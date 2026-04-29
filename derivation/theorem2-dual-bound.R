###############################################################################
#
# Schmidt-Batista 2026 — Privacy-Preserving Attribution in Protocol-Level
# Taxation
#
# Theorem 2 — Dual-Bound Derivation
#
# This script implements the corrected dual-bound formulation:
#
#   Theorem 2a (Event detection)
#       Adv_event(k, alpha_event, beta_event) <= alpha_event +
#           2 * Phi( tau / (2 * sqrt(k * sigma_T^2 + sigma_DP^2)) ) - 1
#       1/sqrt(k) scaling emerges naturally from cohort variance
#       (NOT from DP composition).
#
#   Theorem 2b (Amount disclosure)
#       Adv_amount(alpha_amount) <= min(
#           alpha_amount + tanh(eps_P / 2) + delta_total, 1
#       )
#       k-independent. zCDP composition (Bun-Steinke 2016).
#
# The two bounds quantify two distinct threats; both must hold for the
# composed mechanism to satisfy the application-layer privacy goal.
#
# Run with:
#   Rscript theorem2-dual-bound.R > theorem2-dual-bound-output.txt 2>&1
#
###############################################################################

set.seed(2026L)
options(scipen = 999, digits = 6)

###############################################################################
# 1. Helper functions
###############################################################################

# zCDP per-period parameter for Gaussian mechanism with sensitivity Delta and
# noise scale sigma calibrated to (eps, delta) per Bun-Steinke 2016 Prop 1.6.
gaussian_zcdp_per_period <- function(eps, delta) {
  eps^2 / (4 * log(1.25 / delta))
}

# Linear composition of P independent rho-zCDP mechanisms (Bun-Steinke Lemma 2.3).
zcdp_compose <- function(rho_period, P) {
  P * rho_period
}

# Conversion zCDP -> (eps_P, delta_P)-DP (Bun-Steinke Prop 1.3).
zcdp_to_dp <- function(rho_total, delta_P) {
  rho_total + 2 * sqrt(rho_total * log(1 / delta_P))
}

# Gaussian noise scale for (eps, delta)-DP at sensitivity tau.
gaussian_sigma <- function(eps, delta, tau) {
  tau * sqrt(2 * log(1.25 / delta)) / eps
}

# Optimal LRT advantage on N(mu_0, sigma2) vs N(mu_1, sigma2).
# Equivalent to TV distance between the two normals.
lrt_advantage_gaussian <- function(delta_mu, sigma) {
  2 * pnorm(abs(delta_mu) / (2 * sigma)) - 1
}

###############################################################################
# 2. Theorem 2a — Event-detection bound (closed form)
###############################################################################
#
# Setup:
#   k         cohort size
#   tau       clip / anomaly magnitude
#   sigma_T   std-dev of legitimate transaction amounts (cohort variance)
#   sigma_DP  Gaussian DP noise std-dev
#   alpha_e   TV-richness of auxiliary-info channel about anomaly occurrence
#
# Marginal aggregate (over i.i.d. cohort, given anomaly indicator b):
#   Y | b=0  ~  N(k * mu_T,           k * sigma_T^2 + sigma_DP^2)
#   Y | b=1  ~  N(k * mu_T + tau,     k * sigma_T^2 + sigma_DP^2)
#
# The optimal LRT advantage on b given (Y, A) is bounded by the TV chain rule:
#   Adv_event <= alpha_e + LRT( N(k*mu, V),  N(k*mu + tau, V) )
#              = alpha_e + 2*Phi(tau / (2*sqrt(V))) - 1
# with V = k*sigma_T^2 + sigma_DP^2.
#
# In the natural-variance-dominated regime (k*sigma_T^2 >> sigma_DP^2):
#   Adv_event ~= alpha_e + tau / (sqrt(2*pi*k) * sigma_T)        [1/sqrt(k)]
#
# In the DP-dominated regime (sigma_DP^2 >> k*sigma_T^2):
#   Adv_event ~= alpha_e + 2*Phi(tau / (2*sigma_DP)) - 1         [k-independent]
###############################################################################

