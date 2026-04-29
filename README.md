# Privacy-Preserving Attribution in Protocol-Level Taxation

Replication package for the paper

> **Privacy-Preserving Attribution in Protocol-Level Taxation: A Formal Treatment of the Aggregation-Leakage Tradeoff**
> Adans Schmidt Batista, 2026.
> Cryptology ePrint Archive Report 2026/TBD (placeholder pending editor review).

The paper formalizes the cohort-aggregation privacy tradeoff for a protocol-level transaction tax and proves a **dual cohort-level bound** that separates two threats prior cohort-DP analyses have generally conflated:

- **Theorem 2a — event detection.** Closed-form Gaussian-LRT advantage on whether an anomalous transaction occurred in a cohort of size *k*. The 1/√*k* scaling that emerges in the natural-variance-dominated regime comes from the variance of legitimate cohort transactions, not from differential-privacy composition.
- **Theorem 2b — amount disclosure.** Closed-form *k*-independent bound under zero-concentrated DP composition (Bun-Steinke 2016) plus a TV chain rule for auxiliary information.

Corollaries 2a / 2b state closed-form Kifer-Machanavajjhala-style infeasibility regimes when auxiliary information meets or exceeds the deployer's operational target.

This repository contains the manuscript, the audit-traceable R script that derives every closed-form number, the Python attack-simulation workbench that produces Figures 1–3, and the build configuration to rebuild the PDF.

## Contents

```
.
├── README.md                        — this file
├── LICENSE                          — MIT (code) + CC-BY-4.0 (paper)
├── manuscript/
│   ├── schmidt-batista-privacy-attribution-2026.md    — paper source (Pandoc Markdown + LaTeX math)
│   ├── schmidt-batista-privacy-attribution-2026.pdf   — current rendered PDF
│   ├── Makefile                     — pandoc → xelatex pipeline
│   ├── pandoc_header.tex            — LaTeX preamble
│   ├── chicago-fullnote-bibliography.csl  — citation style
│   └── BUILD.md                     — detailed build instructions
├── references.bib                   — bibliography (BibTeX, ~70 entries)
├── derivation/
│   ├── theorem2-dual-bound.R        — R script: closed-form bounds, sensitivity tables, Monte Carlo
│   └── theorem2-dual-bound-output.txt  — captured R output (audit trail)
└── simulations/
    ├── README.md                    — simulation-specific instructions
    ├── requirements.txt             — Python deps (numpy, scipy, pandas, matplotlib)
    ├── simulate_attacks.py          — attack-simulation workbench
    ├── results/                     — generated CSVs (headline.csv, config.json)
    └── figures/                     — generated PNGs (Figures 1–3)
```

## How to reproduce

The paper has two reproducible artefacts: an R derivation script (the closed-form bounds and sensitivity tables in §5.5 and Appendix A.3) and a Python simulation (the Monte Carlo verification and figures in §7).

### Closed-form bounds and sensitivity tables (R)

```bash
# requires R 4.4+ with base packages only (no exotic dependencies)
Rscript derivation/theorem2-dual-bound.R > derivation/theorem2-dual-bound-output.txt 2>&1
```

Runtime: ~5 seconds. Produces:

- The headline parameters and derived quantities (§5.5).
- The Theorem 2a `k*_event` sensitivity table across (α_e, σ_T) (§5.5 main table).
- The per-period ε sensitivity table (§5.5 secondary table).
- A Monte Carlo verification (N = 20,000) of the closed-form Gaussian-LRT advantage at six cohort sizes.
- The Theorem 2b amount-disclosure regime values across the auxiliary-information tiers.

The script is the single source of truth for every numerical claim in the paper.

### Attack simulation and figures (Python)

```bash
cd simulations
pip install -r requirements.txt    # numpy, scipy, pandas, matplotlib
python simulate_attacks.py
```

Runtime: ~1–2 minutes on a modern laptop at the default Monte Carlo count (N = 20,000). Produces:

