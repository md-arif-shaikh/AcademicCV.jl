using AcademicCV

# Define paths
data_dir = joinpath(@__DIR__, "_data")
template_file = joinpath(@__DIR__, "templates", "cv_template.tex")
output_dir = joinpath(@__DIR__, "output")

# Build the CV
println("Building Academic CV...")
pdf_file = build_cv(data_dir, template_file, output_dir)

println("\nCV generated successfully!")
println("PDF file: $pdf_file")
