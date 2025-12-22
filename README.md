# AcademicCV.jl

[![CI](https://github.com/md-arif-shaikh/AcademicCV.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/md-arif-shaikh/AcademicCV.jl/actions/workflows/CI.yml)
[![Build CV](https://github.com/md-arif-shaikh/AcademicCV.jl/actions/workflows/build-cv.yml/badge.svg)](https://github.com/md-arif-shaikh/AcademicCV.jl/actions/workflows/build-cv.yml)

A Julia package for building academic CVs from YAML data files and LaTeX templates.

📄 **[View Example LaTeX Output](examples/output/cv.tex)** - See the generated LaTeX file  
📥 **[Download Example PDF](../../tree/cv-output)** - View the compiled PDF from the cv-output branch

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

The package supports two YAML formats:

**Format 1: Dictionary/Map structure** (recommended for sections like positions, education, visits):

```yaml
assistant_professor:
  position: Assistant Professor
  department: Department of Computer Science
  institute: University of Example
  institute-website: https://www.example.edu
  from-year: 2020
  from-month: September
  to-year:
  to-month:
```

**Format 2: List/Array structure** (recommended for publications):

```yaml
- title: "Machine Learning for Scientific Discovery"
  authors: "Author Name, Co-Author Name"
  journal: "Journal of Machine Learning Research"
  year: "2021"
  doi: "10.1234/jmlr.2021.001"
```

Both formats work seamlessly with Mustache templates. Dictionary structures are automatically converted to lists for template iteration.

### 2. Create a LaTeX Template

Create a template file using Mustache syntax:

```latex
\documentclass{article}
\begin{document}

\section*{Positions}
{{#positions}}
\subsection*{ {{position}} }
\textit{ {{institute}} } \hfill {{from-month}} {{from-year}} -- {{#to-year}}{{to-month}} {{to-year}}{{/to-year}}{{^to-year}}Present{{/to-year}}
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
- Sample YAML data files in `examples/_data/` matching the format from [md-arif-shaikh.github.io](https://github.com/md-arif-shaikh/md-arif-shaikh.github.io/tree/main/_data)
- Example LaTeX template in `examples/templates/`
- **[Example generated output](examples/output/cv.tex)** - View the LaTeX file produced from the sample data
- Build scripts

To run the example:

```bash
cd examples
julia --project=.. build_cv.jl
```

This will:
1. Load YAML files from `_data/` directory
2. Use the template from `templates/cv_template.tex`
3. Generate a TeX file in `output/`
4. Compile to PDF (if pdflatex is available)

### Viewing the Output

**LaTeX Source**: [examples/output/cv.tex](examples/output/cv.tex)  
**Compiled PDF**: Available in the [cv-output branch](../../tree/cv-output)

The package provides multiple ways to view the output:

#### 1. Pre-generated PDF (Recommended)
The GitHub Actions workflow automatically compiles the example and pushes the PDF to the `cv-output` branch:
- **[View/Download the PDF](../../blob/cv-output/cv.pdf)** from the cv-output branch
- This PDF is automatically updated whenever changes are pushed to the main branch

#### 2. LaTeX Source
View the example LaTeX output directly:
- **[examples/output/cv.tex](examples/output/cv.tex)** - Pre-generated example showing what the package produces from the sample YAML data
- Copy and compile it locally with `pdflatex cv.tex` to see the PDF
- Use an online LaTeX editor like [Overleaf](https://www.overleaf.com/) to compile and view

#### 3. After Running Locally
After running the build script yourself, you can find:
- **LaTeX source**: `examples/output/cv.tex`
- **PDF output**: `examples/output/cv.pdf` (if LaTeX is installed)

#### 4. GitHub Actions Artifacts
When using GitHub Actions in your own repository, the generated PDF is also available as a workflow artifact:
1. Go to the Actions tab in your repository
2. Click on the latest "Build CV" workflow run
3. Download the `cv-pdf` artifact

## Package Structure

```
AcademicCV.jl/
├── src/
│   └── AcademicCV.jl          # Main module
├── examples/
│   ├── _data/                 # Example YAML data
│   │   ├── positions.yml
│   │   ├── education.yml
│   │   ├── publications.yml
│   │   └── visits.yml
│   ├── templates/             # Example LaTeX templates
│   │   └── cv_template.tex
│   └── build_cv.jl           # Example build script
├── test/
│   └── runtests.jl           # Test suite
├── .github/workflows/         # GitHub Actions
│   ├── CI.yml                # Testing workflow
│   └── build-cv.yml          # CV building workflow
├── Project.toml              # Package metadata
└── README.md
```

## Customizing Templates

The package uses [Mustache templating](https://mustache.github.io/) for LaTeX generation. Here's how to create custom templates:

### Template Syntax

- `{{variable}}` - Insert a variable
- `{{#section}}...{{/section}}` - Loop over arrays or conditionally show content
- `{{^section}}...{{/section}}` - Inverted section (shows if section is false/empty)

### Example Template Snippet

```latex
\section*{Publications}
\begin{enumerate}
{{#publications}}
\item {{authors}}. ``{{title}}.'' 
{{#journal}}\textit{ {{journal}} }, {{/journal}}{{year}}.
{{#doi}}DOI: \href{https://doi.org/{{doi}}}{ {{doi}} }{{/doi}}
{{/publications}}
\end{enumerate}
```

This will iterate over all publications in your `publications.yml` file and format them according to the template.

### Custom YAML Fields

You can add any fields to your YAML files and reference them in the template. For example:

```yaml
# custom_data.yml
- field1: "Value 1"
  field2: "Value 2"
  nested:
    subfield: "Nested value"
```

Then in your template:
```latex
{{#custom_data}}
{{field1}} - {{field2}}
{{#nested}}Nested: {{subfield}}{{/nested}}
{{/custom_data}}
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
