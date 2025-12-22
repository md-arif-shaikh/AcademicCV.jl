module AcademicCV

using YAML
using Mustache

export build_cv, load_data, generate_latex, compile_pdf

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
    
    for file in yaml_files
        filepath = joinpath(data_dir, file)
        key = replace(file, r"\.(yml|yaml)$" => "")
        yaml_content = YAML.load_file(filepath)
        
        # If the YAML content is a dictionary (not a list), convert dict values to a list
        # This makes it easier to iterate in Mustache templates
        if isa(yaml_content, Dict) && !isempty(yaml_content)
            # Check if all values are dictionaries (typical for CV sections)
            if all(v -> isa(v, Dict), values(yaml_content))
                data[key] = [v for (k, v) in yaml_content]
            else
                data[key] = yaml_content
            end
        else
            data[key] = yaml_content
        end
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
                # If pdflatex fails, try to show the log file
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
            end
        end
        
        pdf_file = replace(tex_file, r"\.tex$" => ".pdf")
        
        # Check if PDF was actually created
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

end # module AcademicCV