event_detection_bound <- function(k, alpha_e, tau, sigma_T, sigma_DP) {
  V <- k * sigma_T^2 + sigma_DP^2
  pmin(alpha_e + lrt_advantage_gaussian(tau, sqrt(V)), 1)
}

# Inversion: smallest k s.t. event_detection_bound(k, ...) <= beta.
# Solve 2*Phi(tau / (2*sqrt(V))) - 1 = beta - alpha_e, then back out k.
# Returns NA if beta <= alpha_e (infeasible, regardless of k).
kstar_event <- function(alpha_e, beta_e, tau, sigma_T, sigma_DP) {
  margin <- beta_e - alpha_e
  if (margin <= 0) return(NA_real_)
  z_star <- qnorm((1 + margin) / 2)         # Phi^{-1}((1+margin)/2)
  V_required <- (tau / (2 * z_star))^2
  k_required <- (V_required - sigma_DP^2) / sigma_T^2
  ceiling(max(k_required, 0))
}

###############################################################################
# 3. Theorem 2b — Amount-disclosure bound (closed form, k-independent)
###############################################################################
#
# Setup:
#   eps, delta   per-period DP budget
#   P            number of release periods composing the budget
#   alpha_a      TV-richness of auxiliary-info channel about target amount
#   delta_P      acceptable failure probability for composition tail
#   negl_lambda  cryptographic negligibility (lambda=128 -> 2^-100)
#
# Per-record amount-disclosure advantage:
#   Adv_amt <= alpha_a + tanh(eps_P / 2) + delta_total                    (*)
#
# where eps_P = rho_total + 2*sqrt(rho_total * log(1/delta_P))
# and delta_total = delta_P + negl(lambda).
#
# Cohort size k does NOT appear. The DP guarantee is per-neighboring-database;
# enlarging the cohort does not dilute it.
###############################################################################

amount_disclosure_bound <- function(alpha_a, eps, delta, P, delta_P,
                                     lambda = 128) {
  rho_period <- gaussian_zcdp_per_period(eps, delta)
  rho_total  <- zcdp_compose(rho_period, P)
  eps_P      <- zcdp_to_dp(rho_total, delta_P)
  negl       <- 2^(-100)                          # lambda = 128 placeholder
  delta_total <- delta_P + negl
  pmin(alpha_a + tanh(eps_P / 2) + delta_total, 1)
}

# Helper to expose the composed eps_P alone.
composed_eps_P <- function(eps, delta, P, delta_P) {
  rho_period <- gaussian_zcdp_per_period(eps, delta)
  rho_total  <- zcdp_compose(rho_period, P)
  zcdp_to_dp(rho_total, delta_P)
}

###############################################################################
# 4. Headline parameters (deployment-realistic; calibrated standalone, NOT to
#    any external narrative)
###############################################################################

H <- list(
  # Per-period DP budget
  eps        = 1.0,
  delta      = 1e-6,
  P          = 12,                       # monthly aggregation, annual budget
  delta_P    = 1e-6,
  # Transaction-distribution calibration
  tau        = 10000,                    # clip threshold ($10k)
  sigma_T    = 1000,                     # legitimate-transaction std-dev
  # Auxiliary-information tiers (TV richness alpha)
  alpha_e_T1 = 0.05,                     # Tier 1: weak event-timing aux info
  alpha_e_T2 = 0.50,                     # Tier 2: moderate
  alpha_e_T3 = 0.85,                     # Tier 3: rich
  alpha_a_T1 = 0.05,                     # Tier 1 amount-disclosure aux info
  alpha_a_T2 = 0.50,                     # Tier 2
  alpha_a_T3 = 0.94,                     # Tier 3 (de Montjoye-style upper bound)
  # Operational thresholds
  beta_event  = 0.10,                    # event-detection target
  beta_amount = 0.10                     # amount-disclosure target
)

###############################################################################
# 5. Headline computations
###############################################################################

