# Build documentation — Paper 3 manuscript

This manuscript folder uses a **pandoc → LaTeX → PDF** pipeline cloned from
Paper 1's pipeline (see [the bootstrap recipe in Paper 1's
BUILD.md](../../paper1-iterated-game/manuscript/BUILD.md#bootstrapping-paper-2-or-3)).

Paper 3 is a privacy/cryptography companion paper — formal threat model,
composition analysis, and attack simulation for the protocol-layer tax
attribution problem of Paper 2. See [`../plan.md`](../plan.md) for the
overall scope, venue ladder, and contingency posture.

## Pipeline

```
 Markdown + YAML  →  pandoc  →  LaTeX (xelatex)  →  PDF
 (schmidt-batista-privacy-attribution-2026.md)        (schmidt-batista-privacy-attribution-2026.pdf)
```

1. Manuscript source is one Markdown file with a YAML front matter carrying
   title, author, abstract, keywords, ACM CCS codes (swap in place of JEL
   codes when the venue is an ACM venue).
2. [`pandoc_header.tex`](pandoc_header.tex) supplies a small LaTeX
   compatibility header (spacing, URL wrapping, title-page styling).
3. [`chicago-fullnote-bibliography.csl`](chicago-fullnote-bibliography.csl)
   controls citation formatting for the SSRN/arXiv preprint default.
   For privacy venues (PoPETs, IEEE S&P, CCS, FC, USENIX Security), swap
   to the venue CSL per the table below.
4. The [`Makefile`](Makefile) wraps the full pandoc command.

## Requirements

Install once:

- **pandoc** >= 3.1 — https://pandoc.org/installing.html
- **A TeX distribution** with `xelatex`:
  - Windows: [MiKTeX](https://miktex.org/download) (recommended) or [TeX Live](https://tug.org/texlive/)
  - macOS: [MacTeX](https://tug.org/mactex/)
  - Linux: `apt install texlive-xetex texlive-fonts-recommended texlive-latex-extra`

Verify:

```bash
pandoc --version
xelatex --version
```

Typical Windows install paths (winget per-user):

- Pandoc: `C:\Users\<user>\AppData\Local\Pandoc\`
- MiKTeX: `C:\Users\<user>\AppData\Local\Programs\MiKTeX\miktex\bin\x64\`

Add both to PATH if they aren't already.

### One-time MiKTeX setup

So MiKTeX auto-fetches missing LaTeX packages on first build instead of
prompting:

```bash
initexmf --set-config-value "[MPM]AutoInstall=1"
```

### PATH pollution workaround (Windows, this machine)

This machine has `C:\dev\stripe.exe` on PATH as if it were a directory,
which makes MiKTeX abort with *"cannot retrieve attributes for the
directory"*. If the build fails with that error, scrub the entry for the
current shell:

```bash
export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v '/c/dev/stripe.exe' | tr '\n' ':' | sed 's/:$//')
make
```

Permanent fix: remove `C:\dev\stripe.exe` from user PATH via
*System Properties → Environment Variables*.

## Commands

From **this folder**:

```bash
make            # build the SSRN/arXiv preprint PDF (default target)
make review     # build <name>-review.pdf — double-spaced, wide margins
make docx       # export <name>.docx for co-author Word review
make wc         # word count
make clean      # remove build artifacts
```

### If `make` isn't available (Windows without GNU Make)

Install [GnuWin32 Make](http://gnuwin32.sourceforge.net/packages/make.htm)
or run pandoc directly:

```bash
pandoc schmidt-batista-privacy-attribution-2026.md \
  --output=schmidt-batista-privacy-attribution-2026.pdf \
  --citeproc \
  --csl=chicago-fullnote-bibliography.csl \
  --bibliography=../references.bib \
  --pdf-engine=xelatex \
  --include-in-header=pandoc_header.tex \
  --variable=documentclass:article \
  --variable=classoption:12pt \
  --variable=papersize:letter \
  --variable=geometry:margin=1in \
  --variable=linestretch:1.5 \
  --variable=indent:true \
  --variable=colorlinks:true \
  --variable=linkcolor:black \
  --variable=urlcolor:black \
  --variable=citecolor:black \
  --toc \
  --toc-depth=2
```

## Output format — design decisions

Each variable below is a deliberate choice. Change them only if you have a
specific reason.

| Variable | Value | Why |
|---|---|---|
| `documentclass` | `article` | Single-column academic layout, standard for preprints; switch to the venue's LaTeX class at camera-ready time. |
| `classoption` | `12pt` | Reviewer-friendly body size. |
| `papersize` | `letter` | SSRN/arXiv default; most privacy venues accept both letter and A4 for review. |
| `geometry` | `margin=1in` | Standard journal margin. |
| `linestretch` | `1.5` | Reviewer-friendly; `2.0` for the `review` target. |
| `indent` | `true` | First-line indent, **no** blank line between paragraphs — classic journal idiom. Pandoc's own default is web-style (blank line between paragraphs); we override. |
| `mainfont` | *(unset)* | LaTeX's default Latin Modern — a classical serif that reads cleanly for mixed prose and inline math. |
| `colorlinks` + `linkcolor`/`urlcolor`/`citecolor` | `true` + `black` | Links are clickable but render in black — matches print-ready preprints. |
| `--csl` | `chicago-fullnote-bibliography.csl` | Footnote-style citations for the preprint default. Venue-specific CSL swap in the table below. |
| `--toc --toc-depth=2` | — | TOC on its own page before the body (forced via `\pretocmd`/`\apptocmd` in `pandoc_header.tex`). |
| `--include-in-header=pandoc_header.tex` | — | Loads the compat + title-page `.tex` described below. |

Additional layout fixes live in [`pandoc_header.tex`](pandoc_header.tex):

- `booktabs`, `microtype`, `xurl` (soft-wrap long URLs in footnotes).
- `titlesec` with compact spacing for a long paper.
- Tighter display-math spacing for long proofs.
- **SSRN-style title page** via `titling` — small-caps centered title,
  centered author with `\thanks{}` footnote for affiliation/email,
  centered date, indented + bold-labelled abstract (via `changepage`).
- TOC forced onto its own page before the body.
- Stub for `\xmpquote` so pandoc's default PDF-metadata template compiles
  without loading `hyperxmp` (which has a load-order conflict with
  `hyperref`).

### Note on citation style

Chicago full-note is the shared preprint default across the three
companion papers. Privacy venues expect different idioms — ACM uses
numbered refs with author-year bibliography, IEEE uses bracket-numbered
refs. Swap the CSL at the point a specific venue's camera-ready
template is adopted.

## Switching citation style per target venue

Per [plan.md §4](../plan.md), Paper 3's venue ladder is:

| Venue | CSL |
|---|---|
| SSRN / arXiv / IACR ePrint preprint (current default) | `chicago-fullnote-bibliography.csl` |
| *Proceedings on Privacy Enhancing Technologies (PoPETs)* — primary target | `association-for-computing-machinery.csl` (closest match; PoPETs uses ACM-style numbered refs) |
| *IEEE Symposium on Security and Privacy (S&P)* | `ieee.csl` |
| *ACM Conference on Computer and Communications Security (CCS)* | `association-for-computing-machinery.csl` |
| *Financial Cryptography and Data Security (FC)* | `springer-lecture-notes-in-computer-science.csl` (Springer LNCS) |
| *USENIX Security* | `usenix.csl` (if available) or `association-for-computing-machinery.csl` as a fallback |

Download the target CSL from <https://www.zotero.org/styles>, save it
next to the manuscript, update the `--csl=...` line in the Makefile,
and rebuild. Final camera-ready submission typically requires the
venue's native LaTeX class — pandoc → LaTeX works for drafting and
review rounds; a copy-out to the venue's template happens once the
paper is accepted.

## Files in this folder

- [`schmidt-batista-privacy-attribution-2026.md`](schmidt-batista-privacy-attribution-2026.md)
  — manuscript source (Markdown + YAML front matter).
- [`pandoc_header.tex`](pandoc_header.tex) — LaTeX compat + title-page styling.
- [`chicago-fullnote-bibliography.csl`](chicago-fullnote-bibliography.csl)
  — citation style definition (Chicago full-note).
- [`Makefile`](Makefile) — build targets.
- [`BUILD.md`](BUILD.md) — this file.
- Generated on build: `<name>.pdf`, `<name>-review.pdf`, `<name>.docx`
  (and LaTeX intermediates — `.aux`, `.log`, etc., cleaned by `make clean`).

The bibliography lives one folder up at
[`../references.bib`](../references.bib) per the per-paper-bib convention
(see [`../../README.md`](../../README.md)).

## Review workflow

1. Edit the `.md` directly — pure Markdown, with inline LaTeX only for
   display math (definitions, theorems, composition bounds in §5).
2. Run `make` to regenerate the PDF.
3. For Word-based co-author review, `make docx` produces a `.docx` — useful
   when the cryptographer collaborator prefers Word track-changes.
4. For red-team passes (plan §10's ten red-team questions; plan §11's
   internal red team), `make review` produces a double-spaced PDF with
   extra margin room for annotation.

## Relationship to the attack-simulation workbench

Paper 3's empirical work (§7 and Appendix B) lives in a simulation
workbench that is **not yet written** (plan §11, T+9 months). The
convention follows Paper 2: simulation source is an `.Rmd` (or Python
notebook, if the cryptographer collaborator prefers a ZK-friendly stack
via `arkworks`/`circom`/`snarkjs`) living in
`../simulations/`; figures and tables are rendered there and pulled into
the manuscript `.md` as artifacts.

For the attack-simulation scope specifically (§7), the workbench produces:

- *k\** as a function of DP budget ε (figure).
- *k\** as a function of auxiliary-information richness α (figure).
- Longitudinal *k\** under composition over T periods (figure).
- Side-channel-inflation table (§6.worst-case).
- Preregistered threshold readings (pass/fail summary).

Proof-system benchmarks (Appendix B — Groth16 vs. PLONK vs. Bulletproofs
wall-clock and circuit-size numbers) are a **separate** artifact from the
attack-simulation workbench and are generated from the cryptographer
collaborator's proof-system implementation, not the attack simulator.
Per [plan.md §7](../plan.md), the two are kept separate to preserve the
attack-simulation-only scope of §7.
