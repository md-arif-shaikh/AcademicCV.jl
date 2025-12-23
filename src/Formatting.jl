module Formatting

export escape_latex, strip_tex, abbreviate_name, build_author_abbr, html_unescape, sanitize

using OrderedCollections

# Escape LaTeX special characters for visible text
function escape_latex(s)
    if !isa(s, String)
        return s
    end
    out = s
    # Order matters to avoid double-escaping
    replacements = OrderedDict{String,String}()
    replacements[string('\\')] = raw"\textbackslash{}"
    replacements[string('#')] = raw"\#"
    replacements[string('$')] = raw"\$"
    replacements[string('%')] = raw"\%"
    replacements[string('&')] = raw"\&"
    replacements[string('_')] = raw"\_"
    replacements[string('{')] = raw"\{"
    replacements[string('}')] = raw"\}"
    replacements[string('~')] = raw"\textasciitilde{}"
    replacements[string('^')] = raw"\textasciicircum{}"
    for (k,v) in replacements
        out = replace(out, k => v)
    end
    return out
end

# Helper to remove simple LaTeX commands and braces from strings
function strip_tex(s)
    if !isa(s, String)
        return s
    end
    out = s
    # Map common LaTeX accent commands to precomposed Unicode characters
    acc_map = Dict{
        Char, Dict{Char,String}
    }()

    acc_map['"'] = Dict('a'=>"ä", 'e'=>"ë", 'i'=>"ï", 'o'=>"ö", 'u'=>"ü", 'y'=>"ÿ",
                         'A'=>"Ä", 'E'=>"Ë", 'I'=>"Ï", 'O'=>"Ö", 'U'=>"Ü", 'Y'=>"Ÿ")
    acc_map['\''] = Dict('a'=>"á", 'e'=>"é", 'i'=>"í", 'o'=>"ó", 'u'=>"ú", 'y'=>"ý",
                          'A'=>"Á", 'E'=>"É", 'I'=>"Í", 'O'=>"Ó", 'U'=>"Ú", 'Y'=>"Ý")
    acc_map['`'] = Dict('a'=>"à", 'e'=>"è", 'i'=>"ì", 'o'=>"ò", 'u'=>"ù",
                        'A'=>"À", 'E'=>"È", 'I'=>"Ì", 'O'=>"Ò", 'U'=>"Ù")
    acc_map['^'] = Dict('a'=>"â", 'e'=>"ê", 'i'=>"î", 'o'=>"ô", 'u'=>"û",
                        'A'=>"Â", 'E'=>"Ê", 'I'=>"Î", 'O'=>"Ô", 'U'=>"Û")
    acc_map['~'] = Dict('n'=>"ñ", 'a'=>"ã", 'o'=>"õ",
                        'N'=>"Ñ", 'A'=>"Ã", 'O'=>"Õ")
    acc_map['c'] = Dict('c'=>"ç", 'C'=>"Ç")
    acc_map['v'] = Dict('c'=>"č", 's'=>"š", 'z'=>"ž",
                        'C'=>"Č", 'S'=>"Š", 'Z'=>"Ž")
    acc_map['H'] = Dict('o'=>"ő", 'u'=>"ű", 'O'=>"Ő", 'U'=>"Ű")
    acc_map['r'] = Dict('a'=>"å", 'A'=>"Å")
    acc_map['.'] = Dict('e'=>"ė", 'E'=>"Ė")
    acc_map['='] = Dict('a'=>"ā", 'e'=>"ē", 'i'=>"ī", 'o'=>"ō", 'u'=>"ū",
                        'A'=>"Ā", 'E'=>"Ē", 'I'=>"Ī", 'O'=>"Ō", 'U'=>"Ū")

    out2 = out
    for (cmd, cmap) in acc_map
        for (L, rep) in cmap
            pat1 = "\\" * string(cmd) * "{" * string(L) * "}"
            pat2 = "\\" * string(cmd) * string(L)
            out2 = replace(out2, pat1 => rep)
            out2 = replace(out2, pat2 => rep)
        end
    end

    # Strip remaining simple accent commands like \x{Y} or \Y -> keep the letter
    out2 = replace(out2, r"\\.\{([A-Za-z])\}" => m-> m.captures[1])
    out2 = replace(out2, r"\\([A-Za-z])" => m-> m.captures[1])

    # Replace only safe text-like macros (e.g., \textit{...}, \emph{...}) by their contents
    out2 = replace(out2, r"\\(?:textit|textbf|emph|itshape)\{([^}]*)\}" => s-> s.captures[1])
    # Remove remaining braces and leftover backslashes
    out2 = replace(out2, r"[{}]" => "")
    out2 = replace(out2, "\\" => "")
    return out2
