using AcademicCV

# Define paths
data_dir = joinpath(@__DIR__, "_data")
sections_dir = joinpath(@__DIR__, "templates", "sections")
base_template = joinpath(@__DIR__, "templates", "cv_template_base.tex")
output_dir = joinpath(@__DIR__, "output")

# Build the CV using layout configuration
println("Building Academic CV with layout configuration...")
pdf_file = build_cv_with_layout(data_dir, sections_dir, base_template, output_dir)

println("\nCV generated successfully!")
println("PDF file: $pdf_file")
