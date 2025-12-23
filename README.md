# AcademicCV.jl

[![CI](https://github.com/md-arif-shaikh/AcademicCV.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/md-arif-shaikh/AcademicCV.jl/actions/workflows/CI.yml)
[![Build CV](https://github.com/md-arif-shaikh/AcademicCV.jl/actions/workflows/build-cv.yml/badge.svg)](https://github.com/md-arif-shaikh/AcademicCV.jl/actions/workflows/build-cv.yml)

A Julia package for building academic CVs from YAML data files and LaTeX templates with customizable layouts.

📄 **[View Example LaTeX Output](examples/output/cv.tex)** - Generated on-the-fly  
📥 **Download Example PDF** - Available in the [cv-output branch](../../tree/cv-output)  
📖 **[Layout Customization Guide](LAYOUT_GUIDE.md)** - Learn how to customize your CV sections

## Features

- 📄 Load academic data from YAML files (positions, education, visits, references, etc.)
- 📚 Parse BibTeX files for publications with automatic formatting
- 🎨 **Layout-based customization** - Control which sections appear and in what order
- 📝 Generate LaTeX files using Mustache templates
- 🔧 Compile LaTeX to PDF automatically
- 🚀 Easy integration with GitHub Actions for automated CV generation
- 🎨 Modern, professional template with clean typography and color accents
- 🔄 Modular section templates for easy customization
- ✨ Author name abbreviation and highlighting in publications
- 🛡️ Automatic LaTeX sanitization and HTML entity decoding

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

Create a `_data` directory with YAML and BibTeX files for different aspects of your CV:

```
_data/
├── authinfo.yaml         # Your personal information
├── positions.yml         # Academic positions
├── education.yml         # Educational background
├── visits.yml           # Research visits
├── short_author.bib     # Your publications (BibTeX)
├── sxs.bib              # Collaboration publications (optional)
└── lvk.bib              # Collaboration publications (optional)
```

#### Personal Information (authinfo.yaml)

Create an `authinfo.yaml` file with your personal details:

```yaml
name: Your Name
email: your.email@example.edu
website: https://yourwebsite.com
position: Assistant Professor
department: Department of Physics
institute: Your University
institute-address: City, State, Zip, Country
phone: +1-234-567-8900
introduction: |
  Brief introduction about your research interests
  and academic background.

# Optional: Highlight your name in publication lists
bib-highlights:
  short_author: "Your Name"
  sxs: "Your Name"
  lvk: "Your Name"
```

#### YAML Data Files

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

**Format 2: List/Array structure** (for simple lists):

```yaml
- title: "Machine Learning for Scientific Discovery"
  authors: "Author Name, Co-Author Name"
  journal: "Journal of Machine Learning Research"
  year: "2021"
  doi: "10.1234/jmlr.2021.001"
```

Both formats work seamlessly with Mustache templates. Dictionary structures are automatically converted to lists for template iteration.

#### BibTeX Files for Publications

The package now supports BibTeX files (`.bib`) for publications, which is the **recommended approach** for managing publications:

```bibtex
@article{shaikh2024gw,
  author = {Shaikh, Md Arif and Smith, John},
  title = {Gravitational Wave Astronomy},
  journal = {Physical Review D},
  volume = {109},
  number = {4},
  year = {2024},
  doi = {10.1103/PhysRevD.109.044001},
  eprint = {2312.12345}
}
```

**Features of BibTeX support:**
- **Automatic author abbreviation**: Authors are automatically abbreviated (e.g., "Shaikh, M. A.")
- **Name highlighting**: Your name can be automatically underlined in publication lists using `bib-highlights` in `authinfo.yaml`
- **Multiple collections**: Group publications by category (e.g., `short_author.bib`, `sxs.bib`, `lvk.bib`)
- **Smart formatting**: DOI and arXiv links are automatically converted to hyperlinks
- **LaTeX sanitization**: Special characters are automatically escaped for LaTeX

The BibTeX parser extracts fields like `author`, `title`, `journal`, `volume`, `number`, `year`, `doi`, `eprint`, and `booktitle`.

### 2. Create a LaTeX Template

Create a template file using Mustache syntax. The package provides special features for publications:

```latex
\documentclass{article}
\begin{document}

% Personal Information (from authinfo.yaml)
{{#authinfo}}
\centerline{\Large\bfseries {{name}}}
\centerline{{{position}}}
\centerline{{{email}} | {{website}}}
{{/authinfo}}

\section*{Positions}
{{#positions}}
\subsection*{ {{position}} }
\textit{ {{institute}} } \hfill {{from-month}} {{from-year}} -- {{#to-year}}{{to-month}} {{to-year}}{{/to-year}}{{^to-year}}Present{{/to-year}}
{{/positions}}

% Publications from BibTeX files with reverse numbering
\section*{Publications}
{{#bib_collections}}
\subsection*{ {{label}} }
\setcounter{bibcount}{ {{entries_count}} }
\begin{enumerate}
{{#entries}}
\item[\arabic{bibcount}.] {{author_abbr}} ``{{title}}.''
{{#journal}}\textit{ {{journal}} }, {{/journal}}{{year}}.
{{#doi}}\href{https://doi.org/{{doi}}}{ {{doi}} }{{/doi}}
\addtocounter{bibcount}{-1}
{{/entries}}
\end{enumerate}
{{/bib_collections}}

\end{document}
```

**New template features:**
- `{{authinfo}}` - Access personal information from `authinfo.yaml`
- `{{#bib_collections}}` - Iterate over BibTeX file collections
- `{{entries_count}}` - Number of entries in each collection
- `{{author_abbr}}` - Pre-formatted, abbreviated author list with optional highlighting
- Reverse numbering support with LaTeX counters

### 3. Build Your CV

```julia
using AcademicCV

# Build CV with layout customization
pdf_file = build_cv_with_layout(
    "_data",                              # Data directory
    "templates/sections",                 # Section templates directory
    "templates/cv_template_base.tex",    # Base template file
    "output"                              # Output directory
)
```

**Customize your CV layout** by editing `_data/layout.yml`:

```yaml
sections:
  - id: positions
    enabled: true
    title: Professional Experience
  
  - id: publications
    enabled: true
    title: Publications
  
  - id: education
    enabled: false    # Exclude this section
    title: Education
```

See [LAYOUT_GUIDE.md](LAYOUT_GUIDE.md) for detailed customization options.

## API Reference

### `build_cv_with_layout`

Build a CV using layout-based customization (recommended).

```julia
build_cv_with_layout(
    data_dir::String,
    sections_dir::String,
    base_template::String,
    output_dir::String="./output";
    layout_file::String="",           # Defaults to data_dir/layout.yml
    tex_filename::String="cv.tex",
    compile::Bool=true,
    engine::String="pdflatex"
)
```
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

### Data Processing Features

The package includes several data processing features to make working with academic CVs easier:

#### `load_data`

Load all YAML and BibTeX files from a directory.

```julia
data = load_data("_data")
```

This function:
- Loads all `.yml`, `.yaml`, and `.bib` files from the specified directory
- Converts dictionary-based YAML to arrays for easier iteration
- Parses BibTeX files into structured collections
- Applies sanitization to escape LaTeX special characters
- Generates `author_abbr` field for each publication entry
- Creates `*_count` variables for each data collection (e.g., `positions_count`, `bib_collections_count`)

#### BibTeX Processing

When BibTeX files are present in the data directory, the package:

1. **Parses BibTeX entries**: Extracts fields like `author`, `title`, `journal`, `volume`, `number`, `year`, `doi`, `eprint`, `booktitle`
2. **Abbreviates author names**: "Md Arif Shaikh" becomes "Shaikh, M. A."
3. **Highlights your name**: Uses `bib-highlights` from `authinfo.yaml` to underline your name in author lists
4. **Sanitizes for LaTeX**: Escapes special characters while preserving URLs
5. **Groups by collection**: Organizes publications by filename (e.g., `short_author.bib` → "Short author publications")
6. **Provides counts**: Adds `entries_count` for each collection

#### LaTeX Sanitization

The `Formatting` module provides:
- `escape_latex(s)`: Escapes special LaTeX characters (#, $, %, &, _, {, }, ~, ^, \)
- `strip_tex(s)`: Removes LaTeX commands from strings (useful for cleaning BibTeX data)
- `html_unescape(s)`: Converts HTML entities like `&amp;` and `&#x2013;` to regular characters
- `sanitize(obj)`: Recursively processes data structures, applying appropriate sanitization to each field

**Smart field handling**:
- URLs and websites are HTML-unescaped but not LaTeX-escaped
- DOI fields generate multiple variants: `doi`, `doi_url`, `doi_display`, `doi_full_url`
- The `author_abbr` field is never re-escaped to preserve formatting

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
- Sample YAML and BibTeX data files in `examples/_data/`:
  - `authinfo.yaml` - Personal information with BibTeX highlighting configuration
  - `positions.yml`, `education.yml`, `visits.yml` - Academic data
  - `short_author.bib`, `sxs.bib`, `lvk.bib` - Publication collections in BibTeX format
- Example LaTeX template in `examples/templates/` with modern styling
- **[Example generated output](examples/output/cv.tex)** - View the LaTeX file produced from the sample data
- Build scripts (`build_cv.jl` for full build, `build_cv_tex_only.jl` for TeX only)

To run the example:

```bash
cd examples
julia --project=.. build_cv.jl
```

This will:
1. Load YAML and BibTeX files from `_data/` directory
2. Parse and format publications with author abbreviation
3. Use the template from `templates/cv_template.tex`
4. Generate a TeX file in `output/`
5. Compile to PDF (if pdflatex is available)

### Viewing the Output

**LaTeX Source**: [examples/output/cv.tex](examples/output/cv.tex)  
**Compiled PDF**: Will be available in the [cv-output branch](../../tree/cv-output) after this PR is merged

The package provides multiple ways to view the output:

#### 1. LaTeX Source (Available Now)
View the example LaTeX output directly:
- **[examples/output/cv.tex](examples/output/cv.tex)** - Pre-generated example showing what the package produces from the sample YAML data
- Copy and compile it locally with `pdflatex cv.tex` to see the PDF
- Use an online LaTeX editor like [Overleaf](https://www.overleaf.com/) to compile and view

#### 2. Test PDF Generation in PR (Available Now)
To verify PDF generation works before merging:
1. Go to the **[Actions tab](../../actions)** in this repository
2. Click on the **"Build CV"** workflow for this PR
3. Wait for the workflow to complete (installs Julia, LaTeX, and builds the PDF)
4. Download the **`cv-pdf`** artifact from the workflow run
5. Extract and view the PDF to verify it's correct

The workflow now runs on pull requests so you can test PDF generation before merging.

#### 3. Pre-generated PDF (Available After Merge)
After this PR is merged to main, the GitHub Actions workflow will automatically compile the example and push the PDF to the `cv-output` branch:
- **[View/Download the PDF](../../blob/cv-output/cv.pdf)** from the cv-output branch
- The PDF will be automatically updated whenever changes are pushed to the main branch
- **Note**: The `cv-output` branch will be created automatically on the first workflow run after merge

#### 4. After Running Locally
After running the build script yourself, you can find:
- **LaTeX source**: `examples/output/cv.tex`
- **PDF output**: `examples/output/cv.pdf` (if LaTeX is installed)

#### 5. GitHub Actions Artifacts
When using GitHub Actions in your own repository, the generated PDF is also available as a workflow artifact:
1. Go to the Actions tab in your repository
2. Click on the latest "Build CV" workflow run
3. Download the `cv-pdf` artifact

## Package Structure

```
AcademicCV.jl/
├── src/
│   ├── AcademicCV.jl          # Main module
│   ├── BibTools.jl            # BibTeX parser
│   └── Formatting.jl          # LaTeX sanitization & text formatting
├── examples/
│   ├── _data/                 # Example YAML and BibTeX data
│   │   ├── authinfo.yaml      # Personal information
│   │   ├── positions.yml      # Academic positions
│   │   ├── education.yml      # Education
│   │   ├── visits.yml         # Research visits
│   │   ├── short_author.bib   # Individual publications
│   │   ├── sxs.bib            # SXS collaboration
│   │   └── lvk.bib            # LVK collaboration
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

- `{{variable}}` - Insert a variable (automatically LaTeX-escaped)
- `{{&variable}}` - Insert a variable without escaping (use for pre-escaped content)
- `{{#section}}...{{/section}}` - Loop over arrays or conditionally show content
- `{{^section}}...{{/section}}` - Inverted section (shows if section is false/empty)

### Available Data Variables

When you run `build_cv`, the following data is available in your template:

**From authinfo.yaml**:
- `authinfo` - Dictionary with `name`, `email`, `website`, `position`, `department`, `institute`, `introduction`, etc.

**From YAML files**:
- `positions` - Array of position entries (also: `positions_count`)
- `education` - Array of education entries (also: `education_count`)
- `visits` - Array of visit entries (also: `visits_count`)

**From BibTeX files**:
- `bib_collections` - Array of publication collections, each with:
  - `id` - Collection identifier (e.g., "short_author", "sxs", "lvk")
  - `label` - Human-readable label (e.g., "Short author publications")
  - `entries` - Array of publication entries
  - `entries_count` - Number of entries in this collection
- `bib_collections_count` - Total number of collections

**Each BibTeX entry includes**:
- `author_abbr` - Pre-formatted, abbreviated author list (with optional highlighting)
- `title`, `journal`, `volume`, `number`, `year`, `booktitle`, `eprint`
- `doi`, `doi_url`, `doi_display`, `doi_full_url` (if DOI is present)

### Example: Publications with BibTeX

```latex
\section*{Publications}
{{#bib_collections}}
\subsection*{ {{label}} }
\setcounter{bibcount}{ {{entries_count}} }
\begin{enumerate}
{{#entries}}
\item[\arabic{bibcount}.] {{&author_abbr}} ``{{title}}.''
{{#journal}}\textit{ {{journal}} }{{/journal}}{{#volume}}, \textbf{ {{volume}} }{{/volume}}
{{#number}}, \textit{ {{number}} }{{/number}}, {{year}}.
{{#doi_full_url}}\href{ {{&doi_full_url}} }{ {{doi_display}} }{{/doi_full_url}}
{{#eprint}}\href{https://arxiv.org/abs/{{&eprint}}}{arXiv:{{&eprint}}}{{/eprint}}
\addtocounter{bibcount}{-1}
{{/entries}}
\end{enumerate}
{{/bib_collections}}
```

**Note**: Use `{{&author_abbr}}` with `&` to prevent double-escaping since this field is already LaTeX-formatted.

### Example: Personal Header

```latex
{{#authinfo}}
{\centering
{\Huge\bfseries {{name}}}\\[0.5em]
{{#position}}{{position}}\\{{/position}}
{{#department}}{{department}}{{#institute}}, {{institute}}{{/institute}}\\{{/department}}
\vspace{0.5em}
{{#introduction}}
{{introduction}}
\vspace{0.5em}
{{/introduction}}
{{#email}}\href{mailto:{{&email}}}{ {{email}} }{{/email}}
{{#website}} | \href{ {{&website}} }{ {{website}} }{{/website}}
\par
}
{{/authinfo}}
```

The included template (`examples/templates/cv_template.tex`) demonstrates advanced styling features:

**Custom section headers** with decorative rules:
```latex
\newcommand{\CVSection}[1]{%
    \par\vspace{1.5em}
    \noindent\raisebox{0.25ex}{\rule{2cm}{3pt}}%
    \hspace{0.5em}{\Large\bfseries {#1}}\par
    \vspace{0.3em}
}
```

**Indented content blocks**:
```latex
\newenvironment{CVContent}{%
    \begin{list}{}{%
        \setlength{\leftmargin}{1cm}
        ...
    }
    \item[]
}{%
    \end{list}
}
```

**Color schemes**:
```latex
\definecolor{headercolor}{RGB}{0, 51, 102}
\definecolor{linkcolor}{RGB}{0, 102, 204}
```

### Custom Template Styling

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
