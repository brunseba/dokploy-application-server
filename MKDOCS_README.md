# MkDocs Documentation Setup

Complete MkDocs documentation for Dokploy with Material theme, Mermaid diagrams, and PDF export support.

## Documentation Structure

```
docs/
├── index.md                          # Homepage
├── getting-started.md                # Complete getting started guide
├── quick-start.md                    # 10-minute quick start
├── traefik-ovh-dns-setup.md         # Traefik OVH DNS configuration guide
│
├── configuration/                    # Configuration guides
│   ├── script-reference.md          # Script reference documentation
│   └── troubleshooting.md           # Troubleshooting guide
│
├── architecture/                     # TOGAF 9.2 architecture docs
│   ├── index.md                     # Architecture overview
│   ├── 01-vision/                   # Phase A: Architecture Vision
│   ├── 02-business/                 # Phase B: Business Architecture
│   ├── 03-data/                     # Phase C: Data Architecture
│   ├── 04-application/              # Phase D: Application Architecture
│   ├── 05-technology/               # Phase E: Technology Architecture
│   ├── 06-views/                    # Architectural Views
│   ├── 07-requirements/             # Phase F: Requirements
│   ├── 08-decisions/                # ADRs
│   ├── 09-implementation/           # Phase G: Implementation
│   └── 10-governance/               # Phase H: Governance
│
├── deployment/                       # Deployment guides
│   ├── single-server.md
│   ├── multi-server.md
│   ├── high-availability.md
│   └── docker-compose-examples.md
│
├── operations/                       # Operations guides
│   ├── monitoring.md
│   ├── maintenance.md
│   ├── backup-restore.md
│   └── security.md
│
├── reference/                        # Reference documentation
│   ├── api.md
│   ├── cli.md
│   ├── configuration-files.md
│   └── environment-variables.md
│
├── contributing/                     # Contributing guides
│   ├── index.md
│   ├── development.md
│   ├── coding-standards.md
│   └── release-process.md
│
├── stylesheets/
│   └── extra.css                    # Custom styles
│
└── javascripts/
    └── mathjax.js                   # Math rendering
```

## Installation

### Prerequisites

Python 3.8+ required.

### Install Dependencies

```bash
# Install MkDocs with Material theme
pip install mkdocs-material

# Install Mermaid diagram support
pip install mkdocs-mermaid2-plugin

# Install PDF export (optional)
pip install mkdocs-with-pdf

# Install git revision tracking (optional)
pip install mkdocs-git-revision-date-localized-plugin
```

Or use a single command:

```bash
pip install mkdocs-material mkdocs-mermaid2-plugin mkdocs-with-pdf mkdocs-git-revision-date-localized-plugin
```

## Usage

### Serve Locally

Start development server with hot-reload:

```bash
mkdocs serve
```

Open your browser to: http://127.0.0.1:8000

### Build Static Site

Generate static HTML files:

```bash
mkdocs build
```

Output will be in the `site/` directory.

### Deploy to GitHub Pages

Deploy documentation to GitHub Pages:

```bash
mkdocs gh-deploy
```

This builds and pushes to the `gh-pages` branch.

## Features

### Material Theme
- ✅ Modern, responsive design
- ✅ Light/dark mode toggle
- ✅ Navigation tabs and sections
- ✅ Table of contents integration
- ✅ Search functionality

### Mermaid Diagrams
- ✅ 45+ architecture diagrams
- ✅ Auto-rendering in documentation
- ✅ ERD, flowcharts, sequence diagrams

### PDF Export
- ✅ Generate complete PDF documentation
- ✅ Enable with: `ENABLE_PDF_EXPORT=1 mkdocs build`
- ✅ Output: `site/pdf/dokploy-documentation.pdf`

### Git Integration
- ✅ Track document changes
- ✅ Show last updated dates
- ✅ Display creation dates
- ✅ Currently commented out in mkdocs.yml

### Code Highlighting
- ✅ Syntax highlighting for 200+ languages
- ✅ Copy-to-clipboard button
- ✅ Line numbering support

## Configuration

### Main Configuration File

`mkdocs.yml` - Main configuration file with:
- Site metadata
- Theme settings
- Plugins configuration
- Markdown extensions
- Navigation structure

### Custom Styling

`docs/stylesheets/extra.css` - Custom CSS for:
- Color schemes
- Code block styling
- Table enhancements
- Mermaid diagram styling

### Custom JavaScript

`docs/javascripts/mathjax.js` - MathJax configuration for:
- LaTeX math rendering
- Inline and display math
- Equation numbering

