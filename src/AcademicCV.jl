module AcademicCV

using YAML
using Mustache
using OrderedCollections

# load helper modules
include("Formatting.jl")
include("BibTools.jl")
using .Formatting: escape_latex, strip_tex, abbreviate_name, build_author_abbr, html_unescape, sanitize
using .BibTools: parse_bib_file

export build_cv, load_data, generate_latex, compile_pdf, build_cv_with_layout

"""
    load_data(data_dir::String)

Load all YAML files from the specified data directory.
Returns a dictionary with filenames (without extension) as keys and parsed YAML content as values.
If the YAML content is a dictionary (not a list), it converts the dictionary values to a list
for easier iteration in Mustache templates.
"""
function load_data(data_dir::String)
    if !isdir(data_dir)
        error("Data directory does not exist: $data_dir")
    end
    
    data = Dict{String, Any}()
    yaml_files = filter(f -> endswith(f, ".yml") || endswith(f, ".yaml"), readdir(data_dir))
    
    # Helper: recursively convert any dict-of-dicts into arrays of values
    function normalize(obj)
        if isa(obj, AbstractDict)
            # If all values are dict-like, convert to array of normalized values
            if !isempty(obj) && all(v -> isa(v, AbstractDict), values(obj))
                return [normalize(v) for v in values(obj)]
            else
                # normalize each value in-place
                out = OrderedDict()
                for (k, v) in obj
                    out[k] = normalize(v)
                end
                return out
            end
        elseif isa(obj, AbstractVector)
            return [normalize(v) for v in obj]
        else
            return obj
        end
    end

    # `strip_tex` and other formatting helpers are provided by `Formatting.jl`.
    # AcademicCV uses those exported helpers via `using .Formatting` at the module top.

    # Helper function to format date ranges intelligently
    function format_date_range!(item::AbstractDict)
        # Handle ISO date range with from/to fields (e.g., for teaching)
        if haskey(item, "from") && haskey(item, "to") && !haskey(item, "from-month")
            from_str = string(get(item, "from", ""))
            to_str = string(get(item, "to", ""))
            
            # Parse ISO dates
            if occursin(r"^\d{4}-\d{2}-\d{2}$", from_str) && occursin(r"^\d{4}-\d{2}-\d{2}$", to_str)
                from_parts = split(from_str, "-")
                to_parts = split(to_str, "-")
                
                from_year = from_parts[1]
                from_month_num = parse(Int, from_parts[2])
                from_day = parse(Int, from_parts[3])
                
                to_year = to_parts[1]
                to_month_num = parse(Int, to_parts[2])
                to_day = parse(Int, to_parts[3])
                
                months = ["January", "February", "March", "April", "May", "June", 
                         "July", "August", "September", "October", "November", "December"]
                
                from_month = months[from_month_num]
                to_month = months[to_month_num]
                
                # Format based on same/different month and year
                if from_year == to_year
                    if from_month == to_month
                        item["date_range"] = "$from_month $from_day--$to_day, $from_year"
                    else
                        item["date_range"] = "$from_month $from_day--$to_month $to_day, $from_year"
                    end
                else
                    item["date_range"] = "$from_month $from_day, $from_year--$to_month $to_day, $to_year"
                end
            end
            return item
        end
        
        # Handle single date field (e.g., for seminars)
        if haskey(item, "date") && !haskey(item, "from-month")
            date_str = string(get(item, "date", ""))
            # Parse ISO date format (YYYY-MM-DD)
            if occursin(r"^\d{4}-\d{2}-\d{2}$", date_str)
                parts = split(date_str, "-")
                year = parts[1]
                month_num = parse(Int, parts[2])
                day = parse(Int, parts[3])
                
                months = ["January", "February", "March", "April", "May", "June", 
                         "July", "August", "September", "October", "November", "December"]
                month_name = months[month_num]
                
                item["date_range"] = "$month_name $day, $year"
            else
                item["date_range"] = date_str
            end
            return item
        end
        
        if !haskey(item, "from-month") || !haskey(item, "to-month")
            return item
        end
        
        from_month = get(item, "from-month", "")
        from_date = get(item, "from-date", "")
        from_year = get(item, "from-year", "")
        to_month = get(item, "to-month", "")
        to_date = get(item, "to-date", "")
        to_year = get(item, "to-year", "")
        
        # Convert to strings
        from_month = string(from_month)
        to_month = string(to_month)
        from_year = string(from_year)
        to_year = string(to_year)
        from_date = string(from_date)
        to_date = string(to_date)
        
        # Create formatted date range
        if from_year == to_year
            if from_month == to_month
                # Same month and year: "Month day1-day2, year"
                item["date_range"] = "$from_month $from_date--$to_date, $from_year"
            else
                # Different months, same year: "Month1 day1--Month2 day2, year"
                item["date_range"] = "$from_month $from_date--$to_month $to_date, $from_year"
            end
        else
            # Different years: "Month1 day1, year1--Month2 day2, year2"
            item["date_range"] = "$from_month $from_date, $from_year--$to_month $to_date, $to_year"
        end
        
        return item
    end

    # YAML loading and sanitization handled in Formatting.jl

    # Load YAML files and normalize/sanitize
    for file in yaml_files
        filepath = joinpath(data_dir, file)
        key = replace(file, r"\.(yml|yaml)$" => "")
        yaml_content = YAML.load_file(filepath; dicttype=OrderedDict)
        yaml_content = normalize(yaml_content)
        
        # Add is_plural flag before sanitization for items with number field
        if isa(yaml_content, AbstractDict) && !isempty(yaml_content)
            for (k, v) in yaml_content
                if isa(v, AbstractDict) && haskey(v, "number")
                    v["is_plural"] = (v["number"] > 1)
                end
            end
        elseif isa(yaml_content, AbstractVector)
            for item in yaml_content
                if isa(item, AbstractDict) && haskey(item, "number")
                    item["is_plural"] = (item["number"] > 1)
                end
            end
        end
        
        yaml_content = sanitize(yaml_content)

        if isa(yaml_content, AbstractVector)
            # It's already an array of items
            data[key] = yaml_content
            # Apply date range formatting to each item
            for item in data[key]
                if isa(item, AbstractDict)
                    format_date_range!(item)
                end
            end
            data[string(key, "_count")] = length(data[key])
        elseif isa(yaml_content, AbstractDict) && !isempty(yaml_content)
            if all(v -> isa(v, AbstractDict), values(yaml_content))
                data[key] = [v for (k, v) in yaml_content]
                # Apply date range formatting to each item
                for item in data[key]
                    format_date_range!(item)
                end
                data[string(key, "_count")] = length(data[key])
            else
                data[key] = yaml_content
            end
        else
            data[key] = yaml_content
        end
    end

    # Parse any .bib files in the data directory into separate publication collections
    bib_files = filter(f -> endswith(f, ".bib"), readdir(data_dir))

    if !isempty(bib_files)
        # optional highlights mapping: read from `authinfo` (key `bib-highlights` or `bib_highlights`)
        bib_highlights = Dict{String,String}()
        if haskey(data, "authinfo") && isa(data["authinfo"], AbstractDict)
            auth = data["authinfo"]
            raw = nothing
            if haskey(auth, "bib-highlights")
                raw = auth["bib-highlights"]
            elseif haskey(auth, "bib_highlights")
                raw = auth["bib_highlights"]
            end
            if isa(raw, AbstractDict)
                for (k,v) in raw
                    bib_highlights[string(k)] = string(v)
                end
            end
        end

        # helper functions for name formatting live in Formatting.jl

        bib_collections = Any[]
        for bib in bib_files
            path = joinpath(data_dir, bib)
            entries = parse_bib_file(path)
            name = replace(bib, r"\.bib$" => "")
            # compute abbreviated author field before sanitization
            hl = get(bib_highlights, name, nothing)
            for e in entries
                # compute abbreviated author string and normalize fields using helpers
                if haskey(e, "author")
                    e["author"] = strip_tex(string(e["author"]))
                end
                if haskey(e, "doi")
                    e["doi"] = strip_tex(string(e["doi"]))
                end
                if haskey(e, "eprint")
                    e["eprint"] = strip_tex(string(e["eprint"]))
                end
                e["author_abbr"] = build_author_abbr(get(e, "author", ""); highlight=hl)
            end
            # sanitize each entry similar to YAML data (this will not touch author_abbr)
            entries = sanitize(entries)
            # friendly label mapping
            label_map = Dict("short_author" => "Short author publications",
                             "sxs" => "SXS Collaboration",
                             "lvk" => "LVK Collaboration")
            push!(bib_collections, OrderedDict("id" => name,
                                              "label" => get(label_map, name, name),
                                              "entries" => entries,
                                              "entries_count" => length(entries)))
            data[string("bib_", name, "_count")] = length(entries)
        end

        # reorder collections to desired order if present
        preferred = ["short_author", "sxs", "lvk"]
        ordered = Any[]
        for p in preferred
            for c in bib_collections
                if c["id"] == p
                    push!(ordered, c)
                end
            end
        end
        # append any remaining collections not listed above
        for c in bib_collections
            if !any(x->x["id"]==c["id"], ordered)
                push!(ordered, c)
            end
        end

        # Mark the last collection for template rendering
        for (i, c) in enumerate(ordered)
            c["is_last"] = (i == length(ordered))
        end
        
        data["bib_collections"] = ordered
        data["bib_collections_count"] = length(ordered)
        # Calculate total number of publications across all collections
        data["total_publications"] = sum(c["entries_count"] for c in ordered)
    end
    
    return data
