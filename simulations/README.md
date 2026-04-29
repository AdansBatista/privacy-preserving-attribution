# Paper 3 — Attack simulation workbench

Reference implementation for §7 of *Privacy-Preserving Attribution in
Protocol-Level Taxation* (Schmidt Batista, 2026). Produces the figures
cited in the paper for Theorem 2a (event detection) and Theorem 2b
(amount disclosure).

## What this produces

Running `python simulate_attacks.py` generates:

- `results/headline.csv` — all simulation numbers across the three batteries.
- `results/config.json` — serialized configuration used for the run.
- `figures/fig01_kstar_vs_alpha.png` — Theorem 2a Monte Carlo verification:
  closed-form vs empirical LRT advantage across cohort sizes.
- `figures/fig02_longitudinal.png` — Theorem 2a closed-form k\*_event
  sensitivity across (α_e, σ_T) at the headline DP budget.
- `figures/fig03_feasibility_boundary.png` — Theorem 2b amount-disclosure
  bound across (α_a, ε), k-independent.

(The figure file names are retained from earlier drafts for caption-stability;
their content has been updated to match the dual-bound formulation.)

## Scope

This workbench reproduces the closed-form bounds proved in §5.3 and verifies
Theorem 2a empirically via Monte Carlo. The audit-traceable derivation lives
in `../council-review-apply/theorem2-dual-bound.R`; this Python reproduces
the headline numbers and produces the manuscript figures.

It is *not*:

- a proof-system benchmark (those are not reproduced here);
- a formal verification of the theorems (the Monte Carlo is an illustration,
  not a proof — see §7.2 of the paper);
- microdata-validated (calibration is illustrative, per §7.1 and §8.5).

## Requirements

Python 3.11+ with the four standard scientific packages:

```bash
pip install -r requirements.txt
```

## Running

From this directory:

```bash
python simulate_attacks.py
```

Runtime: approximately 1–2 minutes on a modern laptop at the default
N = 20,000 Monte Carlo replications.

For a faster preview run (smaller Monte Carlo, less smooth estimates):

```bash
python simulate_attacks.py --n-monte-carlo 5000
```

For a CSV-only run that skips figure generation:

```bash
python simulate_attacks.py --no-figures
```

For a different output directory:

```bash
python simulate_attacks.py --output /path/to/output
```

## Reproducibility

- Random seed `2026` is fixed in the `Config` dataclass. All outputs are
  deterministic given the configuration.
- `results/config.json` is written on every run for provenance.
- The cross-script audit pair: numbers produced here should match the R
  derivation in `../council-review-apply/theorem2-dual-bound.R` (which
  produces the same closed forms via a different path; Monte Carlo here
  agrees with the closed form within sampling noise).

## Re-parameterization

Three re-parameterizations are explicitly invited (see Appendix B of the paper):

1. *Alternative auxiliary-information instantiations.* Edit the `alpha_e_grid`
   or `alpha_a_grid` in the relevant batteries to reflect deployer-specific
   calibrations against an empirical joint distribution.
2. *Alternative cohort-variance calibrations.* Edit `Config.sigma_T` to
   reflect the empirical std-dev of legitimate transaction amounts in the
   deployer's jurisdiction.
3. *Alternative DP mechanisms or composition frameworks.* Modify
   `gaussian_sigma_dp` and `composed_eps_P` to reflect a Laplace mechanism
   or a Rényi-DP composition at a different optimal order; re-run; report
   the budget-composition sensitivity.

## Layout

```
simulations/
├── README.md                 # this file
├── requirements.txt          # numpy, scipy, pandas, matplotlib
├── simulate_attacks.py       # main script
├── figures/                  # generated on run
└── results/                  # generated on run
```

## License

Released under a permissive open-source license to match the paper's
public-replication commitment.
