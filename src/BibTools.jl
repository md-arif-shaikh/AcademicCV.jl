module BibTools

export parse_bib_file

using OrderedCollections

# Parse a single .bib file into a vector of OrderedDict entries
function parse_bib_file(path::String)
    txt = read(path, String)
    parts = split(txt, r"(?=@\w+\s*{)")
    entries = Any[]
    for ch in parts
        ch = strip(ch)
        if isempty(ch)
            continue
        end
        m = match(r"@(\w+)\s*{\s*([^,]+),", ch)
        if m === nothing
            continue
        end
        entry_type = m.captures[1]
        citekey = m.captures[2]
        # Remaining text after the opening @type{key,
        rest = ch[length(m.match)+1:end]
        # Remove the final closing brace if present
        if endswith(rest, "}")
            rest = rest[1:end-1]
        end

        # Parse key = {value} or key = "value" pairs
        pos = 1
        n = lastindex(rest)
        fields = OrderedDict{String, Any}()
        while pos <= n
            # find field name
            mfield = match(r"\s*([A-Za-z0-9_\-]+)\s*=\s*", rest[pos:end])
            if mfield === nothing
                break
            end
            fname = lowercase(mfield.captures[1])
            pos += mfield.offset - 1 + length(mfield.match)
            # detect delimiter
            if pos > n
                break
            end
            delim = rest[pos]
            val = ""
            if delim == '{'
                # scan for matching brace with nesting
                depth = 0
                i = pos
                started = false
                while i <= n
                    c = rest[i]
                    if c == '{'
                        depth += 1
                        started = true
                        if depth > 1
                            val *= c
                        end
                    elseif c == '}'
                        depth -= 1
                        if depth == 0
                            i += 1
                            break
                        else
                            val *= c
                        end
                    else
                        if started
                            val *= c
                        end
                    end
                    i += 1
                end
                pos = i
            elseif delim == '"'
                # quoted string; handle escaped quotes (e.g., \" inside)
                i = pos+1
                while i <= n
                    c = rest[i]
                    if c == '"' && (i == pos+1 || rest[i-1] != '\\')
                        # closing quote
                        break
                    end
                    val *= c
                    i += 1
                end
                pos = min(i+1, n+1)
            else
                # bare word until comma
                mrest = match(r"([^,]+)", rest[pos:end])
                if mrest !== nothing
                    val = strip(mrest.captures[1])
                    pos += mrest.offset - 1 + length(mrest.match)
                else
                    break
                end
            end
            # consume optional trailing comma and whitespace
            if pos <= n && rest[pos] == ','
                pos += 1
            end
            fields[fname] = strip(val)
        end

        # add type and citekey
        fields["entrytype"] = entry_type
        fields["citekey"] = citekey
        push!(entries, fields)
    end
    return entries
end

end # module BibTools
