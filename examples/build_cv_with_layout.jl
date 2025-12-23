using AcademicCV

# Define paths
data_dir = joinpath(@__DIR__, "_data")
output_dir = joinpath(@__DIR__, "output")

# Get bundled templates from the package
package_dir = pkgdir(AcademicCV)
sections_dir = joinpath(package_dir, "src", "templates", "sections")
base_template = joinpath(package_dir, "src", "templates", "cv_template_base.tex")

# Build the CV using layout configuration with bundled templates
println("Building Academic CV with layout configuration...")
println("Using bundled templates from: $package_dir")
pdf_file = build_cv_with_layout(data_dir, sections_dir, base_template, output_dir)

println("\nCV generated successfully!")
println("PDF file: $pdf_file")
