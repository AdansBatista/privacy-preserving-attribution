#!/usr/bin/env python3
"""
simulate_attacks.py — attack-simulation workbench for the paper
"Privacy-Preserving Attribution in Protocol-Level Taxation"
(Schmidt Batista, 2026).

Scope
-----
The simulation visualises and Monte-Carlo verifies the closed-form bounds of
Theorem 2a (event detection) and Theorem 2b (amount disclosure). The closed
forms are derived in `../derivation/theorem2-dual-bound.R`; this script
reproduces their headline numbers and produces the manuscript figures.

Three batteries:
    1. Theorem 2a closed-form k* sensitivity (alpha_e x sigma_T sweep, fig01).
    2. Theorem 2a Monte Carlo verification (LRT advantage vs cohort size, fig02).
    3. Theorem 2b amount-disclosure bound across (alpha_a, epsilon) (fig03).

Reproducibility: fixed seed (2026). Runtime ~1-2 minutes on a modern laptop.
"""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass, asdict
from pathlib import Path

import numpy as np
import pandas as pd
from scipy.stats import norm

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

SEED = 2026


@dataclass
class Config:
    """Headline configuration matching `theorem2-dual-bound.R`."""

    # Per-period DP budget
    epsilon: float = 1.0
    delta: float = 1e-6
    P: int = 12                 # release periods composing the annual budget
    delta_P: float = 1e-6

    # Transaction-distribution calibration
    tau: float = 10_000.0       # clip threshold (USD)
    sigma_T: float = 1_000.0    # legitimate-transaction std-dev (USD)

    # Operational thresholds
    beta_event: float = 0.10
    beta_amount: float = 0.10

    # Monte Carlo
    n_monte_carlo: int = 20_000
    rng_seed: int = SEED


# ---------------------------------------------------------------------------
# Closed-form bounds
# ---------------------------------------------------------------------------

def gaussian_sigma_dp(epsilon: float, delta: float, tau: float) -> float:
    """Gaussian-mechanism noise scale for (epsilon, delta)-DP at sensitivity tau."""
    return tau * np.sqrt(2.0 * np.log(1.25 / delta)) / epsilon


def composed_eps_P(epsilon: float, delta: float, P: int, delta_P: float) -> float:
    """zCDP composition: rho_period -> rho_total -> (eps_P, delta_P)-DP."""
    rho_period = epsilon ** 2 / (4.0 * np.log(1.25 / delta))
    rho_total = P * rho_period
    return rho_total + 2.0 * np.sqrt(rho_total * np.log(1.0 / delta_P))


def event_detection_bound(
    k: int,
    alpha_e: float,
    cfg: Config,
) -> float:
    """Theorem 2a closed-form bound."""
    sigma_dp = gaussian_sigma_dp(cfg.epsilon, cfg.delta, cfg.tau)
    V = k * cfg.sigma_T ** 2 + sigma_dp ** 2
    lrt_term = 2.0 * norm.cdf(cfg.tau / (2.0 * np.sqrt(V))) - 1.0
    return min(alpha_e + lrt_term, 1.0)


def kstar_event(
    alpha_e: float,
    beta_e: float,
    cfg: Config,
) -> int | None:
    """Inversion of Theorem 2a's bound for minimum k satisfying advantage <= beta_e.

    Returns None if alpha_e >= beta_e (Corollary 2a infeasible).
    """
    margin = beta_e - alpha_e
    if margin <= 0:
        return None
    sigma_dp = gaussian_sigma_dp(cfg.epsilon, cfg.delta, cfg.tau)
    z_star = norm.ppf((1.0 + margin) / 2.0)
    v_required = (cfg.tau / (2.0 * z_star)) ** 2
    k_required = (v_required - sigma_dp ** 2) / cfg.sigma_T ** 2
    return int(np.ceil(max(k_required, 0)))


