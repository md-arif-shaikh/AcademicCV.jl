#!/usr/bin/env julia
# 
# Simple Build Script for Academic CV
# 
# This script uses the AcademicCV package to generate a CV PDF from YAML data files.
# 
# Prerequisites:
# 1. Install the AcademicCV package (if not already installed):
#    julia> using Pkg; Pkg.add(url="path/to/AcademicCV.jl")
#
# 2. Create a data directory with your YAML files (e.g., my_cv_data/)
#    - authinfo.yaml: Your personal information
#    - layout.yml: CV layout configuration
#    - education.yml: Education history
#    - positions.yml: Professional positions
#    - publications.yml: Publication collections (can include .bib files)
#    - And any other sections you want to include
#
# Usage:
#   julia build_cv.jl

using AcademicCV

# Configuration
# Update this path to point to your data directory
DATA_DIR = "my_cv_data"

# Optional: Customize output settings
OUTPUT_DIR = "output"
TEX_FILENAME = "cv.tex"
COMPILE_PDF = true
LATEX_ENGINE = "pdflatex"  # or "xelatex", "lualatex"

# Build the CV
println("=" ^ 60)
println("Building Academic CV")
println("=" ^ 60)
println("Data directory: $DATA_DIR")
println("Output directory: $OUTPUT_DIR")
println()

try
    # This function uses the bundled templates from the AcademicCV package
    # You only need to provide your YAML data files
    pdf_file = build_cv_from_data(
        DATA_DIR;
        output_dir=OUTPUT_DIR,
        tex_filename=TEX_FILENAME,
        compile=COMPILE_PDF,
        engine=LATEX_ENGINE
    )
    
    println()
    println("=" ^ 60)
    println("✓ CV generated successfully!")
    println("=" ^ 60)
    if COMPILE_PDF
        println("PDF file: $pdf_file")
    else
        println("TeX file: $pdf_file")
    end
    
catch e
    println()
    println("=" ^ 60)
    println("✗ Error building CV:")
    println("=" ^ 60)
    println(e)
    rethrow()
end
