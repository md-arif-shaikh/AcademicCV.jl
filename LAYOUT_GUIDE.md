# Layout-Based CV Generation

The AcademicCV package now supports customizable CV layouts through a `layout.yml` file.

## Overview

Instead of using a single monolithic template, you can now:
- Choose which sections to include in your CV
- Control the order of sections
- Enable or disable sections as needed

## Structure

The layout-based system consists of:

1. **layout.yml** - Defines which sections to include and their order
2. **Section templates** - Individual `.tex` files for each CV section (in `templates/sections/`)
3. **Base template** - The main document structure (cv_template_base.tex)

## How to Use

### 1. Configure Your Layout

Edit `examples/_data/layout.yml` to customize your CV:

```yaml
sections:
  - id: positions
    enabled: true
    title: Positions
  
  - id: education
    enabled: true
    title: Education
  
  - id: publications
    enabled: true
    title: Publications
  
  - id: visits
    enabled: true
    title: Research Visits
  
  - id: references
    enabled: true
    title: References
```

- **id**: Must match a section template filename (e.g., `positions.tex`)
- **enabled**: Set to `true` to include, `false` to exclude
- **title**: Display title for the section

### 2. Build Your CV

Use the new build script:

```julia
julia --project=. examples/build_cv_with_layout.jl
```

Or use the function directly:

```julia
using AcademicCV

pdf_file = build_cv_with_layout(
    joinpath(@__DIR__, "_data"),
    joinpath(@__DIR__, "templates", "sections"),
    joinpath(@__DIR__, "templates", "cv_template_base.tex"),
    joinpath(@__DIR__, "output")
)
```

## Examples

### Reorder Sections

To put Publications first:

```yaml
sections:
  - id: publications
    enabled: true
    title: Publications
  
  - id: positions
    enabled: true
    title: Positions
  
  # ... other sections
```

### Exclude Sections

To hide the References section:

```yaml
sections:
  - id: references
    enabled: false
    title: References
```

### Custom Titles

```yaml
sections:
  - id: positions
    enabled: true
    title: Professional Experience  # Custom title
```

## Creating New Sections

1. Create a new `.tex` file in `templates/sections/`
2. Use Mustache template syntax (`{{#data}}...{{/data}}`)
3. Add the section to your `layout.yml`

Example (`templates/sections/awards.tex`):

```latex
{{#awards}}
\begin{CVContent}
{\bfseries {{title}}} \hfill {{year}}\\
{{&description}}

\vspace{0.5em}
\end{CVContent}
{{/awards}}
```

Then add to `layout.yml`:

```yaml
sections:
  - id: awards
    enabled: true
    title: Awards and Honors
```

## Backward Compatibility

The original `build_cv()` function still works with the monolithic `cv_template.tex`:

```julia
julia --project=. examples/build_cv.jl
```