end

"""
    generate_latex(data::Dict, template_file::String, output_file::String)

Generate a LaTeX file from the data and template.
Uses Mustache templating to populate the template with data.
"""
function generate_latex(data::Dict, template_file::String, output_file::String)
    if !isfile(template_file)
        error("Template file does not exist: $template_file")
    end
    
    template_content = read(template_file, String)
    template = Mustache.parse(template_content)
    
    output_content = Mustache.render(template, data)
    
    # Ensure output directory exists
    output_dir = dirname(output_file)
    if !isempty(output_dir) && !isdir(output_dir)
        mkpath(output_dir)
    end
    
    write(output_file, output_content)
    println("LaTeX file generated: $output_file")
    
    return output_file
end

"""
    compile_pdf(tex_file::String; engine::String="pdflatex", clean::Bool=true)

Compile a LaTeX file to PDF using the specified engine.
Returns the path to the generated PDF file.
"""
function compile_pdf(tex_file::String; engine::String="pdflatex", clean::Bool=true)
    if !isfile(tex_file)
        error("TeX file does not exist: $tex_file")
    end
    
    # Get the directory and filename
    tex_dir = dirname(tex_file)
    tex_basename = basename(tex_file)
    
    # Change to the directory containing the tex file
    original_dir = pwd()
    cd(tex_dir)
    
    try
        # Run pdflatex twice for references
        for i in 1:2
            println("Running $engine (pass $i/2)...")
            try
                run(`$engine -interaction=nonstopmode $tex_basename`)
            catch e
                # pdflatex may return non-zero exit code even if PDF is created
                # Check if PDF exists before treating as fatal error
                pdf_basename = replace(tex_basename, r"\.tex$" => ".pdf")
                if !isfile(pdf_basename)
                    # PDF not created - this is a real error
                    log_file = replace(tex_basename, r"\.tex$" => ".log")
                    if isfile(log_file)
                        println("\n" * "="^80)
                        println("LaTeX compilation failed. Last 50 lines of log file:")
                        println("="^80)
                        log_content = readlines(log_file)
                        for line in log_content[max(1, length(log_content)-49):end]
                            println(line)
                        end
                        println("="^80)
                    end
                    rethrow(e)
                else
                    # PDF exists - just warnings, continue
                    println("Warning: LaTeX returned non-zero exit code, but PDF was created successfully.")
                end
            end
        end
        
        pdf_file = replace(tex_file, r"\.tex$" => ".pdf")
        
        # Final check if PDF was actually created
        pdf_basename = replace(tex_basename, r"\.tex$" => ".pdf")
        if !isfile(pdf_basename)
            error("PDF file was not created. LaTeX compilation may have failed silently.")
        end
        
        if clean
            # Clean up auxiliary files
            aux_extensions = [".aux", ".log", ".out", ".toc", ".lof", ".lot"]
            base = replace(tex_basename, r"\.tex$" => "")
            for ext in aux_extensions
                aux_file = base * ext
                if isfile(aux_file)
                    rm(aux_file)
                end
            end
        end
        
        println("PDF compiled successfully: $pdf_file")
        return pdf_file
    finally
        cd(original_dir)
    end