def amount_disclosure_bound(
    alpha_a: float,
    cfg: Config,
) -> float:
    """Theorem 2b closed-form bound (k-independent)."""
    eps_P = composed_eps_P(cfg.epsilon, cfg.delta, cfg.P, cfg.delta_P)
    delta_total = cfg.delta_P + 2 ** -100
    return min(alpha_a + np.tanh(eps_P / 2.0) + delta_total, 1.0)


# ---------------------------------------------------------------------------
# Monte Carlo verification of Theorem 2a
# ---------------------------------------------------------------------------

def run_event_detection_game(
    k: int,
    cfg: Config,
    rng: np.random.Generator,
    mu_T: float = 0.0,
) -> tuple[float, float]:
    """Empirical LRT advantage on the event-detection attack game.

    Returns (advantage, stderr) over `cfg.n_monte_carlo` paired samples.
    """
    sigma_dp = gaussian_sigma_dp(cfg.epsilon, cfg.delta, cfg.tau)
    V_sd = np.sqrt(k * cfg.sigma_T ** 2 + sigma_dp ** 2)
    n = cfg.n_monte_carlo

    Y0 = rng.normal(loc=k * mu_T, scale=V_sd, size=n)
    Y1 = rng.normal(loc=k * mu_T + cfg.tau, scale=V_sd, size=n)

    threshold = k * mu_T + cfg.tau / 2.0
    correct0 = np.mean(Y0 < threshold)
    correct1 = np.mean(Y1 >= threshold)
    accuracy = 0.5 * (correct0 + correct1)
    advantage = max(0.0, 2.0 * accuracy - 1.0)
    stderr = 2.0 * np.sqrt(accuracy * (1.0 - accuracy) / n)
    return advantage, stderr


# ---------------------------------------------------------------------------
# Battery 1 — Theorem 2a closed-form k* sensitivity (fig01)
# ---------------------------------------------------------------------------

def battery_kstar_sensitivity(cfg: Config) -> pd.DataFrame:
    """Closed-form k* across (alpha_e, sigma_T) at the headline DP budget."""
    alphas = [0.00, 0.02, 0.05, 0.08, 0.09]
    sigma_T_grid = [250.0, 500.0, 1_000.0, 1_500.0, 2_000.0, 3_000.0]
    rows = []
    for alpha_e in alphas:
        for sigma_T in sigma_T_grid:
            local_cfg = Config(**{**asdict(cfg), "sigma_T": sigma_T})
            k = kstar_event(alpha_e, cfg.beta_event, local_cfg)
            rows.append({
                "battery": "kstar_sensitivity",
                "alpha_e": alpha_e,
                "sigma_T": sigma_T,
                "kstar_event": k if k is not None else -1,
                "feasible": k is not None,
                "beta_event": cfg.beta_event,
            })
    return pd.DataFrame(rows)


# ---------------------------------------------------------------------------
# Battery 2 — Theorem 2a Monte Carlo verification (fig02)
# ---------------------------------------------------------------------------

def battery_mc_verification(cfg: Config) -> pd.DataFrame:
    """Closed-form vs Monte Carlo across cohort sizes."""
    k_grid = [100, 500, 1_000, 3_000, 10_000, 50_000]
    rows = []
    rng = np.random.default_rng(cfg.rng_seed)
    for k in k_grid:
        cf = event_detection_bound(k, alpha_e=0.0, cfg=cfg)
        mc, mc_err = run_event_detection_game(k, cfg, rng)
        rel_err = (mc - cf) / cf if cf > 0 else np.nan
        rows.append({
            "battery": "mc_verification",
            "k": k,
            "closed_form": round(cf, 4),
            "monte_carlo": round(mc, 4),
            "monte_carlo_stderr": round(mc_err, 4),
            "relative_error": round(rel_err, 4) if not np.isnan(rel_err) else np.nan,
        })
    return pd.DataFrame(rows)


