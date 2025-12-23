# AcademicCV.jl Examples

This directory contains example build scripts demonstrating different ways to use AcademicCV.jl.

## Examples

### 1. `build_cv_simple.jl` - Recommended for Most Users

Uses the bundled templates (simplest approach):

```julia
using AcademicCV
pdf_file = build_cv_from_data("my_cv_data")
```

**What you need:**
- Your data directory with YAML files and `layout.yml`
- That's it! No template files needed.

### 2. `build_cv_with_layout.jl` - For Custom Templates

Uses custom LaTeX templates for full control:

```julia
using AcademicCV
pdf_file = build_cv_with_layout(
    data_dir, 
    sections_dir, 
    base_template, 
    output_dir
)
```

**What you need:**
- Your data directory with YAML files
- Custom LaTeX template files in `templates/`
- See `_data/`, `templates/` directories for the full structure

## Data Files

The `_data/` directory contains example YAML files showing the expected format for:
- Personal information (`authinfo.yaml`)
- Positions, education, teaching, etc.
- Layout configuration (`layout.yml`)

## Getting Started

1. Copy one of the build scripts to your project
2. Update the paths to point to your data directory
3. Run: `julia build_cv_simple.jl` (or whichever script you chose)
