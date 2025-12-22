using AcademicCV

# Define paths
data_dir = joinpath(@__DIR__, "_data")
template_file = joinpath(@__DIR__, "templates", "cv_template.tex")
output_dir = joinpath(@__DIR__, "output")

# Build the CV (without compilation since pdflatex is not available)
println("Building Academic CV...")
tex_file = build_cv(data_dir, template_file, output_dir; compile=false)

println("\nCV LaTeX file generated successfully!")
println("TeX file: $tex_file")