- `results/headline.csv` — all simulation numbers across the three batteries (k* sensitivity, Monte Carlo verification, amount-disclosure regime).
- `results/config.json` — serialized configuration for provenance.
- `figures/fig01_kstar_vs_alpha.png` — Theorem 2a Monte Carlo verification (closed form vs empirical LRT).
- `figures/fig02_longitudinal.png` — Theorem 2a `k*_event` sensitivity across (α_e, σ_T).
- `figures/fig03_feasibility_boundary.png` — Theorem 2b amount-disclosure bound across (α_a, ε).

For a faster preview run with smaller Monte Carlo (less smooth):

```bash
python simulate_attacks.py --n-monte-carlo 5000
```

For CSV-only (no figures):

```bash
python simulate_attacks.py --no-figures
```

### Rebuilding the PDF

The manuscript is Pandoc Markdown with LaTeX math; the build pipeline is `pandoc → xelatex → PDF`. Requires:

- `pandoc ≥ 3.1`
- A TeX distribution with `xelatex` (MiKTeX, TeX Live, or MacTeX).

```bash
cd manuscript
make
```

Or directly:

```bash
pandoc manuscript/schmidt-batista-privacy-attribution-2026.md \
  --output=schmidt-batista-privacy-attribution-2026.pdf \
  --citeproc \
  --csl=manuscript/chicago-fullnote-bibliography.csl \
  --bibliography=references.bib \
  --pdf-engine=xelatex \
  --include-in-header=manuscript/pandoc_header.tex \
  --variable=documentclass:article \
  --variable=classoption:12pt \
  --variable=papersize:letter \
  --variable=geometry:margin=1in \
  --variable=linestretch:1.5 \
  --toc --toc-depth=2
```

See `manuscript/BUILD.md` for the full pipeline (review-mode PDF, `.docx` for track-changes, etc.).

## Reproducibility commitments

- **R script.** `set.seed(2026)` at the top; all parameters in a top-level `H` list. Output is deterministic given the configuration.
- **Python script.** `rng_seed = 2026` in the `Config` dataclass; results are deterministic given the configuration.
- **Cross-script audit.** The Monte Carlo verification produced by the R script and the Monte Carlo battery produced by the Python script use the same closed-form expressions and agree within sampling noise (1/√N). This is the audit-trail commitment: the closed-form derivation in R is reproduced via a different code path in Python, and both match the figures and tables in the manuscript.

## Re-parameterizing for your own deployment

Three re-parameterizations are explicitly invited:

1. **Auxiliary-information richness.** Edit the `alpha_e` / `alpha_a` grids in `derivation/theorem2-dual-bound.R` and `simulations/simulate_attacks.py` to match the empirical TV-distance richness you compute from your own auxiliary-data joint distributions. The Tier-2 anchor used in the paper (α_e ≈ 0.94 from de Montjoye-style spatiotemporal uniqueness) is illustrative, not operational.
2. **Cohort transaction variance.** Edit `Config.sigma_T` in the Python config or the `H` list in the R script to match the empirical std-dev of legitimate transaction amounts in your jurisdiction.
3. **DP budget and composition.** Edit `epsilon`, `delta`, `P` in either script. The R script implements the zero-concentrated DP chain (Bun-Steinke 2016 Prop 1.6 → Lemma 2.3 → Prop 1.3); for an alternative composition framework (Rényi DP, the f-DP / Gaussian-DP framework, or analytic Gaussian calibration) substitute the relevant function.

## Citation

If you use these results, please cite the paper:

```bibtex
@misc{schmidt-batista-2026-privacy-attribution,
  author       = {Adans Schmidt Batista},
  title        = {Privacy-Preserving Attribution in Protocol-Level Taxation:
                  A Formal Treatment of the Aggregation-Leakage Tradeoff},
  howpublished = {Cryptology ePrint Archive, Report 2026/TBD},
  year         = {2026},
  url          = {https://eprint.iacr.org/2026/TBD}
}
```

## License

- **Paper text** (`manuscript/`): Creative Commons Attribution 4.0 International (CC-BY-4.0).
- **Code** (`derivation/`, `simulations/`): MIT License.

See [LICENSE](LICENSE) for full text.

## Contact

Adans Schmidt Batista
Email: adansschmidtbatista@gmail.com

This is a preprint. Co-author and external cryptographer review for venue submission is in progress; specific follow-on items are listed in §8.5 of the paper.