cat("================================================================\n")
cat("Schmidt-Batista 2026 — Theorem 2 Dual-Bound Derivation\n")
cat("================================================================\n\n")

cat("HEADLINE PARAMETERS\n")
cat("-------------------\n")
cat(sprintf("  Per-period DP:    eps=%.3f, delta=%.0e, P=%d, delta_P=%.0e\n",
            H$eps, H$delta, H$P, H$delta_P))
cat(sprintf("  Transactions:     tau=$%d, sigma_T=$%d\n",
            as.integer(H$tau), as.integer(H$sigma_T)))
cat(sprintf("  Operational:      beta_event=%.2f, beta_amount=%.2f\n\n",
            H$beta_event, H$beta_amount))

# Composed annual epsilon
sigma_DP <- gaussian_sigma(H$eps, H$delta, H$tau)
eps_P    <- composed_eps_P(H$eps, H$delta, H$P, H$delta_P)

cat("DERIVED QUANTITIES\n")
cat("------------------\n")
cat(sprintf("  Per-period sigma_DP                = $%.0f\n", sigma_DP))
cat(sprintf("  Composed eps_P (12-fold zCDP)      = %.3f\n", eps_P))
cat(sprintf("  tanh(eps_P/2)                       = %.4f\n", tanh(eps_P / 2)))
cat("\n")

###############################################################################
# 6. Theorem 2b feasibility check (amount disclosure, k-independent)
###############################################################################

cat("THEOREM 2b — AMOUNT-DISCLOSURE BOUND  (k-independent)\n")
cat("------------------------------------------------------\n")

amt_T1 <- amount_disclosure_bound(H$alpha_a_T1, H$eps, H$delta, H$P, H$delta_P)
amt_T2 <- amount_disclosure_bound(H$alpha_a_T2, H$eps, H$delta, H$P, H$delta_P)
amt_T3 <- amount_disclosure_bound(H$alpha_a_T3, H$eps, H$delta, H$P, H$delta_P)

cat(sprintf("  Tier 1 (alpha_a=%.2f): Adv_amount <= %.4f  [feasible if <= %.2f]\n",
            H$alpha_a_T1, amt_T1, H$beta_amount))
cat(sprintf("  Tier 2 (alpha_a=%.2f): Adv_amount <= %.4f\n",
            H$alpha_a_T2, amt_T2))
cat(sprintf("  Tier 3 (alpha_a=%.2f): Adv_amount <= %.4f\n",
            H$alpha_a_T3, amt_T3))
cat("\n")

cat("Interpretation (Theorem 2b):\n")
cat("  * Cohort size k does NOT appear in this bound — the DP guarantee\n")
cat("    is per-neighboring-database and is not diluted by enlarging\n")
cat("    the cohort.\n")
cat("  * Feasibility for amount disclosure requires\n")
cat("    alpha_a + tanh(eps_P/2) + delta_total < beta_amount.\n")
cat("  * At the headline (eps=1.0, P=12), tanh(eps_P/2) alone exceeds\n")
cat("    beta_amount=0.10. Meaningful amount-disclosure privacy at this\n")
cat("    budget therefore requires either a tighter per-period eps OR a\n")
cat("    relaxed beta_amount; this is a real constraint of standard\n")
cat("    Gaussian-DP and is part of the paper's negative result.\n")
cat("\n")

###############################################################################
# 7. Theorem 2a feasibility (event detection, k-dependent)
###############################################################################

cat("THEOREM 2a — EVENT-DETECTION BOUND  (k-dependent)\n")
cat("--------------------------------------------------\n")

kstar_T1 <- kstar_event(H$alpha_e_T1, H$beta_event, H$tau, H$sigma_T, sigma_DP)
kstar_T2 <- kstar_event(H$alpha_e_T2, H$beta_event, H$tau, H$sigma_T, sigma_DP)
kstar_T3 <- kstar_event(H$alpha_e_T3, H$beta_event, H$tau, H$sigma_T, sigma_DP)

fmt_kstar <- function(x) {
  if (is.na(x)) "INFEASIBLE  (alpha_e >= beta_event)"
  else          formatC(x, format = "d", big.mark = ",")
}

