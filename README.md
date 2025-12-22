# AcademicCV.jl

[![CI](https://github.com/md-arif-shaikh/AcademicCV.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/md-arif-shaikh/AcademicCV.jl/actions/workflows/CI.yml)
[![Build CV](https://github.com/md-arif-shaikh/AcademicCV.jl/actions/workflows/build-cv.yml/badge.svg)](https://github.com/md-arif-shaikh/AcademicCV.jl/actions/workflows/build-cv.yml)

A Julia package for building academic CVs from YAML data files and LaTeX templates.

## Features

- 📄 Load academic data from YAML files (positions, education, publications, visits, etc.)
- 📝 Generate LaTeX files using Mustache templates
- 🔧 Compile LaTeX to PDF automatically
- 🚀 Easy integration with GitHub Actions for automated CV generation
- 🎨 Customizable templates for different CV styles

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/md-arif-shaikh/AcademicCV.jl")
```

Or in the Julia REPL package mode (press `]`):

```
add https://github.com/md-arif-shaikh/AcademicCV.jl
```

## Quick Start

### 1. Organize Your Data

Create a `_data` directory with YAML files for different aspects of your CV:

```
_data/
├── positions.yml
├── education.yml
├── publications.yml
└── visits.yml
```

Example `positions.yml`:

```yaml
- position: "Assistant Professor"
  institution: "University of Example"
  location: "City, Country"
  start_date: "2020"
  end_date: "Present"
  description: "Teaching and research in Computer Science"
```

### 2. Create a LaTeX Template

Create a template file using Mustache syntax:

```latex
\documentclass{article}
\begin{document}

\section*{Positions}
{{#positions}}
\subsection*{ {{position}} }
\textit{ {{institution}}, {{location}} } \hfill {{start_date}} -- {{end_date}}
{{/positions}}

\end{document}
```

### 3. Build Your CV

```julia
using AcademicCV

# Build CV from YAML data
pdf_file = build_cv(
    "_data",                    # Data directory
    "cv_template.tex",          # Template file
    "output"                    # Output directory
)
```

## API Reference

### `build_cv`

Main function to build a CV from YAML data files.

```julia
build_cv(data_dir, template_file, output_dir="./output"; 
         tex_filename="cv.tex", compile=true, engine="pdflatex")
```

**Arguments:**
- `data_dir::String`: Directory containing YAML data files
- `template_file::String`: Path to the LaTeX template file
- `output_dir::String`: Directory where output files will be saved (default: `"./output"`)
- `tex_filename::String`: Name of the generated TeX file (default: `"cv.tex"`)
- `compile::Bool`: Whether to compile the TeX file to PDF (default: `true`)
- `engine::String`: LaTeX engine to use (default: `"pdflatex"`)

**Returns:** Path to the generated PDF file (if `compile=true`) or TeX file (if `compile=false`)

### `load_data`

Load all YAML files from a directory.

```julia
data = load_data("_data")
```

### `generate_latex`

Generate LaTeX file from data and template.

```julia
generate_latex(data, "template.tex", "output.tex")
```

### `compile_pdf`

Compile LaTeX file to PDF.

```julia
compile_pdf("document.tex"; engine="pdflatex", clean=true)
```

## Using with GitHub Actions

Create a workflow file `.github/workflows/build-cv.yml`:

```yaml
name: Build CV

on:
  push:
    branches: [main]

jobs:
  build-cv:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Julia
        uses: julia-actions/setup-julia@v2
        with:
          version: '1.12'
      
      - name: Install LaTeX
        run: |
          sudo apt-get update
          sudo apt-get install -y texlive-latex-base texlive-latex-extra
      
      - name: Install AcademicCV.jl
        run: julia --project=. -e 'using Pkg; Pkg.instantiate()'
      
      - name: Build CV
        run: julia --project=. build_cv.jl
      
      - name: Upload PDF
        uses: actions/upload-artifact@v4
        with:
          name: cv-pdf
          path: output/*.pdf
```

## Examples

See the `examples/` directory for:
- Sample YAML data files
- Example LaTeX template
- Build script

To run the example:

```bash
cd examples
julia --project=.. build_cv.jl
```

## Requirements

- Julia ≥ 1.6
- LaTeX distribution (for PDF compilation)
  - Linux: `texlive-latex-base` and `texlive-latex-extra`
  - macOS: MacTeX
  - Windows: MiKTeX or TeX Live

## License

MIT License

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
