# Paper 3 manuscript build — pandoc + LaTeX pipeline.
#
# Cloned from papers/paper2-protocol-tax/manuscript/Makefile (itself from
# Paper 1) per the bootstrap recipe in
# ../../paper1-iterated-game/manuscript/BUILD.md.
#
#   Markdown + YAML  →  pandoc  →  LaTeX (xelatex)  →  PDF
#
# Targets:
#   make              → paper.pdf (SSRN preprint: letter, 12pt, 1.5 spacing)
#   make review       → paper-review.pdf (double-spaced, wide margins, for edits)
#   make docx         → paper.docx (for co-author track-changes review)
#   make wc           → word count
#   make clean        → remove build artifacts
#
# Requirements (install once — see BUILD.md):
#   - pandoc >= 3.1
#   - a TeX distribution with xelatex (MiKTeX / TeX Live / MacTeX)

NAME     := schmidt-batista-privacy-attribution-2026
SRC      := $(NAME).md
BIB      := ../references.bib
PDF      := $(NAME).pdf
REVIEW   := $(NAME)-review.pdf
DOCX     := $(NAME).docx

PANDOC   := pandoc
ENGINE   := xelatex

# ---------------------------------------------------------------------------
# Default: SSRN-bound PDF.
# Letter size, 12pt, 1.5 spacing, 1in margins, Chicago full-note citations
# (footnote per cite, full bibliography at end), indented paragraphs,
# black links. SSRN accepts clean PDFs — no rigid template. See BUILD.md
# for the output-format decisions and how to swap CSL per target venue.
# ---------------------------------------------------------------------------

$(PDF): $(SRC) $(BIB) pandoc_header.tex
	$(PANDOC) $(SRC) \
	  --output=$(PDF) \
	  --citeproc \
	  --csl=chicago-fullnote-bibliography.csl \
	  --bibliography=$(BIB) \
	  --pdf-engine=$(ENGINE) \
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

paper: $(PDF)

# ---------------------------------------------------------------------------
# Review build: double-spaced, wider margins, room for editorial marks.
# ---------------------------------------------------------------------------

$(REVIEW): $(SRC) $(BIB) pandoc_header.tex
	$(PANDOC) $(SRC) \
	  --output=$(REVIEW) \
	  --citeproc \
	  --csl=chicago-fullnote-bibliography.csl \
	  --bibliography=$(BIB) \
	  --pdf-engine=$(ENGINE) \
	  --include-in-header=pandoc_header.tex \
	  --variable=documentclass:article \
	  --variable=classoption:12pt \
	  --variable=papersize:letter \
	  --variable=geometry:margin=1.25in \
	  --variable=linestretch:2.0 \
	  --variable=indent:true \
	  --variable=colorlinks:true \
	  --variable=linkcolor:black \
	  --variable=urlcolor:black \
	  --variable=citecolor:black \
	  --toc

review: $(REVIEW)

# ---------------------------------------------------------------------------
# DOCX export for co-author review (Word track-changes).
# ---------------------------------------------------------------------------

$(DOCX): $(SRC) $(BIB)
	$(PANDOC) $(SRC) \
	  --output=$(DOCX) \
	  --citeproc \
	  --bibliography=$(BIB) \
	  --toc

docx: $(DOCX)

# ---------------------------------------------------------------------------
# Utilities.
# ---------------------------------------------------------------------------

wc:
	@wc -w $(SRC) | awk '{printf "manuscript: %s words\n", $$1}'

clean:
	rm -f $(PDF) $(REVIEW) $(DOCX) *.aux *.log *.out *.toc *.bbl *.blg

.PHONY: paper review docx wc clean