# ---------------------------------------------------------------------------
# Battery 3 — Theorem 2b amount-disclosure bound (fig03)
# ---------------------------------------------------------------------------

def battery_amount_disclosure(cfg: Config) -> pd.DataFrame:
    """Theorem 2b bound across (alpha_a, epsilon)."""
    alpha_a_grid = [0.00, 0.05, 0.10, 0.20, 0.50, 0.85, 0.94]
    epsilon_grid = [0.10, 0.25, 0.50, 1.00, 2.00, 4.00]
    rows = []
    for eps in epsilon_grid:
        for alpha_a in alpha_a_grid:
            local_cfg = Config(**{**asdict(cfg), "epsilon": eps})
            adv = amount_disclosure_bound(alpha_a, local_cfg)
            rows.append({
                "battery": "amount_disclosure",
                "epsilon": eps,
                "alpha_a": alpha_a,
                "adv_amount": round(adv, 4),
                "feasible": adv <= cfg.beta_amount,
                "beta_amount": cfg.beta_amount,
            })
    return pd.DataFrame(rows)


# ---------------------------------------------------------------------------
# Figure helpers
# ---------------------------------------------------------------------------

def make_figure_kstar_sensitivity(df: pd.DataFrame, out_path: Path) -> None:
    import matplotlib.pyplot as plt

    fig, ax = plt.subplots(figsize=(7.5, 4.5))
    sigma_grid = sorted(df["sigma_T"].unique())
    alphas = sorted(df["alpha_e"].unique())
    for alpha in alphas:
        sub = df[df["alpha_e"] == alpha].sort_values("sigma_T")
        # NaN out infeasible values for log plot
        kvals = sub["kstar_event"].astype(float).where(sub["feasible"], np.nan)
        ax.plot(sub["sigma_T"], kvals, "o-", label=fr"$\alpha_e = {alpha:.2f}$")
    ax.set_xlabel(r"Cohort transaction std-dev $\sigma_T$ (USD)")
    ax.set_ylabel(r"Minimum cohort size $k^*_{\mathrm{event}}$")
    ax.set_yscale("log")
    ax.set_title(
        "Figure 1. Theorem 2a $k^*_{\mathrm{event}}$ across "
        r"$(\alpha_e, \sigma_T)$"
        "\nat headline DP budget "
        r"($\varepsilon=1$, $\delta=10^{-6}$, $P=12$, $\beta_e=0.10$, $\tau=\$10\mathrm{k}$)"
    )
    ax.legend(loc="best", fontsize=9, ncols=2)
    ax.grid(True, which="both", alpha=0.3)
    fig.tight_layout()
    fig.savefig(out_path, dpi=180, bbox_inches="tight")
    plt.close(fig)


def make_figure_mc_verification(df: pd.DataFrame, out_path: Path) -> None:
    import matplotlib.pyplot as plt

    fig, ax = plt.subplots(figsize=(7.5, 4.5))
    ks = df["k"].values
    cf = df["closed_form"].values
    mc = df["monte_carlo"].values
    mc_err = df["monte_carlo_stderr"].values

    ax.plot(ks, cf, "ko-", label="Closed form (Theorem 2a)")
    ax.errorbar(
        ks, mc, yerr=mc_err,
        fmt="rs", capsize=3,
        label=f"Monte Carlo (N={20_000:,} per k)",
    )
    ax.set_xscale("log")
    ax.set_xlabel(r"Cohort size $k$")
    ax.set_ylabel("LRT event-detection advantage")
    ax.set_title(
        "Figure 2. Theorem 2a Monte Carlo verification\n"
        r"closed form vs empirical LRT, $\alpha_e = 0$, headline parameters"
    )
    ax.legend(loc="best", fontsize=9)
    ax.grid(True, which="both", alpha=0.3)
    fig.tight_layout()
    fig.savefig(out_path, dpi=180, bbox_inches="tight")
    plt.close(fig)


