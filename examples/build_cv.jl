#!/usr/bin/env julia
# 
# Build Script for Academic CV
# 
# This demonstrates the simplest way to build a CV using AcademicCV.jl
# with bundled templates - no need to manage LaTeX template files!
#
# Usage:
#   julia build_cv.jl

using AcademicCV

# Define paths
data_dir = joinpath(@__DIR__, "_data")
output_dir = joinpath(@__DIR__, "output")

# Build the CV using bundled templates (recommended way)
println("Building Academic CV...")
pdf_file = build_cv_from_data(data_dir; output_dir=output_dir)

println("\nCV generated successfully!")
println("PDF file: $pdf_file")