cat(sprintf("  Tier 1 (alpha_e=%.2f): k* = %s\n",
            H$alpha_e_T1, fmt_kstar(kstar_T1)))
cat(sprintf("  Tier 2 (alpha_e=%.2f): k* = %s\n",
            H$alpha_e_T2, fmt_kstar(kstar_T2)))
cat(sprintf("  Tier 3 (alpha_e=%.2f): k* = %s\n",
            H$alpha_e_T3, fmt_kstar(kstar_T3)))
cat("\n")

# Regime crossover
k_crossover <- ceiling(sigma_DP^2 / H$sigma_T^2)
cat(sprintf("  Regime crossover (k*sigma_T^2 = sigma_DP^2):  k = %s\n",
            formatC(k_crossover, format = "d", big.mark = ",")))
cat("    Below this k, DP noise dominates and 2a saturates near 2b.\n")
cat("    Above this k, cohort variance dominates and 1/sqrt(k) operates.\n")
cat("\n")

###############################################################################
# 8. Sensitivity sweep — k* under Theorem 2a vs (alpha_e, sigma_T)
###############################################################################

cat("SENSITIVITY SWEEP — k* (Theorem 2a) vs (alpha_e, sigma_T)\n")
cat("at beta_event=0.10, eps=1.0, delta=1e-6, tau=$10k, P=12\n")
cat("-----------------------------------------------------------------\n")

alpha_grid   <- c(0.00, 0.02, 0.05, 0.08, 0.09)         # below beta_event
sigma_T_grid <- c(250, 500, 1000, 1500, 2000, 3000)

sweep <- expand.grid(alpha_e = alpha_grid, sigma_T = sigma_T_grid)
sweep$kstar <- mapply(
  kstar_event,
  alpha_e = sweep$alpha_e,
  sigma_T = sweep$sigma_T,
  MoreArgs = list(beta_e = H$beta_event, tau = H$tau, sigma_DP = sigma_DP)
)

# Reshape for printing
mat <- matrix(NA_integer_, nrow = length(alpha_grid),
              ncol = length(sigma_T_grid))
rownames(mat) <- sprintf("alpha=%.2f", alpha_grid)
colnames(mat) <- sprintf("sigma_T=$%d", sigma_T_grid)
for (i in seq_along(alpha_grid)) {
  for (j in seq_along(sigma_T_grid)) {
    v <- sweep$kstar[sweep$alpha_e == alpha_grid[i] &
                     sweep$sigma_T == sigma_T_grid[j]]
    mat[i, j] <- if (is.na(v)) NA_integer_ else as.integer(v)
  }
}
print(mat)
cat("\n")
cat("Rows: alpha_e (event-detection aux-info richness)\n")
cat("Cols: sigma_T  (legitimate-transaction std-dev, USD)\n")
cat("Cell: ceiling(k*) — minimum cohort size for event-detection privacy\n")
cat("\n")

###############################################################################
# 9. Sensitivity to the per-period DP budget
###############################################################################

cat("SENSITIVITY — k* vs per-period eps  (alpha_e=0.05, sigma_T=$1000)\n")
cat("-----------------------------------------------------------------\n")
eps_grid <- c(0.25, 0.5, 1.0, 2.0, 4.0)
for (e in eps_grid) {
  s_DP_e <- gaussian_sigma(e, H$delta, H$tau)
  k_e    <- kstar_event(0.05, H$beta_event, H$tau, H$sigma_T, s_DP_e)
  e_P    <- composed_eps_P(e, H$delta, H$P, H$delta_P)
  cat(sprintf("  eps=%.2f -> sigma_DP=$%-7.0f  eps_P=%-6.3f  k*=%s\n",
              e, s_DP_e, e_P, fmt_kstar(k_e)))
}
cat("\n")
cat("Note: smaller per-period eps tightens both bounds (less DP noise to\n")
cat("hide cohort variance, but also smaller per-record amount-disclosure\n")
cat("advantage). The deployment trade-off is explicit.\n")
cat("\n")