def make_figure_amount_disclosure(df: pd.DataFrame, out_path: Path) -> None:
    import matplotlib.pyplot as plt

    fig, ax = plt.subplots(figsize=(7.5, 4.5))
    eps_grid = sorted(df["epsilon"].unique())
    alpha_grid = sorted(df["alpha_a"].unique())
    for eps in eps_grid:
        sub = df[df["epsilon"] == eps].sort_values("alpha_a")
        ax.plot(sub["alpha_a"], sub["adv_amount"], "o-",
                label=fr"$\varepsilon = {eps:.2f}$")
    ax.axhline(df["beta_amount"].iloc[0], color="black", linestyle="--",
               label=fr"$\beta_a = {df['beta_amount'].iloc[0]:.2f}$ (target)")
    ax.set_xlabel(r"Auxiliary-information richness $\alpha_a$")
    ax.set_ylabel(r"Theorem 2b bound on $\mathrm{Adv}^{\mathrm{amt}}$")
    ax.set_title(
        "Figure 3. Theorem 2b amount-disclosure bound across "
        r"$(\alpha_a, \varepsilon)$"
        "\n($k$-independent; bound clamps at 1)"
    )
    ax.set_ylim(-0.05, 1.1)
    ax.legend(loc="best", fontsize=9, ncols=2)
    ax.grid(True, alpha=0.3)
    fig.tight_layout()
    fig.savefig(out_path, dpi=180, bbox_inches="tight")
    plt.close(fig)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[1])
    parser.add_argument(
        "--output", type=Path, default=Path(__file__).parent,
        help="Output directory (contains figures/ and results/).",
    )
    parser.add_argument(
        "--no-figures", action="store_true",
        help="Skip figure generation (CSV only).",
    )
    parser.add_argument(
        "--n-monte-carlo", type=int, default=20_000,
        help="Monte Carlo replications for Theorem 2a verification.",
    )
    args = parser.parse_args()

    cfg = Config(n_monte_carlo=args.n_monte_carlo)
    out = args.output.resolve()
    (out / "figures").mkdir(parents=True, exist_ok=True)
    (out / "results").mkdir(parents=True, exist_ok=True)

    print(f"Config: {cfg}")
    print()

    print("[1/3] Theorem 2a k* sensitivity (alpha_e x sigma_T) ...")
    df1 = battery_kstar_sensitivity(cfg)
    print(df1.to_string(index=False))
    print()

    print("[2/3] Theorem 2a Monte Carlo verification ...")
    df2 = battery_mc_verification(cfg)
    print(df2.to_string(index=False))
    print()

    print("[3/3] Theorem 2b amount-disclosure bound (alpha_a x epsilon) ...")
    df3 = battery_amount_disclosure(cfg)
    print(df3.to_string(index=False))
    print()

    combined = pd.concat([df1, df2, df3], axis=0, ignore_index=True, sort=False)
    combined_path = out / "results" / "headline.csv"
    combined.to_csv(combined_path, index=False)
    print(f"Results written to {combined_path}")

    cfg_path = out / "results" / "config.json"
    with cfg_path.open("w") as fh:
        json.dump(asdict(cfg), fh, indent=2)
    print(f"Config written to {cfg_path}")

    if not args.no_figures:
        print()
        print("Generating figures ...")
        # fig01: §7.2 Theorem 2a Monte Carlo verification vs closed form
        make_figure_mc_verification(df2, out / "figures" / "fig01_kstar_vs_alpha.png")
        # fig02: §7.5 Theorem 2a k* sensitivity across (alpha_e, sigma_T)
        make_figure_kstar_sensitivity(df1, out / "figures" / "fig02_longitudinal.png")
        # fig03: §7.5 Theorem 2b amount-disclosure bound across (alpha_a, epsilon)
        make_figure_amount_disclosure(df3, out / "figures" / "fig03_feasibility_boundary.png")
        print(f"Figures written to {out / 'figures'}")


if __name__ == "__main__":
    main()