end

# Abbreviate personal name: "Md Arif Shaikh" -> "Shaikh, M. A."
function abbreviate_name(fullname::AbstractString)
    sfullname = string(fullname)
    s = strip(sfullname)
    if occursin(",", s)
        parts = split(s, ",")
        surname = strip(parts[1])
        given = strip(join(parts[2:end], ","))
        gparts = split(given)
        initials = [string(first(g), '.') for g in gparts if !isempty(g)]
        return string(surname, ", ", join(initials, " "))
    else
        parts = split(s)
        if length(parts) == 0
            return sfullname
        elseif length(parts) == 1
            return parts[1]
        else
            surname = parts[end]
            initials = [string(first(p), '.') for p in parts[1:end-1] if !isempty(p)]
            return string(surname, ", ", join(initials, " "))
        end
    end
end

# Build abbreviated author string and optionally highlight an author
function build_author_abbr(raw_authors::AbstractString; highlight::Union{Nothing,AbstractString}=nothing)
    s = string(raw_authors)
    if isempty(strip(s))
        return ""
    end
    authors = split(s, " and ")
    out = String[]
    for a in authors
        a_clean = strip(a)
        abbr_raw = abbreviate_name(a_clean)
        if !isnothing(highlight) && !isempty(string(highlight))
            sh = lowercase(replace(string(highlight), r"[^A-Za-z0-9]" => ""))
            sc = lowercase(replace(a_clean, r"[^A-Za-z0-9]" => ""))
            sa = lowercase(replace(abbr_raw, r"[^A-Za-z0-9]" => ""))
            if !isempty(sh) && (occursin(sh, sc) || occursin(sh, sa) || occursin(sc, sh))
                safe_raw = replace(abbr_raw, r"[\\{}]" => "")
                abbr_escaped = escape_latex(safe_raw)
                abbr_escaped = "\\underline{" * abbr_escaped * "}"
            else
                abbr_escaped = escape_latex(abbr_raw)
            end
        else
            abbr_escaped = escape_latex(abbr_raw)
        end
        push!(out, abbr_escaped)
    end
    s_out = join(out, ", ")
    if !isempty(s_out)
        if !endswith(s_out, ".")
            s_out *= "."
        end
    end
    return s_out
end
# Basic HTML numeric/entity unescape (handles &#xHH; and &amp;)
function html_unescape(s)
    if !isa(s, String)
        return s
    end
    out = replace(s, "&amp;" => "&")
    out = replace(out, r"&#x([0-9A-Fa-f]+);" => (m-> Char(parse(Int, m.captures[1], base=16))))
    out = replace(out, r"&#([0-9]+);" => (m-> Char(parse(Int, m.captures[1]))))
    return out
end

# Sanitize YAML-like data: unescape URLs, escape visible text for LaTeX
function sanitize(obj)
    if isa(obj, AbstractDict)
        out = OrderedDict()
        for (k,v) in obj
            # Convert key to string for safe comparison
            key_str = string(k)
            
            if isa(v, String)
                if key_str == "author_abbr"
                    # Don't escape - author abbreviations are pre-formatted
                    out[k] = v
                elseif key_str == "conference" || key_str == "title"
                    # Escape special characters but preserve already-escaped LaTeX commands
                    # Only escape underscores, the rest should be handled properly
                    out[k] = replace(v, "_" => raw"\_")
                elseif occursin("website", key_str) || occursin("url", key_str) || key_str == "website"
                    out[k] = html_unescape(v)
                elseif key_str == "doi"
                    cleaned = html_unescape(v)
                    out["doi"] = cleaned
                    out["doi_url"] = cleaned
                    out["doi_display"] = escape_latex(cleaned)
                    out["doi_full_url"] = "https://doi.org/" * cleaned
                else
                    out[k] = escape_latex(v)
                end
            else
                out[k] = sanitize(v)
            end
        end
        return out
    elseif isa(obj, AbstractVector)
        return [sanitize(v) for v in obj]
    else
        return obj
    end
end

end # module Formatting