end

"""
    build_cv(data_dir::String, template_file::String, output_dir::String="./output"; 
             tex_filename::String="cv.tex", compile::Bool=true, engine::String="pdflatex")

Main function to build a CV from YAML data files.

# Arguments
- `data_dir::String`: Directory containing YAML data files
- `template_file::String`: Path to the LaTeX template file
- `output_dir::String`: Directory where output files will be saved (default: "./output")
- `tex_filename::String`: Name of the generated TeX file (default: "cv.tex")
- `compile::Bool`: Whether to compile the TeX file to PDF (default: true)
- `engine::String`: LaTeX engine to use (default: "pdflatex")

# Returns
- Path to the generated PDF file (if compile=true) or TeX file (if compile=false)
"""
function build_cv(data_dir::String, template_file::String, output_dir::String="./output"; 
                  tex_filename::String="cv.tex", compile::Bool=true, engine::String="pdflatex")
    # Create output directory if it doesn't exist
    if !isdir(output_dir)
        mkpath(output_dir)
    end
    
    # Load data from YAML files
    println("Loading data from $data_dir...")
    data = load_data(data_dir)
    println("Loaded data for: $(join(keys(data), ", "))")
    
    # Generate LaTeX file
    tex_output = joinpath(output_dir, tex_filename)
    println("Generating LaTeX file...")
    generate_latex(data, template_file, tex_output)
    
    # Compile to PDF if requested
    if compile
        println("Compiling PDF...")
        pdf_file = compile_pdf(tex_output; engine=engine)
        return pdf_file
    else
        return tex_output
    end