## Documentation Statistics

| Category | Count |
|----------|-------|
| **Total .md files** | 59 |
| **Architecture docs** | 31 |
| **Configuration guides** | 2 |
| **Deployment guides** | 4 |
| **Operations guides** | 4 |
| **Reference docs** | 4 |
| **Contributing guides** | 4 |
| **Mermaid diagrams** | 45+ |
| **Code examples** | 150+ |

## Customization

### Update Site Information

Edit `mkdocs.yml`:

```yaml
site_name: Your Site Name
site_url: https://your-domain.github.io/your-repo/
repo_url: https://github.com/your-username/your-repo
```

### Change Theme Colors

Edit `mkdocs.yml` under `theme.palette`:

```yaml
theme:
  palette:
    primary: indigo  # Change to: blue, teal, green, etc.
    accent: indigo   # Change to match primary
```

### Add Analytics

Edit `mkdocs.yml` under `extra.analytics`:

```yaml
extra:
  analytics:
    provider: google
    property: G-XXXXXXXXXX  # Your Google Analytics ID
```

### Enable PDF Export

Uncomment in `mkdocs.yml` or set environment variable:

```bash
ENABLE_PDF_EXPORT=1 mkdocs build
```

## Troubleshooting

### Missing Dependencies

**Error**: `ModuleNotFoundError: No module named 'material'`

**Solution**:
```bash
pip install mkdocs-material
```

### Mermaid Diagrams Not Rendering

**Error**: Diagrams show as code blocks

**Solution**:
```bash
pip install mkdocs-mermaid2-plugin
```

Check `mkdocs.yml` has:
```yaml
plugins:
  - mermaid2
```

### Build Warnings

**Warning**: "WARNING - Doc file 'xxx.md' contains a link..."

**Solution**: Check that all internal links use correct paths relative to the docs/ directory.

### Git Plugin Errors

**Error**: Git revision plugin fails

**Solution**: Temporarily comment out in `mkdocs.yml`:
```yaml
plugins:
  # - git-revision-date-localized:
  #     enable_creation_date: true
```

## Development Workflow

### 1. Make Changes

Edit markdown files in `docs/` directory.

### 2. Preview Changes

```bash
mkdocs serve
```

### 3. Check Build

```bash
mkdocs build --strict
```

The `--strict` flag treats warnings as errors.

### 4. Deploy

```bash
# To GitHub Pages
mkdocs gh-deploy

# Or build for custom hosting
mkdocs build
# Upload site/ directory to your host
```

## Documentation Standards

### File Naming
- Use lowercase with hyphens: `my-document.md`
- Match navigation structure in `mkdocs.yml`

### Markdown Guidelines
- Use ATX-style headers: `# Header`
- Include code language specifiers: ` ```bash `
- Use relative links: `[link](../other-doc.md)`
- Include alt text for images: `![description](image.png)`

### Code Blocks
```yaml
# Good - with language
```bash
docker ps
`` `

# Bad - no language
`` `
docker ps
`` `
```

### Mermaid Diagrams
```markdown
`` `mermaid
graph TD
    A[Start] --> B[Process]
    B --> C[End]
`` `
```

## Scripts

### Generate Missing Documentation

```bash
./scripts/generate-docs.sh
```

This script creates placeholder documentation for missing sections.

## Next Steps

1. **Review Documentation**
   - Read through all sections
   - Fix any broken links
   - Update placeholder content

2. **Customize Theme**
   - Update colors and branding
   - Add your logo
   - Customize footer

3. **Add Content**
   - Expand placeholder pages
   - Add screenshots and diagrams
   - Include real examples

4. **Deploy**
   - Set up GitHub Pages
   - Configure custom domain
   - Set up CI/CD for auto-deployment

## Resources

- **MkDocs**: https://www.mkdocs.org/
- **Material Theme**: https://squidfunk.github.io/mkdocs-material/
- **Mermaid**: https://mermaid-js.github.io/
- **MkDocs Plugins**: https://github.com/mkdocs/mkdocs/wiki/MkDocs-Plugins

## Support

For issues with:
- **MkDocs**: https://github.com/mkdocs/mkdocs/issues
- **Material Theme**: https://github.com/squidfunk/mkdocs-material/issues
- **This Documentation**: Open an issue in your repository

---

**Created**: 2024-12-31  
**MkDocs Version**: 1.5+  
**Material Theme Version**: 9.5+  
**Status**: Production Ready
