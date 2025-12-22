module AcademicCV

using YAML
using Mustache

export build_cv, load_data, generate_latex, compile_pdf

"""
    load_data(data_dir::String)

Load all YAML files from the specified data directory.
Returns a dictionary with filenames (without extension) as keys and parsed YAML content as values.
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
        data[key] = YAML.load_file(filepath)
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
            run(`$engine -interaction=nonstopmode $tex_basename`)
        end
        
        pdf_file = replace(tex_file, r"\.tex$" => ".pdf")
        
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