end

"""
    build_cv_with_layout(data_dir::String, sections_dir::String, base_template::String, 
                         output_dir::String="./output"; layout_file::String="",
                         tex_filename::String="cv.tex", compile::Bool=true, 
                         engine::String="pdflatex")

Build a CV using a layout configuration file to customize section ordering and inclusion.

# Arguments
- `data_dir::String`: Directory containing YAML data files
- `sections_dir::String`: Directory containing section template files
- `base_template::String`: Path to the base LaTeX template file
- `output_dir::String`: Directory where output files will be saved (default: "./output")
- `layout_file::String`: Path to layout.yml file (default: searches in data_dir)
- `tex_filename::String`: Name of the generated TeX file (default: "cv.tex")
- `compile::Bool`: Whether to compile the TeX file to PDF (default: true)
- `engine::String`: LaTeX engine to use (default: "pdflatex")

# Returns
- Path to the generated PDF file (if compile=true) or TeX file (if compile=false)
"""
function build_cv_with_layout(data_dir::String, sections_dir::String, base_template::String, 
                               output_dir::String="./output"; layout_file::String="",
                               tex_filename::String="cv.tex", compile::Bool=true, 
                               engine::String="pdflatex")
    # Create output directory if it doesn't exist
    if !isdir(output_dir)
        mkpath(output_dir)
    end
    
    # Determine layout file path
    if isempty(layout_file)
        layout_file = joinpath(data_dir, "layout.yml")
    end
    
    if !isfile(layout_file)
        error("Layout file does not exist: $layout_file")
    end
    
    # Load layout configuration
    println("Loading layout from $layout_file...")
    layout = YAML.load_file(layout_file; dicttype=OrderedDict)
    
    # Load data from YAML files
    println("Loading data from $data_dir...")
    data = load_data(data_dir)
    println("Loaded data for: $(join(keys(data), ", "))")
    
    # Build sections based on layout
    println("Building sections based on layout...")
    sections_content = ""
    
    if haskey(layout, "sections")
        for section in layout["sections"]
            section_id = get(section, "id", "")
            enabled = get(section, "enabled", true)
            title = get(section, "title", section_id)
            
            if !enabled || isempty(section_id)
                continue
            end
            
            # Check if section template exists
            section_template_path = joinpath(sections_dir, "$(section_id).tex")
            
            if !isfile(section_template_path)
                println("Warning: Section template not found: $section_template_path")
                continue
            end
            
            # Create section-specific data context by merging section options with global data
            section_data = copy(data)
            for (key, value) in section
                if key != "id" && key != "enabled" && key != "title"
                    section_data[key] = value
                end
            end
            
            # Read and render section template with data
            section_template_content = read(section_template_path, String)
            section_template = Mustache.parse(section_template_content)
            rendered_section = Mustache.render(section_template, section_data)
            
            # Add section header and rendered content
            sections_content *= "\\CVSection{$title}\n"
            sections_content *= rendered_section
            sections_content *= "\n\n"
        end
    end
    
    # Add sections content to data
    data["cv_sections"] = sections_content
    
    # Generate LaTeX file
    tex_output = joinpath(output_dir, tex_filename)
    println("Generating LaTeX file...")
    generate_latex(data, base_template, tex_output)
    
    # Compile to PDF if requested
    if compile
        println("Compiling PDF...")
        pdf_file = compile_pdf(tex_output; engine=engine)
        return pdf_file
    else
        return tex_output
    end
end

end # module AcademicCV