###############################################################################
# 10. Monte Carlo verification — Theorem 2a closed form vs empirical LRT
###############################################################################

cat("MONTE CARLO VERIFICATION — empirical LRT advantage vs closed form\n")
cat("(N=20,000 replications per cohort size; alpha_e=0, headline params)\n")
cat("------------------------------------------------------------------\n")

mc_event_lrt <- function(k, tau, sigma_T, sigma_DP, mu_T = 0, N = 20000L) {
  V_sd <- sqrt(k * sigma_T^2 + sigma_DP^2)
  # Sample marginal Y under each hypothesis
  Y0 <- rnorm(N, mean = k * mu_T,         sd = V_sd)
  Y1 <- rnorm(N, mean = k * mu_T + tau,   sd = V_sd)
  threshold <- k * mu_T + tau / 2
  # Bayes-optimal classifier (assuming equal priors)
  correct0 <- mean(Y0 < threshold)
  correct1 <- mean(Y1 >= threshold)
  acc <- 0.5 * (correct0 + correct1)
  2 * acc - 1                              # advantage = 2*accuracy - 1
}

k_test_grid <- c(100, 500, 1000, 3000, 10000, 50000)
cat(sprintf("  %-8s  %-12s  %-12s  %-8s\n",
            "k", "closed_form", "monte_carlo", "rel_err"))
for (k_t in k_test_grid) {
  cf <- event_detection_bound(k_t, alpha_e = 0,
                              tau = H$tau, sigma_T = H$sigma_T,
                              sigma_DP = sigma_DP)
  mc <- mc_event_lrt(k_t, H$tau, H$sigma_T, sigma_DP)
  rel <- if (cf > 0) (mc - cf) / cf else NA_real_
  cat(sprintf("  %-8s  %-12.4f  %-12.4f  %-+8.2f%%\n",
              formatC(k_t, format = "d", big.mark = ","),
              cf, mc, 100 * rel))
}
cat("\n")
cat("Closed-form is exact for the marginal Gaussian-vs-Gaussian LRT;\n")
cat("Monte Carlo agrees within sampling noise (~1/sqrt(N)).\n")
cat("\n")

###############################################################################
# 11. Summary
###############################################################################

cat("================================================================\n")
cat("HEADLINE SUMMARY\n")
cat("================================================================\n\n")

cat(sprintf("  Theorem 2a event-detection k* (Tier 1 alpha_e=0.05,\n"))
cat(sprintf("    sigma_T=$1000):                            %s\n",
            fmt_kstar(kstar_T1)))
cat(sprintf("  Theorem 2a Tier 2/3 (alpha_e >= beta_event): INFEASIBLE\n"))
cat(sprintf("  Theorem 2b amount-disclosure bound at Tier 1: %.4f\n", amt_T1))
cat(sprintf("  Theorem 2b amount-disclosure bound at Tier 3: %.4f\n", amt_T3))
cat("\n")

cat("Key results:\n")
cat("  1. The 1/sqrt(k) scaling of the event-detection bound emerges from\n")
cat("     cohort transaction variance, NOT DP composition. The original\n")
cat("     manuscript's 1/sqrt(rho*k) scaling under Yeom-style membership\n")
cat("     inference was a category error.\n")
cat("\n")
cat("  2. The amount-disclosure bound is k-independent. Standard Gaussian\n")
cat("     DP at eps=1.0 / P=12 gives tanh(eps_P/2) ~= 0.95, dominating\n")
cat("     beta_amount=0.10. Meaningful per-record amount privacy under\n")
cat("     this budget is feasible only for very weak adversaries\n")
cat("     (alpha_a + tanh(eps_P/2) + delta < beta_amount).\n")
cat("\n")
cat("  3. The two bounds quantify different threats. The mechanism\n")
cat("     satisfies the application-layer privacy goal iff BOTH bounds\n")
cat("     are met under the deployer's auxiliary-info assumptions.\n")
cat("\n")
cat("================================================================\n")
