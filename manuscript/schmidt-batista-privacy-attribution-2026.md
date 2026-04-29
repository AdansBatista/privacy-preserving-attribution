---
title: "Privacy-Preserving Attribution in Protocol-Level Taxation: A Formal Treatment of the Aggregation-Leakage Tradeoff"
author: "Adans Schmidt Batista`\\thanks{Independent Researcher. Email: \\texttt{adansschmidtbatista@gmail.com}. This is a preprint; co-author and external cryptographer review for venue submission is in progress. Specific follow-on items for the camera-ready version are listed in \\S8.5.}`{=latex}"
date: "April 2026"
abstract: |
  A protocol-level transaction tax faces a structural privacy tradeoff: jurisdictional attribution requires releasing aggregates from which an adversary with auxiliary information may attempt to learn properties of the underlying transactions. This paper formalizes the tradeoff and proves two mechanism-level theorems. **Theorem 1** establishes that the composition of Pedersen commitments with zero-knowledge validity proofs preserves individual-transaction hiding under standard cryptographic assumptions, with no distributional requirement on transaction amounts. **Theorem 2** separates two cohort-aggregation threats that prior analyses have conflated and bounds each. *Theorem 2a (event detection)*: against an adversary attempting to detect that an anomalous transaction of magnitude $\tau$ occurred in a cohort of size $k$, the optimal likelihood-ratio-test advantage is bounded by $\alpha_e + 2\Phi\!\big(\tau / (2\sqrt{k\sigma_T^2 + \sigma_{\mathrm{DP}}^2})\big) - 1$, where $\alpha_e$ is the total-variation richness of an auxiliary channel about anomaly occurrence, $\sigma_T$ is the standard deviation of legitimate transactions, and $\sigma_{\mathrm{DP}}$ is the Gaussian-DP noise scale; the $1/\sqrt{k}$ scaling that emerges in the natural-variance-dominated regime is a cohort-variance phenomenon, not a property of differential-privacy composition. *Theorem 2b (amount disclosure)*: against an adversary attempting per-record amount inference, the bound is $\min(\alpha_a + \tanh(\varepsilon_P/2) + \delta_{\mathrm{total}},\, 1)$, $k$-independent, derived under a single named composition framework — zero-concentrated differential privacy [@bun2016concentrated] — with auxiliary information composed via the standard total-variation chain rule. A Kifer-Machanavajjhala-style corollary shows that whenever $\alpha_a + \tanh(\varepsilon_P/2) \geq \beta$, no finite cohort size achieves amount-disclosure target $\beta$; this is an honest negative result for standard Gaussian-DP at typical annual budgets. Closed-form $k^*$ thresholds for Theorem 2a are derived; sensitivity tables across $(\alpha, \beta, \sigma_T, \varepsilon)$ and Monte Carlo confirmation of the closed form are reproduced from a single audit-traceable R script. A worst-case-realistic side-channel — correlated timing plus auxiliary-dataset joining — is evaluated against Theorem 2a explicitly. The paper is a tradeoff measurement, not a policy endorsement; its main contribution is the explicit separation of the event-detection and amount-disclosure threats into independently provable bounds, the empirically-anchored auxiliary-information discipline under which each bound is calibrated, and the parameter regime in which each is meaningful, with the regime in which a privacy claim is unsupported named explicitly.


  **ACM CCS concepts:** Security and privacy → Cryptography → Cryptographic primitives → Zero-knowledge proofs; Security and privacy → Database and storage security → Data anonymization and sanitization; Security and privacy → Formal methods and theory of security → Formal security models.


  **Keywords:** differential privacy, zero-knowledge proofs, commitment schemes, privacy-preserving aggregation, protocol-layer taxation, jurisdictional attribution, composition theorems, auxiliary-information attacks, side channels.
bibliography: "../references.bib"
link-citations: true
---

# 1. Introduction

Jurisdictional tax attribution requires knowing where a transaction occurred — or at least knowing enough about the transaction that a jurisdictional aggregate can be computed and defensibly allocated. Individual transactions, however, carry sensitive information that attribution cannot safely reveal: a payment for medical treatment implies a medical condition, a donation implies an affiliation, a retail transaction at a particular merchant at a particular time implies presence at a particular location. The design space is not, however, the binary choice between a legible ledger and an unattributable one. Jurisdictional attribution does not require revealing *individual* transactions; it requires revealing *aggregates*. The machinery for releasing useful aggregates while bounding per-record disclosure — differential privacy, zero-knowledge proofs, commitment schemes, secure aggregation — is mature, and pieces of it are deployed in production. What has not been done, and what this paper undertakes, is a formal treatment of the *composition* of these primitives for protocol-level transaction taxation, under an adversary model with explicit auxiliary information.

**Positioning against the payment-privacy literature.** Full-stack payment-privacy systems (Zcash [@sasson2014zerocash], Monero) target per-transaction unlinkability and amount-confidentiality and have an empirical deanonymization record [@moser2018empirical; @kappos2018zcash; @biryukov2014deanonymisation; @biryukov2019privacy] driven by implementation flaws, usage-pattern leakage, and network-layer correlation alongside auxiliary-information attacks. This paper differs in *target* (jurisdictional aggregate inference-resistance, not per-transaction unlinkability — the aggregate is meant to be revealed), in *threat-model precision* (an explicit three-tier auxiliary-information model used consistently across [§3](#sec-3), [§5](#sec-5), and [§7](#sec-7)), and in *scope* (application-layer composition only; network-layer and usage-pattern surfaces remain open and are flagged where they intersect the bound, [§4.1](#sec-4-1), [§6](#sec-6)). The paper does not claim to have fixed the per-transaction problems prior systems failed to fix; it formalizes a *different* problem — application-layer aggregate attribution under an auxiliary-information-aware adversary — and gives the parameter regime in which it is tractable.

**Contributions.** Three, with the dual-bound split as the central conceptual move.

1. **Cohort-aggregation analysis decomposed into two distinct privacy threats with independently provable bounds — the paper's primary contribution.** Prior cohort-DP analyses for aggregate-release mechanisms have generally tracked a single posterior-advantage bound that conflates two threats with different scaling laws. We separate them. *Event detection* — does an anomalous transaction occur in the cohort? — is bounded by a Gaussian-LRT advantage whose $1/\sqrt{k}$ scaling emerges from the *natural variance of the legitimate cohort transactions*, not from differential-privacy composition (Theorem 2a, [§5.3](#sec-5-3)). The cohort-size dependence in this regime is therefore a property of the transaction distribution, not the privacy mechanism — an observation that prior $1/\sqrt{k}$-scaling claims (often attributed to membership-inference bounds against ML models) have not made cleanly in the aggregate-release setting. *Amount disclosure* — what amount did a target transaction have? — is bounded by the standard hypothesis-testing characterisation of $(\varepsilon, \delta)$-DP composed with auxiliary information via the total-variation chain rule, $k$-independent, with the composition framework named once and used throughout (Theorem 2b, [§5.3](#sec-5-3)). The two bounds compose with cohort size, with auxiliary information, and with composition over time in materially different ways; conflating them under a single bound obscures the fact that a deployer's design choices (cohort size, DP budget, auxiliary-information assumptions) trade against the two threats asymmetrically.

2. **Empirically-anchored three-tier auxiliary-information discipline.** Each bound is reported under a three-tier model: parametric (theorem-level), empirical (Tier 2, illustratively anchored to four-metadata-point joint distributions in the style of @demontjoye2015unique), and worst-case-realistic (Tier 3, including the side-channel inflation of [§6.4](#sec-6-4)). Each section names its tier; the headline reports the regime under which each threat is feasible or infeasible. The empirical anchoring is illustrative rather than operationally calibrated — a deployer using these results must substitute their own auxiliary-information estimates from the relevant joint distributions.

3. **Honest negative results, stated as one-line algebraic consequences (not new impossibility theorems).** Kifer-Machanavajjhala-style corollaries [@kifer2011nofreelunch] (Corollaries 2a / 2b, [§5.4](#sec-5-4)) show that whenever the auxiliary-information richness alone meets or exceeds the deployer's operational target, no cohort size and no per-period DP budget alone delivers meaningful indistinguishability against the corresponding threat. At standard annual DP budgets ($\varepsilon = 1.0$ per period, $P = 12$ monthly compositions), the amount-disclosure regime is empirically infeasible against any auxiliary information — so per-record amount privacy in this setting must come from supplementary mechanisms (minimum aggregation, temporal smoothing, additional encryption layers) rather than from differential-privacy noise alone. The paper states this explicitly rather than absorbing the gap into a free composition constant or an unstated assumption.

**Structure.** [§2](#sec-2) maps the engaged literatures. [§3](#sec-3) states the threat model. [§4](#sec-4) specifies the protocol syntactically. [§5](#sec-5) is the technical core: formal definitions, Theorem 1 (cryptographic-layer hiding), Theorem 2a (event detection), Theorem 2b (amount disclosure), Corollary 2 (infeasibility regime), and quantitative estimates. [§6](#sec-6) catalogues side channels and evaluates the worst-case-realistic combined attack. [§7](#sec-7) reports the attack-simulation results. [§8](#sec-8) draws design implications. [§9](#sec-9) concludes. Appendix A contains full proofs; Appendix B contains replication instructions.

The paper is a measurement of a tradeoff, not an endorsement of any particular deployment. A reader who concludes that the feasibility regime is too narrow to justify deployment is entitled to that conclusion; the paper's job is to draw the regime precisely.

---









# 2. Related work {#sec-2}

This paper sits in the intersection of differential privacy, zero-knowledge proofs, privacy-preserving aggregation, and digital tax attribution.

**Foundational DP and reconstruction-from-aggregates.** The differential-privacy framework originates with @dwork2006calibrating, with the canonical algorithmic-foundations treatment in @dwork2014algorithmic. Reconstruction attacks against aggregate releases — establishing that releasing too many noisy aggregates can recover the underlying database — were established by @dinur2003revealing, and the impossibility of arbitrary indistinguishability under rich auxiliary information by @kifer2011nofreelunch and @kifer2014pufferfish. These results bound what any aggregate-release mechanism can deliver and motivate the dual-bound separation pursued here.

**DP composition frameworks.** Composition theorems include basic / advanced composition [@dwork2014algorithmic; @kairouz2017composition], adaptive composition [@rogers2016adaptive], the moments accountant [@abadi2016deep], concentrated DP [@dwork2016concentrated], zero-concentrated DP [@bun2016concentrated], Rényi DP [@mironov2017renyi], and the f-DP / Gaussian-DP framework [@dong2022gaussian]. We use zCDP throughout for its tight Gaussian-mechanism characterisation and linear composition; @balle2018improving's analytic Gaussian mechanism would be a Pareto-improvement on noise calibration in the regime where deployment $\delta$ is loose, and could be substituted with no impact on the dual-bound separation. Other Gaussian-mechanism analyses — including the analytic calibration of @balle2018improving and the f-DP framework of @dong2022gaussian — would yield Pareto-comparable bounds in the deployment regime.

**Secure aggregation and privacy-preserving sums.** Cryptographic protocols for computing aggregates without revealing individual contributions include @shi2011privacy on time-series aggregation, @bonawitz2017secureagg on secure aggregation in federated settings, and the broader secure-multiparty-computation lineage. These mechanisms are orthogonal to but composable with the application-layer dual bound this paper analyses; a deployer combining secure aggregation with the Theorem 2a/2b stack would carry the secure-aggregation guarantees through Theorem 1's cryptographic absorption.

**Auxiliary-information attacks on released aggregates.** The empirical record on auxiliary-information de-identification is deep: @sweeney2002k (ZIP–DOB–sex re-identification), @ohm2010broken (the broken-anonymisation argument), @narayanan2008robust (high-dimensional re-identification), and @demontjoye2015unique (four-metadata-point spatiotemporal uniqueness in credit-card data) are the canonical empirical anchors. Our Tier 2 / Tier 3 calibrations draw illustratively on @demontjoye2015unique.

**Privacy-preserving cryptocurrencies and payment systems.** The empirical attack record on Zcash, Monero, and earlier systems [@sasson2014zerocash; @moser2018empirical; @kappos2018zcash; @biryukov2014deanonymisation; @biryukov2019privacy; @meiklejohn2013fistful; @bonneau2015sok] establishes that auxiliary-information modelling has been the implicit gap in many prior privacy claims. Our paper differs in *target* (aggregate jurisdictional inference, not per-transaction unlinkability), in *threat-model precision* (explicit dual auxiliary-information channels), and in *scope* (application layer only).

**Cryptographic primitives.** Pedersen commitments [@pedersen1991noninteractive] and zero-knowledge proof systems [@goldwasser1989knowledge; @groth2016size; @gabizon2019plonk; @bunz2018bulletproofs; @bensasson2018scalable] supply the cryptographic primitives the cohort layer composes with.

**Information-theoretic foundations.** The total-variation chain rule used in Lemma 1 follows the variational treatment in @polyanskiy2025information; the Berry-Esseen CLT correction for Theorem 2a's Gaussian-aggregate model is the standard form (e.g., @polyanskiy2025information Ch. 4).

**Tax attribution in digital regimes.** The paper's application setting — protocol-level taxation with jurisdictional attribution — is mostly motivated from cryptographic-mechanism considerations rather than from the public-finance literature, which is engaged in the deployment-discussion sections only. A deployer interested in the policy ecosystem should consult the tax-administration literature directly; the cryptographic claims of this paper are independent of it.

# 3. Threat model {#sec-3}

The threat model is the gate. A privacy paper without a precise threat model fails review; a paper whose threat model slips across sections fails in a different way — the theorem uses a favorable adversary, the simulation uses a different one, the headline claim invokes whichever is convenient. To forestall that failure mode, [§3](#sec-3) makes four threat-model commitments before the model itself is stated. Each commitment is carried through [§5](#sec-5) (the theorems) and [§7](#sec-7) (the simulation) without slippage.

## 3.1 Threat-model commitments {#sec-3-1}

The paper commits to four model choices before stating any theorem; each is carried through [§5](#sec-5) (theorems) and [§7](#sec-7) (simulation) without slippage.

**(1) Privacy notions, partitioned by threat.** The paper uses three privacy notions, each anchored to a specific threat:

- *Individual-transaction hiding* — computational indistinguishability of two transactions of equal public structure, in the sense of @goldreich2001foundations and @goldwasser1984probabilistic. Targeted by Theorem 1 ([§5.2](#sec-5-2)) and Definition 4 ([§5.1](#sec-5-1)).
- *Event-detection resistance at the cohort layer* — bounded LRT advantage on whether an anomalous transaction occurred in the cohort, given the noisy aggregate and an auxiliary-information channel. Targeted by Theorem 2a ([§5.3](#sec-5-3)) and Definition 2a ([§5.1](#sec-5-1)).
- *Amount-disclosure resistance at the cohort layer* — bounded posterior advantage on a target transaction's amount, given the noisy aggregate and an auxiliary-information channel. Targeted by Theorem 2b ([§5.3](#sec-5-3)) and Definition 2b ([§5.1](#sec-5-1)).

The three are not interchangeable, and the paper deliberately decomposes the cohort-layer threat into event detection and amount disclosure because they obey different scaling laws. Pfitzmann-Hansen terminology [@pfitzmann2010terminology] is used where it clarifies distinctions (unlinkability vs. undetectability vs. unobservability).

**(2) Computational bound.** Probabilistic polynomial-time (PPT) by default, with security parameter $\lambda$ explicit. Quantum adversaries are out of scope as a load-bearing target. Shor's algorithm [@shor1997quantum] breaks the discrete-logarithm assumption in the Pedersen group, which destroys *Pedersen binding* (the only Pedersen property that depends on DL hardness) and the soundness of any DL-based zero-knowledge proof system. Pedersen *hiding* is information-theoretic and survives a quantum adversary; what does not survive is the protocol's non-equivocation property and any range-proof or attestation soundness that rests on DL or pairing assumptions. Post-quantum hardening would therefore require replacing the binding-side primitives (and the discrete-log-based proof systems) and re-running the composition analysis. We do not claim post-quantum resistance for the present instantiation.

**(3) Composition framework.** A single named accountant: zero-concentrated differential privacy (zCDP) [@bun2016concentrated], chosen because it gives a tight characterisation of the Gaussian mechanism's intrinsic privacy budget at the zCDP level and composes linearly across periods with no auxiliary $\delta'$ tuning. The conversion to $(\varepsilon_P, \delta_P)$-DP carries the standard zCDP $\to$ DP conversion slack of @bun2016concentrated Prop 1.3, which is the operationally relevant bound used in Theorem 2b. Every $(\varepsilon, \delta)$ claim in [§5.3](#sec-5-3) and [§5.5](#sec-5-5) traces to three results of @bun2016concentrated: Proposition 1.6 ($\rho_p$-zCDP for the Gaussian mechanism with $\rho_p = \Delta^2/(2\sigma^2)$), Lemma 2.3 (linear composition $\rho_{\mathrm{total}} = P \cdot \rho_p$), and Proposition 1.3 (conversion $\varepsilon_P(\delta_P) = \rho_{\mathrm{total}} + 2\sqrt{\rho_{\mathrm{total}}\log(1/\delta_P)}$). An independent Rényi-DP cross-check [@mironov2017renyi] is reported in [Appendix A.3](#app-a-3); for tighter Gaussian-mechanism analyses, the analytic Gaussian mechanism of @balle2018improving and the f-DP / Gaussian-DP framework of @dong2022gaussian are alternatives, with Pareto-comparable noise calibration in the deployment regime considered here. Other composition frameworks ([@rogers2016adaptive; @abadi2016deep; @kairouz2017composition; @dwork2016concentrated]) are referenced only as context.

**(4) Auxiliary-information model.** Two distinct TV-richness parameters, one per cohort-layer threat, each in a three-tier discipline:

- $\alpha_e$ — TV-richness of the adversary's auxiliary channel about the *event indicator* (did a target anomalous transaction occur in the cohort?). For binary target $X_e \in \{0, 1\}$ with uniform prior, $\alpha_e := d_{\mathrm{TV}}(P_{A \mid X_e = 0},\, P_{A \mid X_e = 1}) \in [0, 1]$.
- $\alpha_a$ — TV-richness of the adversary's auxiliary channel about the *amount* of a target transaction (which of two candidate amounts in $[0, \tau]$). For binary target $X_a \in \{a_0, a_1\}$ with $|a_0 - a_1| \leq \tau$ and uniform prior, $\alpha_a := d_{\mathrm{TV}}(P_{A \mid X_a = a_0},\, P_{A \mid X_a = a_1}) \in [0, 1]$.

The two channels can have different empirical sources: $\alpha_e$ is naturally calibrated by spatiotemporal-uniqueness data (e.g., four-metadata-point joint distributions over time/location/merchant in the style of @demontjoye2015unique); $\alpha_a$ is naturally calibrated by amount-side data (income or spending-pattern microdata). They are not assumed independent, but they are not assumed coupled either — a deployer's auxiliary-information assumptions about the two channels are stated separately.

The three tiers, applied to *both* parameters:

- **Tier 1 (parametric, theorems).** $\alpha_{e}, \alpha_{a} \in [0, 1]$ as free parameters. $\alpha = 0$ recovers the no-auxiliary-information case; $\alpha = 1$ is the degenerate channel that determines the target.
- **Tier 2 (illustrative empirical anchor).** $\alpha$ derived from a stated empirical joint distribution. The Tier-2 anchor we use for $\alpha_e$ is the @demontjoye2015unique four-metadata-point spatiotemporal-uniqueness rate of approximately 0.95 over typical sample sizes, giving $\alpha_e \approx 0.94$ in the binary inference game. *This is an illustrative anchor, not an operational calibration.* The de Montjoye result establishes uniqueness of spatiotemporal patterns; the translation to a TV-richness bound on the binary event-channel inference game requires assumptions about the deployer's specific auxiliary-data sources that this paper does not derive in full. A deployer using this paper's bounds must compute $\alpha_e$ from their own auxiliary-data joint distribution. Tier-2 calibration for $\alpha_a$ depends on the deployer's amount-side aux source; we report a parametric sweep rather than commit to a single value.
- **Tier 3 (worst-case-realistic, headline; illustrative not measured).** Tier 2 plus the side-channel inflation modelled in [§6.4](#sec-6-4) under a Gaussian-jitter timing model (correlated timing plus auxiliary-dataset joining). The headline feasibility / infeasibility statements are reported with the Tier-3 inflation applied; the inflation derivation in [Appendix A.4](#app-a-4) is model-based rather than measured against transaction-rail microdata, and the wide CI on the inflation reflects this. As with Tier 2, a deployer must substitute their own observed timing distribution to operationalise the Tier-3 estimate.

Each section names which tier is operating. The three-tier discipline is the paper's structural defense against "auxiliary-information opportunism" — the failure mode where a theorem uses a favourable $\alpha$ and a headline cites a different one. We do not claim the Tier-2 / Tier-3 numbers are operationally tight; we claim the discipline of separating them is what reviewers and deployers should adopt.

### 3.1.1 Notation summary {#sec-3-1-1}

The paper carries several closely-named privacy parameters; this table consolidates them.

| Symbol | Role | Where introduced |
|---|---|---|
| $\varepsilon, \delta$ | Per-period DP budget for the Gaussian mechanism | (B2), [§4.3](#sec-4-3) |
| $P$ | Number of release periods composing the annual budget | (B6), [§5.3](#sec-5-3) |
| $\rho_p, \rho_{\mathrm{total}}$ | Per-period and total zCDP parameters (Bun-Steinke 2016) | [§5.3](#sec-5-3) |
| $\varepsilon_P, \delta_P$ | Composed annual $(\varepsilon, \delta)$-DP after zCDP $\to$ DP conversion | [§5.3](#sec-5-3) |
| $\delta_{\mathrm{total}}$ | $\delta_P$ plus cryptographic-layer failure $\mathit{negl}(\lambda) \leq 2^{-100}$ | (B4), [§5.3](#sec-5-3) Step 5 |
| $\delta_{\mathrm{clip}}$ | Clipping-tail leakage from heavy-tailed amounts; *separate* from $\delta_{\mathrm{total}}$ | [§5.3](#sec-5-3) distributional remark |
| $\tau$ | Amount-clip threshold; bounded sensitivity of the Gaussian mechanism | (B1) |
| $\sigma_{\mathrm{DP}}$ | Gaussian DP noise std-dev: $\tau\sqrt{2\ln(1.25/\delta)}/\varepsilon$ | (B2) |
| $\sigma_T$ | Std-dev of legitimate cohort transaction amounts | (B3) |
| $\gamma_3$ | Third absolute central moment of $T_i$; controls Berry-Esseen CLT correction | (B3) |
| $\alpha_e$ | TV-richness of auxiliary channel about the *event indicator* $X_e$ | (B5e), Definition 2a |
| $\alpha_a$ | TV-richness of auxiliary channel about a *target amount* $X_a$ | (B5a), Definition 2b |
| $\beta_e, \beta_a$ | Deployer-chosen operational thresholds for event detection / amount disclosure | Definitions 2a, 2b |
| $\varepsilon_{\mathrm{CLT}}(k)$ | Berry-Esseen CLT correction in Theorem 2a (zero under exact Gaussian aggregate) | (B3$^{\mathrm{G}}$), [§5.3](#sec-5-3) |
| (CI) | Conditional-independence assumption needed for Lemma 1 | Lemma 1 statement |

The two auxiliary channels ($\alpha_e$, $\alpha_a$) are *separately calibrated* — they may have different empirical sources, and a deployer may face a Tier-1 $\alpha_a$ alongside a Tier-3 $\alpha_e$ or vice versa. The two failure-probability terms ($\delta_{\mathrm{total}}$, $\delta_{\mathrm{clip}}$) are *separately tracked* — $\delta_{\mathrm{total}}$ governs DP-mechanism slack and cryptographic-layer negligible terms; $\delta_{\mathrm{clip}}$ governs the heavy-tailed-amount tail risk. Theorem 2 statements reference $\delta_{\mathrm{total}}$ alone; clipping leakage is discussed separately in [§5.3](#sec-5-3)'s distributional-assumptions remark.

## 3.2 Adversary types

With the commitments in place, four adversary types.

*Honest-but-curious tax authority.* Follows the protocol exactly; wants to infer more than the protocol's aggregate output discloses. Has access to the aggregate output, the protocol's parameters, and any auxiliary information admissible under [§3.1](#sec-3-1)(4). Does not deviate from protocol. This is the weakest adversary and the one against which Theorem 2's cleanest bound is stated.

*Malicious platform operator.* Colludes with an adversarially-chosen subset of users (bounded fraction of the transaction population, but the bound is a parameter of the threat model and stated explicitly where invoked). Can inject transactions, selectively route transactions, or delay transactions; can observe the transaction-stream metadata at the rail layer. Cannot forge cryptographic attestations or produce invalid zero-knowledge proofs. The paper's [§5.4](#sec-5-4) discusses how Theorem 2 degrades under the malicious-platform variant.

*Inference attacker with auxiliary data.* Uses public datasets (voter rolls, census, social-media geotag scrapes, public court filings) joined with protocol outputs to produce inferences the protocol did not intend to release. This is the Tier 2 adversary, instantiated via the de Montjoye-style auxiliary model. The most technically consequential adversary for the paper's feasibility claim.

*Nation-state adversary.* Full network observation over the in-scope payment rail; ability to compromise a bounded fraction of nodes; selective legal compulsion of rail operators; ability to correlate observations across multiple jurisdictions. This adversary is *in scope* but marked as the hardest case; the paper notes where Theorem 2's bound degrades under nation-state capabilities and states the result honestly. A reader who finds the nation-state case inadequately addressed is not wrong, and [§9](#sec-9)'s cut-if-scope-creeps option 2 anticipates that limitation.

## 3.3 Adversary goals {#sec-3-3}

Four goals, each linked to a privacy notion from [§3.1](#sec-3-1)(1):

- *Deanonymization.* Link a pseudonym used on the protocol to a real-world identity. Targeted by the computational-indistinguishability property at the individual-transaction layer (Theorem 1) and by the posterior-advantage bound at the aggregate layer (Theorem 2).
- *Transaction linkage.* Link multiple transactions to the same real-world actor, even if no real-world identity is recovered. The pseudonymity-but-not-anonymity failure mode documented by @meiklejohn2013fistful. Targeted by individual-transaction hiding (Theorem 1) at the per-transaction layer; longitudinal-attack composition ([§5.3](#sec-5-3), [§7](#sec-7)) bounds the linkage advantage over multi-period observation.
- *Jurisdictional inference beyond declared attribution.* Infer finer-grained jurisdictional location than the attribution mechanism requires. A tax mechanism that attributes at the county level should not inadvertently leak ZIP-code-level location; the paper's cohort construction ([§4](#sec-4)) sets the jurisdictional granularity deliberately, and Theorem 2's posterior-advantage bound is stated at the declared granularity.
- *Amount inference.* Infer individual transaction amounts from aggregate leakage. Targeted by Pedersen hiding (Theorem 1 at the individual layer); the aggregate layer's DP mechanism bounds amount-inference via the bounded-sensitivity framework ([§5.3](#sec-5-3)), which requires amount clipping and reports the clipping loss as a robustness quantity.

## 3.4 Access patterns and resource assumptions

The adversary observes the protocol's *public* outputs: published jurisdictional aggregates at each period, the noise scale (public by design, per [§4](#sec-4)), the cohort-size parameters, and any public metadata attached to the aggregates. The adversary does *not* observe: the commitment openings (per Pedersen hiding); the zero-knowledge proof witnesses (per zero-knowledge, under the setup assumptions stated in Theorem 1); the individual DP noise samples (which are discarded after aggregate computation); or the per-transaction jurisdictional metadata below the cohort-level aggregation threshold. The adversary has PPT compute and any auxiliary information admissible under [§3.1](#sec-3-1)(4). The adversary cannot run Shor's algorithm; quantum-adversary resistance is out of scope per [§3.1](#sec-3-1)(2).

## 3.5 Out of scope

The following are not targets of the paper's security analysis. A real-world deployment that depended on any of them without additional machinery would fail *outside* the scope of Theorems 1–2 and the existence-form negative statement of [§5.4](#sec-5-4).

- *Physical device compromise* — a compromised endpoint device leaks its own private state regardless of protocol properties.
- *User-endpoint attacks* — phishing, malware, key-exfiltration at the user's device. The protocol presumes honest generation of commitments and proofs at the user endpoint.
- *Regulatory compulsion* — legal orders compelling disclosure of cryptographic keys or protocol state. This is a governance-layer concern, not a cryptographic one, and is addressed (if at all) by protocol-layer commitments that the rail operator does not hold the decryption keys required to respond to such an order.
- *Post-quantum adversaries* — noted in [§3.1](#sec-3-1)(2), flagged as a hardening target in [§8](#sec-8), not treated at depth in this paper.
- *Denial-of-service and availability attacks* — this is a privacy paper, not an availability paper; a DoS-capable adversary does not gain privacy advantage from mounting a DoS attack, only liveness disruption.

---

# 4. Protocol model {#sec-4}

[§4](#sec-4) specifies what the protocol *looks like*. [§5](#sec-5) specifies what security it *claims*. Keeping the syntax of the mechanism ([§4](#sec-4)) cleanly separated from its semantics and proofs ([§5](#sec-5)) is the precondition for the [§5](#sec-5) composition analysis that cryptography venues expect. [§4](#sec-4) is deliberately compressed; the formal definitions have been moved to [§5.1](#sec-5-1).

## 4.1 Layer specification {#sec-4-1}

A blockchain or payments engineer reading this paper will want to know, in their own vocabulary, where the proposed mechanism lives in the stack. We commit explicitly.

- *Application layer.* The mechanism is a rule imposed on transaction-level messages exchanged between users on an in-scope payment rail. The rail is any system — regulated bank network, card network, ACH, instant-payment rail, stablecoin-issuer network, CBDC, permissionless cryptocurrency under the relevant regulatory threshold — that carries messages of the transaction schema specified below.

- *Consensus-layer integrity (assumed).* The mechanism assumes transactions, once committed to the rail's ledger, are final and non-reorderable beyond the finality depth assumed by Theorem 1. The mechanism is *not* a consensus-layer construction; it does not propose a new consensus algorithm, and its security does not rest on a consensus property stronger than the underlying rail provides.

- *Network-layer confidentiality (not assumed).* The mechanism makes no assumption about network-layer confidentiality. Traffic-analysis resistance — packet-timing patterns, connection-level metadata, IP-layer routing — is the primary source of side-channel leakage analyzed in [§6](#sec-6). A deployment that additionally routes transactions through a network-layer anonymity system (Tor, a mixnet) would reduce [§6](#sec-6)'s side-channel surface at stated cost; without such a layer, the side-channel leakage stands.

Three things the mechanism is *not*. It is not a novel consensus construction (no L1 fork). It is not a novel network-layer privacy construction (no mixnet variant). It is not a novel cryptographic primitive (no new ZK proof system or commitment scheme). These positioning statements forestall the referee question "why is this not just ⟨alternative the paper did not invoke⟩?" — it is not that because it is a composition analysis at the application layer, which is a different contribution from a primitive or a consensus design.

## 4.2 Inputs and outputs {#sec-4-2}

**Inputs.** A transaction *t* on the in-scope rail is a tuple:

$$ t = (\mathit{sender}, \mathit{receiver}, C_{\mathit{amount}}, j, \pi_t, \mathit{ts}) $$

where *sender* and *receiver* are pseudonymous identifiers (public keys on the rail); $C_{\mathit{amount}}$ is a Pedersen commitment to the transaction amount; *j* is the jurisdictional metadata at the attribution granularity specified by the tax authority (e.g., county-level); $\pi_t$ is a zero-knowledge proof that the commitment opens to a valid (non-negative, within the declared range) amount and that the *j* field is consistent with the sender's publicly attested jurisdictional claim; and *ts* is the rail-issued timestamp. Individual transactions are published on the rail in this form.

**Outputs.** For each period *p* and each jurisdiction *j*, the protocol publishes:

$$ \mathit{AGG}_{p,j} = \left(\sum_{t \in T_{p,j}} \mathit{amount}(t)\right) + \eta_{p,j} $$

where $T_{p,j}$ is the set of in-scope transactions in period *p* with jurisdictional metadata *j*; the sum is computed over the cleartext amounts (via a cryptographic opening of the sum of commitments — see §4.3); and $\eta_{p,j}$ is differential-privacy noise (Gaussian or Laplace, per [§4.3](#sec-4-3)). The count $|T_{p,j}|$ is also published with its own DP noise term.

The aggregate $\mathit{AGG}_{p,j}$ is the quantity the tax authority uses to allocate jurisdictional revenue. No other per-transaction information is released.

## 4.3 Cryptographic primitives and DP noise generation {#sec-4-3}

**Stacked primitives.**

1. *Pedersen commitments* [@pedersen1991noninteractive] for amount hiding. Perfectly hiding, and computationally binding under the discrete-logarithm assumption for the underlying group with generators chosen so that their discrete-log relation is unknown.
2. *Zero-knowledge proofs* (Groth16 [@groth2016size], PLONK [@gabizon2019plonk], Bulletproofs [@bunz2018bulletproofs], or STARKs [@bensasson2018scalable]) for validity: the committed amount is non-negative and within the declared range; the jurisdictional metadata *j* is consistent with the sender's public attestation.
3. *Jurisdictional-cohort aggregation*: the protocol sums commitments at the cohort level (period × jurisdiction) before revealing; only the aggregate is opened, not the individual commitments.
4. *Differential-privacy noise* on the opened aggregate.

**DP noise-generation requirements (explicit; load-bearing for whether Theorem 2 survives deployment).** Four specifics, without which Theorem 2 does not apply and the paper must say so.

- *Noise distribution.* Gaussian mechanism only — composition is accounted via zCDP [@bun2016concentrated] (the single named accountant of [§5.3](#sec-5-3)(B3)). The protocol does not switch composition frameworks; alternative accountants (moments accountant, advanced composition) are referenced only for cross-checks (Appendix A.3) and never for the headline numbers.
- *Noise scale.* Derived from the (ε, δ) budget and the sensitivity Δ of the aggregate query, which is set by the amount-clipping threshold τ ([§5.3](#sec-5-3)). Noise scale is public.
- *Source of randomness.* **Publicly verifiable randomness (PVR)** — a verifiable delay function (VDF, following @boneh2018vdf) or a distributed randomness beacon (e.g., the @cascudo2017scrape SCRAPE construction) that commits to a random value *before* the aggregation is performed. **Local PRNG on the aggregator's machine is disallowed.** Local-PRNG noise is fingerprintable by a well-resourced adversary, compromised-aggregator-exploitable, and a known deployment failure mode of DP systems; a mechanism that uses local PRNG is outside Theorem 2's scope.
- *Noise-sample handling.* Noise is added once per aggregate query per period, not once per transaction. The noise value itself is never revealed. The composition accounting ([§5.3](#sec-5-3)) treats each aggregate-release as one DP query against the continuous-observation budget.

*PVR maturity and auditability.* Two honest caveats on the randomness requirement. First, VDF and distributed-randomness-beacon constructions are themselves an area of active cryptographic research; specific instantiations have known security-parameter and liveness tradeoffs (VDFs depend on sequentiality assumptions that are not yet as well-studied as the assumptions underlying standard public-key cryptography; SCRAPE-style beacons depend on honest-majority of the beacon committee). A deployment may need to wait for a specific PVR instantiation to reach production maturity, or accept a stated trust assumption on the beacon committee's honesty. The paper's theorems are stated under the abstraction that *some* PVR with stated properties is available; instantiation is a deployment engineering decision the paper does not resolve. Second, auditability of PVR use is not automatic: the requirement that the aggregator used PVR rather than local PRNG needs to be verifiable after the fact. The construction we presume is that the aggregator publishes (a) the PVR commitment reference (e.g., the VDF output or the beacon round identifier) alongside the aggregate, and (b) a zero-knowledge proof that the published noise value was drawn from the DP distribution seeded by the PVR output. An auditor checks the PVR reference is from the expected source and verifies the ZK proof; a deployment that fails to publish these artifacts cannot be audited and should not be trusted to satisfy the Theorem 2 precondition.

If any of these deployment constraints is relaxed in a deployed instantiation, the paper's theorems do not apply to that instantiation. [§8](#sec-8) lists this as a deployment-discipline requirement, not an optional recommendation.

## 4.4 What the protocol does not do {#sec-4-4}

The protocol does not hide the *existence* of a transaction — the rail's ledger records that transaction *t* occurred, with pseudonymous parties. It does not hide the *timing* of the transaction beyond the period-level aggregation granularity; within-period timing is visible on the rail and is the primary source of [§6](#sec-6)'s timing side-channel. It does not hide the *jurisdictional metadata j* of the transaction — the jurisdiction is the attribution key and must be visible for the cohort-aggregation to be computable. What is hidden is the *amount* (via Pedersen), the *relationship between amount and jurisdiction at the individual level* (via aggregation), and *individual inferability of the aggregate* (via DP noise). The paper is precise about what is and is not hidden; claims about hiding that go beyond this list are claims the paper does not make.

---

# 5. Composition analysis {#sec-5}

[§5](#sec-5) is the paper's technical core. The methodological modes used: (1) game-based security definitions for individual-transaction hiding (Theorem 1) and the cohort-layer threats (Definitions 2a, 2b); (2) composition theorems applied to the stacked mechanism — Pedersen + ZK + cohort aggregation + Gaussian DP — under a single named composition framework (zCDP, [@bun2016concentrated]); (3) closed-form $k^*_{\mathrm{event}}$ derivation by inversion of Theorem 2a; (4) explicit infeasibility carve-outs (Corollaries 2a, 2b).

**Scope.** [§5](#sec-5) does not introduce a new cryptographic primitive or a new proof technique. The contribution is the *dual-bound separation* itself, the closed forms it produces ($k^*_{\mathrm{event}}$ from Corollary 1, $\alpha^*_a$ from Corollary 2b), and the three-tier auxiliary-information discipline under which they are calibrated. Prior cohort-DP analyses for aggregate-release mechanisms have generally tracked a single posterior-advantage bound that conflates event detection and amount disclosure under one expression; the consequence is that the cohort-size dependence (which comes from transaction variance, not DP composition) and the auxiliary-information regime (which interacts with each threat differently) are obscured. Separating the two threats yields the closed forms a deployer can actually use and a Kifer-Machanavajjhala-style infeasibility statement that is honest about what standard Gaussian DP at deployment-realistic budgets does and does not deliver. A reader looking for a new ZK proof system or a new DP mechanism will not find one; a reader looking for the composition analysis whose absence in the cohort-DP literature this paper closes will.

## 5.1 Formal definitions {#sec-5-1}

Each definition is stated with the security parameter λ explicit. PPT denotes probabilistic polynomial-time in λ; $\mathit{negl}(\lambda)$ denotes a negligible function.

**Definition 1 (Valid attribution).** A mechanism $\mathcal{M}$ valid-attributes over a transaction set *T* to a jurisdiction set *J* if and only if, for every period *p* and every jurisdiction $j \in J$, the published aggregate $\mathit{AGG}_{p,j}$ satisfies

$$ \mathit{AGG}_{p,j} = \left(\sum_{t \in T_{p,j}} \mathit{amount}(t)\right) + \eta_{p,j} $$

with $\eta_{p,j}$ drawn from the DP mechanism's distribution at scale $\Delta / \varepsilon$ (Laplace) or $\Delta \sqrt{2 \ln(1.25/\delta)} / \varepsilon$ (Gaussian), where Δ is the clipped sensitivity ([§5.3](#sec-5-3)).

**Definition 2a (Event-detection attack game).** Let $t^*$ be a publicly named target transaction whose presence in cohort $T_{p,j}$ at magnitude $\tau$ the adversary attempts to detect. Let $A$ denote the adversary's auxiliary-information channel about the event indicator $X_e \in \{0, 1\}$ (anomaly absent / anomaly present), with TV-distance richness $\alpha_e \in [0, 1]$ as defined in [§3.1](#sec-3-1)(4). Let $\beta_e \in [0, 1]$ denote the deployer-chosen target advantage threshold for event detection.

The game: a challenger samples $b \in \{0, 1\}$ uniformly. If $b = 0$, the cohort consists of $k$ legitimate transactions sampled i.i.d. from a distribution class $\mathcal{D}$ on $[0, \tau]$ with mean $\mu_T$ and variance $\sigma_T^2$. If $b = 1$, the cohort additionally contains the target transaction $t^*$ at amount $\tau$. The challenger releases $Y = \sum_{t \in T_{p,j}} \mathrm{clip}_\tau(\mathit{amount}(t)) + \eta$, with $\eta \sim \mathcal{N}(0, \sigma_{\mathrm{DP}}^2)$ from [§4.3](#sec-4-3), together with an auxiliary observation $A$ jointly distributed with $X_e$ at richness at most $\alpha_e$. The adversary $\mathcal{B}$ outputs $b' \in \{0, 1\}$.

The mechanism $\mathcal{M}$ is $(\beta_e, \alpha_e)$-**event-private** if for all PPT adversaries $\mathcal{B}$:

$$ \mathrm{Adv}^{\mathrm{event}}_{\mathcal{B}}(\mathcal{M}; X_e, A) \;:=\; \big| \Pr[\mathcal{B}(Y, A) = 1 \mid b = 0] - \Pr[\mathcal{B}(Y, A) = 1 \mid b = 1] \big| \;\leq\; \beta_e + \mathit{negl}(\lambda). $$

**Definition 2b (Amount-disclosure attack game).** Let $t^*$ be a publicly named target transaction with unknown amount, and let $a_0, a_1 \in [0, \tau]$ be two candidate amounts with $|a_0 - a_1| \leq \tau$ (the bounded-sensitivity sensitivity, B1 below). Let $A$ denote the adversary's auxiliary-information channel about $X_a := \mathit{amount}(t^*)$ in the discriminative-pair $\{a_0, a_1\}$, with TV-distance richness $\alpha_a \in [0, 1]$ as defined in [§3.1](#sec-3-1)(4). Let $\beta_a \in [0, 1]$ denote the deployer-chosen target advantage threshold for amount disclosure.

The game: a challenger samples $b \in \{0, 1\}$ uniformly, sets $\mathit{amount}(t^*) = a_b$, draws the remaining $k - 1$ amounts from $\mathcal{D}$ on $[0, \tau]$, computes $Y = \sum_{t \in T_{p,j}} \mathrm{clip}_\tau(\mathit{amount}(t)) + \eta$, and presents $(Y, A)$ to $\mathcal{B}$. The adversary outputs $b' \in \{0, 1\}$.

The mechanism is $(\beta_a, \alpha_a)$-**amount-private** if for all $a_0, a_1 \in [0, \tau]$ with $|a_0 - a_1| \leq \tau$ and all PPT adversaries $\mathcal{B}$:

$$ \mathrm{Adv}^{\mathrm{amt}}_{\mathcal{B}}(\mathcal{M}; X_a, A, a_0, a_1) \;:=\; \big| \Pr[\mathcal{B}(Y, A) = 1 \mid b = 0] - \Pr[\mathcal{B}(Y, A) = 1 \mid b = 1] \big| \;\leq\; \beta_a + \mathit{negl}(\lambda). $$

Definition 2a and Definition 2b specify two distinct attack games. The mechanism's *application-layer* privacy goal — stated as a deployment design choice — is to satisfy both with deployer-chosen $(\beta_e, \alpha_e)$ and $(\beta_a, \alpha_a)$. Theorem 2a ([§5.3](#sec-5-3)) bounds Definition 2a's advantage, with the bound depending on cohort size $k$ via the cohort transaction variance. Theorem 2b ([§5.3](#sec-5-3)) bounds Definition 2b's advantage, with the bound *independent of $k$* and instead governed by the differential-privacy budget composed across $P$ release periods.

The standard $(\varepsilon, \delta)$-DP definition is recovered as the $\alpha_a = 0$ specialisation of Definition 2b (no auxiliary channel) with $\beta_a$ matched to the standard hypothesis-testing form $\tanh(\varepsilon/2) + \delta$. Definitions 2a and 2b are generalisations under explicit auxiliary information; they coincide with familiar DP statements at $\alpha = 0$.

**Definition 4 (Individual-transaction hiding — computational).** The hiding and admissibility properties of a transaction are stated separately, and Definition 4 is the *hiding* property; admissibility is captured by Definition 4a immediately below.

The hiding game: let $t_0 = (\mathit{sender}_0, \mathit{receiver}_0, C_{\mathit{amount}}^{(0)}, j_0, \pi^{(0)}, \mathit{ts}_0)$ and $t_1 = (\mathit{sender}_1, \mathit{receiver}_1, C_{\mathit{amount}}^{(1)}, j_1, \pi^{(1)}, \mathit{ts}_1)$ be two transactions, **each independently admissible per Definition 4a**, of equal public structure (same $\mathit{sender}, \mathit{receiver}, j, \mathit{ts}$ to fix the public metadata). The adversary $\mathcal{A}$ is given a uniformly-random challenge $t_b$ for $b \in \{0, 1\}$ and must output $b' \in \{0, 1\}$. The mechanism is *hiding* if

$$ \Big| \Pr[\mathcal{A}(t_b) = 1 \mid b = 0] - \Pr[\mathcal{A}(t_b) = 1 \mid b = 1] \Big| \;\leq\; \mathit{negl}(\lambda), $$

under the standard assumptions for the instantiated primitives: *perfect* hiding of Pedersen commitments, *computational binding* of Pedersen commitments under the discrete-logarithm-relation-unknown assumption for the chosen generators, and zero-knowledge simulatability of the proof system under its setup model from (B4).

**Definition 4a (Admissibility constraint, separate from hiding).** A transaction $t = (\mathit{sender}, \mathit{receiver}, C_{\mathit{amount}}, j, \pi, \mathit{ts})$ is *admissible* if its zero-knowledge proof $\pi$ verifies under the proof system's verifier, witnessing that the committed amount lies in the declared non-negative range $[0, A_{\max}]$ and that the jurisdictional metadata $j$ is consistent with the sender's public attestation. Admissibility is a *publicly verifiable* property of $t$, independent of the hiding game; Definition 4 conditions on both transactions in the hiding game being admissible. The two properties compose: hiding gives indistinguishability of the *committed amount* between two admissible transactions; admissibility gives a non-malleability and validity guarantee that the *committed amount is in range and the jurisdictional metadata is consistent*. Neither property implies the other.

Definitions 2a, 2b, and 4 are deliberately separated. Definition 4 is computational indistinguishability at the individual-transaction layer; Definitions 2a and 2b are posterior-advantage-bounded inference-resistance at the aggregate layer for two distinct threats. The notions are composed, not unified: Theorem 1 ([§5.2](#sec-5-2)) addresses Definition 4; Theorem 2a addresses Definition 2a; Theorem 2b addresses Definition 2b; [§5.4](#sec-5-4) states the existence-form infeasibility regime under strong auxiliary information for amount disclosure.

## 5.2 Theorem 1 — commitment + ZK hiding preservation {#sec-5-2}

The hiding property of Pedersen commitments is *information-theoretic* (perfect, no computational assumption) while the binding property is *computational* (relying on discrete-logarithm hardness). These are independent statements and we present them separately to avoid the common misstatement that conflates them. The composition theorem then combines hiding (Theorem 1a) with the proof-system zero-knowledge property (Theorem 1c) to obtain individual-transaction hiding for the full stack.

**Theorem 1a (Pedersen perfect hiding — information-theoretic, no DL assumption).** Let $\mathcal{C}$ be the Pedersen commitment scheme over an Abelian group $G$ of prime order, with generators $g, h \in G$. For any messages $m_0, m_1 \in \mathbb{Z}_{|G|}$, the distribution of commitments $\{(g^{m_b} h^r) : r \in_R \mathbb{Z}_{|G|}\}$ is *identical* for $b = 0$ and $b = 1$. Therefore no adversary — even one with unbounded computational power — can distinguish $\mathcal{C}(m_0)$ from $\mathcal{C}(m_1)$ better than random guessing. The hiding property holds *without* any computational hardness assumption on $G$; it requires only that $h$ is a uniformly-distributed group element independent of $g$ at setup time, which is what "generator setup with discrete-log relation unknown" means.

**Theorem 1b (Pedersen computational binding — DL hardness).** Let $G$ be a group in which the discrete-logarithm problem is hard for PPT adversaries. Then no PPT adversary can produce $(m_0, r_0) \neq (m_1, r_1)$ with $g^{m_0} h^{r_0} = g^{m_1} h^{r_1}$ except with probability negligible in the security parameter $\lambda$. Binding is the only property that depends on DL hardness; hiding (Theorem 1a) is independent.

**Theorem 1c (Zero-knowledge proof composition).** Let $\Pi$ be the zero-knowledge proof system instantiated for the protocol's range and jurisdictional-consistency claims, *restricted to the explicit class*

> $\Pi \in \{\text{Bulletproofs}, \text{STARK} \text{ under transparent public-coin simulation}\} \;\cup\; \{\text{Groth16}, \text{PLONK} \text{ with honest or MPC-ceremony SRS/CRS setup}\}.$

For any $\Pi$ in this class there exists a PPT simulator $\mathcal{S}$ such that $\mathcal{S}$'s output is computationally indistinguishable from honest prover transcripts under the standard simulation assumptions of the named system [@groth2016size; @gabizon2019plonk; @bunz2018bulletproofs; @bensasson2018scalable]. We do *not* claim composition for "any proof system satisfying soundness + ZK" generically; a deployment using a proof system outside this class must re-prove Theorem 1c for the new class with its specific setup model and simulation assumptions.

**Theorem 1 (Individual-transaction hiding, composed).** Under the conjunction of (i) Theorem 1a (perfect hiding of Pedersen, requiring only that the generator setup of (A1) below is honest), (ii) Theorem 1b (computational binding under DL), and (iii) Theorem 1c (ZK simulation under the chosen setup family), the composition of the Pedersen commitment and the zero-knowledge validity proof satisfies Definition 4 (hiding) *conditional on Definition 4a (admissibility)*. Specifically: for any two admissible transactions $t_0, t_1$ of equal public structure, no PPT adversary can distinguish them in the hiding game with non-negligible advantage in $\lambda$, where:

- *(A1) — Pedersen setup.* Generators $g, h \in G$ chosen so the discrete-log relation $\log_g(h)$ is unknown to all parties (e.g., via a Fiat-Shamir transformation of a publicly-verifiable random oracle, or via an MPC ceremony with toxic-waste destruction). Under (A1), Theorem 1a applies (hiding is perfect, no DL needed) and Theorem 1b applies under additional DL hardness in $G$ (binding is computational).
- *(A2) — Proof-system class.* The ZK proof system is instantiated as one of: transparent (STARK, Bulletproofs) under the public-coin simulation model, *or* SRS/CRS-based (Groth16, PLONK) with honest setup or MPC-ceremony setup. (A2) is the class restriction; Theorem 1 does not extend to proof systems outside this class without re-proving Theorem 1c for that class.
- *(A3) — Admissibility precondition.* Both transactions in the hiding game pass Definition 4a's admissibility check (range proof verifies, jurisdictional metadata is consistent). Transactions that fail admissibility are publicly rejected and never enter the hiding game.

The proof is a standard hybrid argument; full proof in [Appendix A.1](#app-a-1).

**Distributional assumptions: none for hiding; a protocol-acceptance constraint for validity.** Theorem 1's *hiding* property makes no assumption about the transaction-amount distribution. Pedersen hiding is perfect once the generators are set correctly, and no distributional assumption enters the hiding reduction. A reader who suspects a hidden distributional assumption at the hiding layer ("this works only for approximately-uniform amounts" or "this works only for bounded-entropy amounts") will not find one. Distributional considerations enter the aggregate layer (Theorem 2 and the clipped-sensitivity framework of [§5.3](#sec-5-3)), not the individual-transaction hiding layer.

A separate point worth clarifying: the range-proof component of the ZK validity proof *does* impose a protocol-acceptance constraint — the committed amount must lie in a declared range (non-negative, below a system maximum). This is not a distributional constraint on *what is hidden*; it is a constraint on *what the protocol accepts as a valid transaction*. Transactions outside the declared range are rejected at submission; accepted transactions are hidden uniformly within the range. The two statements compose: the protocol accepts a distribution-free set of in-range transactions, and hides them under assumption (A1).

*Proof sketch.* By reduction to the hiding property of Pedersen commitments and the zero-knowledge simulation property of the proof system, via a standard hybrid argument: first replace the honest proof transcript with a simulated one under (A2), then invoke the commitment hiding game under (A1). The binding property of Pedersen is not what yields hiding, but it is required for the protocol's validity and non-equivocation claims. Full proof: Appendix A.1.

**Remark on setup assumptions and composition.** A reader familiar with proof-system engineering will ask whether the simulator/setup assumptions are being smuggled in. They are not: Theorem 1 is conditioned explicitly on the setup model of the chosen proof system. For transparent systems, no trusted setup assumption is needed beyond the public-coin model of the system. For SRS-based systems, the theorem assumes an honestly generated or securely multi-party-generated SRS with the usual simulation/soundness properties. A deployment that uses a compromised setup is outside Theorem 1's scope.

**Remark on UC vs. game-based framing.** A reader familiar with @canetti2001universally will ask why we use game-based rather than UC framing. The reason: the paper's composition extends through the aggregate-DP layer, where universal-composability-preserving DP mechanisms are not standard. Stating Theorem 1 in UC would force a framing choice for Theorem 2 that we do not want to impose. The game-based framing suffices for the composition we need; a UC-framed version of Theorem 1 would be a strict refinement of the present statement and is compatible with it.

## 5.3 Theorem 2 — cohort dual-bound (event detection + amount disclosure) {#sec-5-3}

The cohort layer hosts two formally distinct privacy threats that prior analyses have conflated. Theorem 2a bounds the event-detection advantage of Definition 2a; Theorem 2b bounds the amount-disclosure advantage of Definition 2b. The two bounds compose with cohort size $k$ in *different* ways: Theorem 2a is $k$-dependent, with $1/\sqrt{k}$ scaling that emerges from the natural variance of legitimate cohort transactions; Theorem 2b is $k$-independent, with the standard hypothesis-testing characterisation of $(\varepsilon, \delta)$-DP composed with auxiliary information via the total-variation chain rule. We state and prove each separately.

### Lemma 1 — Posterior-advantage chain rule (TV form, self-contained)

**Lemma 1 (TV chain rule for joint observations under conditional independence).** Let $X \in \{0, 1\}$ have uniform prior. Let $A$ and $\mathcal{M}(d)$ be two random variables jointly distributed with $X$, satisfying the conditional-independence assumption

$$ A \perp \mathcal{M}(d) \;\big|\; X \tag{CI} $$

(i.e., conditional on $X$, the auxiliary channel $A$ is independent of the mechanism's internal randomness — equivalently, the mechanism does not consume $A$ as input). Let

$$ \alpha \;:=\; d_{\mathrm{TV}}\!\big(P_{A \mid X = 0},\, P_{A \mid X = 1}\big), \qquad \mathrm{Adv}_{\mathcal{M}}(X) \;:=\; d_{\mathrm{TV}}\!\big(P_{\mathcal{M}(d) \mid X = 0},\, P_{\mathcal{M}(d) \mid X = 1}\big). $$

Then for any (PPT or unbounded) binary distinguisher $\mathcal{B}(\mathcal{M}(d), A) \to \{0, 1\}$:

$$ \mathrm{Adv}(X \mid \mathcal{M}, A) \;:=\; \big|\Pr[\mathcal{B} = 1 \mid X=0] - \Pr[\mathcal{B} = 1 \mid X=1]\big| \;\leq\; \alpha + \mathrm{Adv}_{\mathcal{M}}(X). $$

*Proof.* The Bayes-optimal binary-distinguisher advantage between two distributions equals their TV distance, so the LHS equals $d_{\mathrm{TV}}(P_{\mathcal{M},A \mid X=0},\, P_{\mathcal{M},A \mid X=1})$. We bound this joint TV distance via the chain rule.

For any two joint laws $P_{U, V \mid X=0}$ and $P_{U, V \mid X=1}$, applying the variational characterization of TV (the supremum over events) and conditioning on the value of $V$:

$$ d_{\mathrm{TV}}\!\big(P_{U,V \mid X=0},\, P_{U,V \mid X=1}\big) \;\leq\; d_{\mathrm{TV}}\!\big(P_{V \mid X=0},\, P_{V \mid X=1}\big) \;+\; \mathbb{E}_{V \sim P_{V \mid X = 0}}\!\big[d_{\mathrm{TV}}\!\big(P_{U \mid V, X=0},\, P_{U \mid V, X=1}\big)\big]. $$

This is the standard data-processing / conditional decomposition of total variation [@polyanskiy2025information Ch. 4 Thm 4.4 and Ch. 7]. Setting $V = A$ and $U = \mathcal{M}(d)$ gives a first term $d_{\mathrm{TV}}(P_{A \mid X=0},\, P_{A \mid X=1}) = \alpha$. For the second term, the conditional-independence assumption (CI) implies

$$ P_{\mathcal{M}(d) \mid A = a, X = b} \;=\; P_{\mathcal{M}(d) \mid X = b} \quad \text{for all } a, b, $$

so the inner TV does not depend on $A$ and equals $\mathrm{Adv}_{\mathcal{M}}(X)$. Substituting yields $\mathrm{Adv}(X \mid \mathcal{M}, A) \leq \alpha + \mathrm{Adv}_{\mathcal{M}}(X)$. ∎

**Remark on the conditional-independence assumption.** (CI) is the load-bearing assumption of Lemma 1. It holds whenever the auxiliary channel $A$ is generated independently of the mechanism's noise — for example, $A$ is published metadata or external joinable data that the mechanism does not consume as input. It does *not* hold if the adversary chooses $A$ adaptively after observing $\mathcal{M}(d)$, or if the mechanism's randomness is correlated with $A$ via a side channel. Theorem 2a applies (CI) with $A$ = the event-channel auxiliary information, $\mathcal{M}$ = the Gaussian-mechanism aggregate; (CI) is satisfied because the DP noise is drawn from publicly verifiable randomness independent of $A$ (B2). Theorem 2b applies (CI) analogously with $A$ = the amount-channel auxiliary information.

Lemma 1 is the load-bearing technical step shared by Theorems 2a and 2b. Each theorem instantiates a specific mechanism $\mathcal{M}$, derives $\mathrm{Adv}_{\mathcal{M}}(X)$ from first principles for that mechanism, and invokes Lemma 1 to compose with $\alpha$ under (CI).

### Theorem 2a — Event-detection cohort bound

**Theorem 2a (Event detection, Gaussian-aggregate model).** Fix the security parameter $\lambda = 128$. Under the conditions:

- *(B1) — Bounded sensitivity.* Transaction amounts are clipped at threshold $\tau > 0$ before aggregation; neighbouring databases differ in exactly one record and aggregate sensitivity is $\Delta = \tau$.
- *(B2) — Gaussian mechanism.* Per-period noise $\eta \sim \mathcal{N}(0, \sigma_{\mathrm{DP}}^2)$ with $\sigma_{\mathrm{DP}} = \tau \sqrt{2 \ln(1.25/\delta)} / \varepsilon$, drawn from publicly verifiable randomness per [§4.3](#sec-4-3).
- *(B3) — Cohort-distribution model.* Legitimate cohort transactions are i.i.d.\ from a distribution class $\mathcal{D}$ on $[0, \tau]$ with mean $\mu_T$ and finite variance $\sigma_T^2 > 0$, and bounded third absolute central moment $\gamma_3 := \mathbb{E}|T - \mu_T|^3 < \infty$. The cohort under attack consists of $k$ such transactions, optionally plus a target anomalous transaction of magnitude $\tau$.
- *(B3$^{\mathrm{G}}$) — Gaussian-aggregate model.* The cohort sum $S_k := \sum_{i=1}^{k} T_i$ is treated as a Gaussian random variable with mean $k\mu_T$ and variance $k\sigma_T^2$. This holds *exactly* when the $T_i$ themselves are Gaussian (e.g., a tightly modeled retail-transaction distribution), and *approximately* by the Central Limit Theorem when the $T_i$ are non-Gaussian; the approximation error is bounded by Berry-Esseen as discussed in the remark below.
- *(B4) — Cryptographic layer absorbed.* Theorem 1's hiding holds under (A1)–(A3); the cryptographic failure probability is bounded by $\mathit{negl}(\lambda) \leq 2^{-100}$.
- *(B5e) — Event-channel auxiliary information.* The adversary's auxiliary channel about the event indicator $X_e$ has TV-richness $\alpha_e \in [0, 1]$ as defined in [§3.1](#sec-3-1)(4).

The mechanism satisfies Definition 2a with bound

$$ \mathrm{Adv}^{\mathrm{event}} \;\leq\; \alpha_e + \big[\,2\,\Phi\!\big(\tau / (2 \sqrt{k\sigma_T^2 + \sigma_{\mathrm{DP}}^2})\big) - 1\,\big] \;+\; \varepsilon_{\mathrm{CLT}}(k). $$

The CLT correction $\varepsilon_{\mathrm{CLT}}(k) = 0$ under (B3$^{\mathrm{G}}$) holding exactly. When (B3$^{\mathrm{G}}$) holds only by CLT, the Berry-Esseen theorem gives $\varepsilon_{\mathrm{CLT}}(k) \leq C \cdot \gamma_3 / (\sigma_T^3 \sqrt{k})$ for an absolute constant $C \leq 0.4748$ [@polyanskiy2025information Ch. 4], which is $O(k^{-1/2})$ and small at deployment-relevant cohort sizes.

In the natural-variance-dominated regime $k \sigma_T^2 \gg \sigma_{\mathrm{DP}}^2$, the bracketed Gaussian-LRT term simplifies to $\tau / (\sqrt{2\pi k}\, \sigma_T) + O(k^{-3/2})$; equivalently, the bound exhibits a $1/\sqrt{k}$ scaling driven by *cohort transaction variance*, not by differential-privacy composition. In the DP-dominated regime $\sigma_{\mathrm{DP}}^2 \gg k \sigma_T^2$ the cohort sum's deviation from Gaussianity is irrelevant — the Gaussian DP noise dominates and the aggregate is Gaussian by construction; the bracketed term saturates near $\tau / (\sqrt{2\pi}\, \sigma_{\mathrm{DP}})$ and ceases to depend on $k$.

*Proof.* Fix $b \in \{0, 1\}$. Under (B3$^{\mathrm{G}}$), the released aggregate satisfies

$$ Y \,\mid\, X_e = b \;\sim\; \mathcal{N}\!\big(k \mu_T + b \tau,\;\; k \sigma_T^2 + \sigma_{\mathrm{DP}}^2\big). $$

The optimal LRT advantage between two normals with common variance $V := k \sigma_T^2 + \sigma_{\mathrm{DP}}^2$ and mean separation $\tau$ is $2\Phi(\tau / (2 \sqrt{V})) - 1$ — the closed-form TV distance between the two laws. Under (B4), the cryptographic layer adds at most $\mathit{negl}(\lambda)$ to this distance via union bound. Lemma 1 with the auxiliary channel (B5e) gives the stated additive composition with $\alpha_e$. The $\varepsilon_{\mathrm{CLT}}(k)$ term is the worst-case TV between the actual cohort-sum distribution and its Gaussian approximation under (B3$^{\mathrm{G}}$); it is zero under exact Gaussianity and bounded by Berry-Esseen otherwise. ∎

**Remark on the Gaussian-aggregate assumption.** (B3$^{\mathrm{G}}$) is the substantive modelling commitment of Theorem 2a. Two regimes make it tight: (i) a Gaussian or near-Gaussian transaction-amount distribution at the deployment's cohort granularity (a modeling choice the deployer must justify against the in-scope rail's empirical distribution), and (ii) any regime where $\sigma_{\mathrm{DP}}^2 \gtrsim k \sigma_T^2$, because the Gaussian DP noise then dominates the aggregate and the cohort-distribution shape is irrelevant. For deployments where $T_i$ are heavy-tailed and $k\sigma_T^2 \gg \sigma_{\mathrm{DP}}^2$, the bound holds with the explicit $\varepsilon_{\mathrm{CLT}}(k)$ correction.

**Worked-example bound on $\varepsilon_{\mathrm{CLT}}$ at small deployment-relevant $k$.** A reviewer can ask: what is $\varepsilon_{\mathrm{CLT}}(k)$ at the smallest $k$ for which Theorem 2a is operationally interesting, under heavy-tailed $T_i$? Take the headline calibration $\sigma_T = \$1{,}000$, target $\beta_e = 0.10$, and the smallest deployment-relevant cohort $k = 500$ (well below the headline $k^*_{\mathrm{event}} = 3{,}551$ but inside the natural-variance-dominated regime since $k\sigma_T^2 = 5 \times 10^8$ is comparable to $\sigma_{\mathrm{DP}}^2 = 2.78 \times 10^9$). For a clipped-Pareto retail distribution with shape parameter 2.5 and scale calibrated so the 99th percentile is $\tau$, the third absolute central moment ratio $\gamma_3 / \sigma_T^3$ is approximately $5$ (a generous heavy-tail upper bound for the bounded-clip regime; lighter-tailed distributions give smaller ratios). Berry-Esseen then gives

$$ \varepsilon_{\mathrm{CLT}}(500) \;\leq\; \frac{0.4748 \cdot 5}{\sqrt{500}} \;\approx\; 0.106. $$

This is the same order of magnitude as $\beta_e = 0.10$ — i.e., at $k = 500$ with pessimistic heavy-tail assumptions, the CLT correction is *not* negligible relative to the operational target. Two responses are available to a deployer in this regime: (a) restrict deployment to cohorts above the regime-crossover ($k = 2{,}808$ at the headline calibration), where the DP-noise term dominates and (B3$^{\mathrm{G}}$) becomes automatic; (b) use a tighter Berry-Esseen variant (multivariate or Edgeworth-corrected) or a non-asymptotic Gaussian-approximation bound calibrated to the deployer's measured transaction-amount distribution. At the headline $k^*_{\mathrm{event}} = 3{,}551$, $\varepsilon_{\mathrm{CLT}}$ falls to $\approx 0.040$ under the same pessimistic $\gamma_3/\sigma_T^3 = 5$, and to $\approx 0.008$ under a moderate $\gamma_3/\sigma_T^3 = 1$ that is more typical for a clipped retail distribution. The qualitative $1/\sqrt{k}$ scaling is preserved across the regime, but the constant is not negligible at small $k$ with heavy tails — and the paper's quantitative claims are stated at $k$ above the regime crossover, where the correction is sub-dominant.

**Inversion to $k^*$.** For deployer-chosen $\beta_e$ with $\beta_e > \alpha_e$, the smallest cohort size satisfying $\mathrm{Adv}^{\mathrm{event}} \leq \beta_e$ is

$$ k^*_{\mathrm{event}}(\alpha_e, \beta_e, \tau, \sigma_T, \sigma_{\mathrm{DP}}) \;=\; \left\lceil \frac{(\tau / (2 z^*))^2 - \sigma_{\mathrm{DP}}^2}{\sigma_T^2} \right\rceil_{\geq 0},\qquad z^* := \Phi^{-1}\!\big((1 + \beta_e - \alpha_e)/2\big). $$

When $\beta_e \leq \alpha_e$, no $k$ achieves the target — auxiliary information alone exceeds the deployer's threshold (Corollary 2 fires for the event-detection threat).

### Theorem 2b — Amount-disclosure cohort bound

**Theorem 2b (Amount disclosure).** Fix $\lambda = 128$. Under (B1)–(B4) above plus:

- *(B5a) — Amount-channel auxiliary information.* The adversary's auxiliary channel about the binary amount discrimination $X_a \in \{a_0, a_1\}$ with $|a_0 - a_1| \leq \tau$ has TV-richness $\alpha_a \in [0, 1]$ as defined in [§3.1](#sec-3-1)(4).
- *(B6) — zCDP composition (single named accountant).* Per-period zCDP parameter $\rho_p = \varepsilon^2 / (4 \ln(1.25/\delta))$ from @bun2016concentrated Proposition 1.6. $P$-fold linear composition: $\rho_{\mathrm{total}} = P \cdot \rho_p$ (Lemma 2.3). Conversion to $(\varepsilon_P, \delta_P)$-DP: $\varepsilon_P(\delta_P) = \rho_{\mathrm{total}} + 2\sqrt{\rho_{\mathrm{total}} \log(1/\delta_P)}$ (Proposition 1.3). Total failure $\delta_{\mathrm{total}} = \delta_P + 2^{-100}$.

The mechanism satisfies Definition 2b with bound

$$ \mathrm{Adv}^{\mathrm{amt}} \;\leq\; \min\!\big(\,\alpha_a + \tanh(\varepsilon_P / 2) + \delta_{\mathrm{total}},\;\; 1\big). $$

The bound is **independent of cohort size $k$**.

*Proof.* The Gaussian mechanism is $\rho_p$-zCDP per (B6) Proposition 1.6, which under linear composition (Lemma 2.3) and conversion (Proposition 1.3) yields the stated $(\varepsilon_P, \delta_P)$-DP guarantee for the $P$-fold release. The standard hypothesis-testing characterisation of $(\varepsilon, \delta)$-DP gives the exact single-mechanism advantage $\mathrm{Adv}_{\mathcal{M}}(X_a) \leq (e^{\varepsilon_P} - 1)/(e^{\varepsilon_P} + 1) + \delta_P = \tanh(\varepsilon_P/2) + \delta_P$ on the discriminative pair $(a_0, a_1)$ [@kairouz2017composition]. Lemma 1 with the auxiliary channel (B5a) gives the stated additive composition with $\alpha_a$. The $\min(\cdot, 1)$ is the trivial bound on binary advantage. The bound depends on $\tau$ only through (B1)'s sensitivity and is invariant to cohort size — adding records to the database does not dilute a per-neighbouring-database DP guarantee. ∎

**Recovery cases.** At $\alpha_a = 0$, the bound reduces to $\tanh(\varepsilon_P/2) + \delta_{\mathrm{total}}$, the standard hypothesis-testing form of the $(\varepsilon_P, \delta_P)$-DP guarantee. At $\alpha_a = 1$, the bound saturates at 1 (degenerate aux channel determines the target). The bound is monotonically non-decreasing in $\alpha_a$ and $\varepsilon_P$.

### Composition statement for the cryptographic layer

The role of Theorem 1 in Theorems 2a and 2b is not to make DP itself computational, but to ensure that the per-transaction cryptographic artifacts composed with the aggregate release do not add exploitable witness leakage beyond what the DP mechanism accounts for. Under (B4), proof transcripts can be replaced by simulated transcripts in the hybrid argument, and the commitment layer contributes no amount leakage at the individual level beyond the public metadata named in [§4.4](#sec-4-4). If the setup assumptions of Theorem 1 fail, this composition step fails and neither Theorem 2a nor 2b applies to the full deployed stack.

### Distributional assumptions: bounded sensitivity and cohort variance

Theorems 2a and 2b assume bounded-sensitivity queries (B1) under amount clipping at $\tau$. Real-world transaction distributions are heavy-tailed [@newman2005powerlaws], and the gap between the theorems' bounded-sensitivity assumption and heavy-tailed reality is load-bearing.

*Mitigation.* Standard DP practice caps amounts at a per-jurisdiction threshold $\tau$ chosen to preserve a stated fraction of total mass (default: 99%, reported in [§7](#sec-7)). The theorems are stated on the clipped distribution. Clipping loss is reported as a robustness quantity in [§7](#sec-7); clipping leakage (the observation that a transaction hit the clip threshold is itself a signal) is folded into $\delta_{\mathrm{total}}$ via a one-sided tail bound on $\Pr[\mathit{amount} > \tau]$ (see [Appendix A.2](#app-a-2)).

*Cohort-variance assumption (Theorem 2a only).* Theorem 2a additionally requires (B3): legitimate cohort transactions are i.i.d.\ with finite variance $\sigma_T^2$. The bound's $1/\sqrt{k}$ scaling is sensitive to $\sigma_T$ (a deployer with very small $\sigma_T$ — a near-constant-amount cohort — has a sharper signal-to-noise ratio at any $k$). [§7](#sec-7) reports sensitivity to $\sigma_T$ across realistic retail-transaction calibrations.

*Honest gap statement.* Against an adversary exploiting the heavy tail of the *unclipped* distribution, Theorem 2a's bound on the *clipped* aggregate is the operative statement; clipping leakage is absorbed into $\delta_{\mathrm{total}}$ as above. The i.i.d.\ assumption (B3) is an idealization — real cohorts have correlated transaction patterns that may amplify the event-detection signal beyond what an i.i.d.\ model predicts. [§6.4](#sec-6-4) analyses one such amplification (correlated timing plus auxiliary-dataset joining); the gap to fully-general adversarial cohort distributions is named explicitly in [§8.5](#sec-8-5).

## 5.4 Corollary 2 — infeasibility regime (K-M corollary, not new theorem) {#sec-5-4}

The negative result of this paper is *not a new impossibility theorem*. It is a direct corollary of Theorems 2a and 2b combined with @kifer2011nofreelunch's no-free-lunch result, instantiated in the cohort-aggregation setting of [§4](#sec-4). The negative result has two clean statements, one per threat.

**Corollary 2a (Event-detection infeasibility).** Under the conditions of Theorem 2a, whenever the auxiliary-information richness $\alpha_e$ meets or exceeds the deployer-chosen target $\beta_e$, no finite cohort size achieves $(\beta_e, \alpha_e)$-event-privacy. The auxiliary channel alone delivers advantage $\alpha_e \geq \beta_e$; cohort size cannot reduce a quantity that is already determined by the adversary's prior knowledge.

**Corollary 2b (Amount-disclosure infeasibility).** Under the conditions of Theorem 2b, whenever $\alpha_a + \tanh(\varepsilon_P/2) + \delta_{\mathrm{total}} \geq \beta_a$, no per-period DP budget $(\varepsilon, \delta)$ alone — and no cohort size $k$ — achieves $(\beta_a, \alpha_a)$-amount-privacy. Equivalently, the closed-form infeasibility threshold is

$$ \alpha^*_a(\beta_a,\, \varepsilon_P,\, \delta_{\mathrm{total}}) \;=\; \beta_a - \tanh(\varepsilon_P/2) - \delta_{\mathrm{total}}. $$

When $\alpha^*_a \leq 0$, the amount-disclosure target is unreachable from DP plus this auxiliary channel at any $\alpha_a \in [0, 1]$; meaningful per-record amount privacy then requires either a tighter per-period $\varepsilon$ (so that $\tanh(\varepsilon_P/2) < \beta_a$) or supplementary mechanisms beyond standard Gaussian DP.

*Proof.* Direct rearrangement of the bounds in Theorems 2a and 2b. ∎

**Why these are corollaries, not theorems.** Kifer and Machanavajjhala [@kifer2011nofreelunch] proved the underlying impossibility at the abstract level: DP combined with sufficiently rich auxiliary information cannot deliver arbitrary posterior-advantage guarantees. Corollaries 2a and 2b contribute the *closed-form instantiations* of the impossibility threshold in the cohort-aggregation setting of this paper, falling out as one-line algebraic consequences of the Theorem 2a/2b bounds. There is no new theorem statement, no new proof technique, no new mechanism-specific reduction. The novelty is the explicit forms in this setting, not the impossibility itself.

**Empirical bite of Corollary 2b.** At standard annual DP budgets — $\varepsilon = 1.0$ per period, $\delta = 10^{-6}$, $P = 12$ — the composition gives $\varepsilon_P \approx 3.65$ and $\tanh(\varepsilon_P/2) \approx 0.95$. The amount-disclosure infeasibility threshold $\alpha^*_a$ is therefore *negative* for any operational $\beta_a < 0.95$. This is an honest negative result: at this budget, standard Gaussian DP alone cannot deliver per-record amount-privacy at typical operational thresholds for *any* $\alpha_a \geq 0$. Tightening the per-period budget — e.g., $\varepsilon = 0.25$ giving $\tanh(\varepsilon_P/2) \approx 0.40$ — opens a feasibility regime at $\alpha_a \lesssim \beta_a - 0.40$. The deployer trades DP-budget tightness against utility (smaller $\varepsilon$ = larger $\sigma_{\mathrm{DP}}$, see Theorem 2a) and against feasible $\alpha_a$ ranges; Section [§8](#sec-8) and the sensitivity table in [§5.5](#sec-5-5) draw the trade-off explicitly.

**Engagement with the strongest disconfirming precedent.** The empirical record on privacy-preserving cryptographic schemes is uneven, and the unevenness has multiple causes. Monero's initial linkability was undone by ring-signature decoy analysis [@moser2018empirical]; Zcash's shielded-pool usage patterns leak linkability information even when the underlying cryptography is sound [@kappos2018zcash]; mix-and-tumble systems were followed by practical deanonymization driven by network-layer correlation and mix-pool flow analysis [@meiklejohn2013fistful]. The steelmanned precedent is that past payment-privacy claims have repeatedly been undone by *combinations* of implementation flaws, usage-pattern leakage, network-layer correlation, and auxiliary-information attacks the designers did not anticipate.

This paper does not claim to have made the cryptography better. It closes one specific gap (auxiliary-information-modelling) by separating event-detection and amount-disclosure threats, giving each its own bound and its own infeasibility carve-out, and reporting [§7](#sec-7)'s simulations under empirically-anchored auxiliary information rather than under parametric $\alpha$ that flatters the bound. The empirical failure modes outside this analysis (network correlation, implementation defects, usage-pattern leakage) remain valid concerns and are flagged where they intersect the bound ([§6](#sec-6)).

**Remark on post-quantum robustness.** Pedersen *hiding* is information-theoretic and survives a quantum adversary, so the per-transaction amount-confidentiality property of Theorem 1 is preserved against Shor. What Shor breaks is *Pedersen binding* (DL-based) and the *soundness* of any DL- or pairing-based zero-knowledge proof system in the stack — i.e., the non-equivocation guarantee that the same commitment cannot be opened to two different amounts, and the range-proof / attestation correctness needed for a sound protocol. Theorems 2a and 2b's DP component is information-theoretic, but the full stack is not post-quantum because the binding-side primitives are not. Post-quantum hardening requires replacing the binding layer (a lattice-based commitment) and the soundness-side proof systems, then re-running the composition analysis; the paper does not claim such a swap is automatic.

## 5.5 Corollary 1 — *k\** bound and quantitative estimates {#sec-5-5}

**Corollary 1 (Event-detection $k^*$ bound; closed-form, derived from Theorem 2a).** Under the conditions of Theorem 2a, the minimum cohort size satisfying $(\beta_e, \alpha_e)$-event-privacy at per-period DP budget $(\varepsilon, \delta)$ and cohort transaction std-dev $\sigma_T$ is

$$ k^*_{\mathrm{event}}(\alpha_e, \beta_e, \tau, \sigma_T, \varepsilon, \delta) \;=\; \left\lceil \frac{(\tau / (2 z^*))^2 - \sigma_{\mathrm{DP}}^2}{\sigma_T^2} \right\rceil_{\geq 0},\qquad z^* := \Phi^{-1}\!\big((1 + \beta_e - \alpha_e)/2\big), $$

with $\sigma_{\mathrm{DP}} = \tau \sqrt{2 \ln(1.25/\delta)} / \varepsilon$. When $\beta_e \leq \alpha_e$, no $k$ satisfies the target — Corollary 2a fires.

For the amount-disclosure threat, Theorem 2b gives a $k$-independent bound, and Corollary 2b states the closed-form infeasibility threshold $\alpha^*_a = \beta_a - \tanh(\varepsilon_P/2) - \delta_{\mathrm{total}}$ above which no $k$ achieves the target. There is no $k^*_{\mathrm{amount}}$ in the standard Gaussian-DP setting; meaningful per-record amount-privacy is a function of the DP budget and $\alpha_a$, not the cohort size.

**Scope of the $1/\sqrt{k}$ scaling.** The $1/\sqrt{k}$ scaling in $k^*_{\mathrm{event}}$ emerges from the natural variance of the legitimate cohort transaction distribution (Theorem 2a, B3) and is *not* a property of differential-privacy composition. In the natural-variance-dominated regime $k \sigma_T^2 \gg \sigma_{\mathrm{DP}}^2$, the bound is a Gaussian signal-to-noise ratio that an additional record dilutes; in the DP-dominated regime $\sigma_{\mathrm{DP}}^2 \gg k \sigma_T^2$, cohort size has no effect and the operative constraint is the per-period DP budget. The crossover occurs at $k = \sigma_{\mathrm{DP}}^2 / \sigma_T^2$.

**Headline numerical estimates.** Headline parameters: $\varepsilon = 1.0$ per period, $\delta = 10^{-6}$, $P = 12$ (monthly aggregation, annual budget), $\delta_P = 10^{-6}$, $\tau = \$10{,}000$ clip threshold, $\sigma_T = \$1{,}000$ legitimate-transaction std-dev, $\beta_e = \beta_a = 0.10$ operational target. Derived quantities: $\sigma_{\mathrm{DP}} \approx \$52{,}988$, $\varepsilon_P \approx 3.65$, $\tanh(\varepsilon_P/2) \approx 0.95$. Regime crossover at $k \approx 2{,}808$.

| Tier | $\alpha_e, \alpha_a$ | Theorem 2a $k^*_{\mathrm{event}}$ | Theorem 2b Adv$^{\mathrm{amt}}$ |
|---|---|---:|---:|
| Tier 1 | $0.05$ | **3,551** | $\geq 0.99$ |
| Tier 2 | $0.50$ | infeasible ($\alpha_e \geq \beta_e$) | $\geq 1.00$ |
| Tier 3 (de Montjoye-rich) | $0.85, 0.94$ | infeasible | $1.00$ |

Both bounds are reproduced from the audit-traceable R script `derivation/theorem2-dual-bound.R` and verified by Monte Carlo (N=20,000) within sampling noise.

**Two interpretive points.** First, the Tier 1 event-detection $k^* \approx 3{,}551$ is the load-bearing positive result: at small auxiliary-information richness about event timing, cohort aggregation above this size makes detection harder than the deployer-chosen $\beta_e$. Second, the Tier 2/3 amount-disclosure saturation is the paper's load-bearing negative result: at standard DP budgets, $\tanh(\varepsilon_P/2) \approx 0.95$ alone exceeds typical operational thresholds. Meaningful per-record amount-privacy at this budget requires either auxiliary information so weak that $\alpha_a + 0.95 < \beta_a$ — implausibly weak in any realistic threat model — or a tighter per-period $\varepsilon$, traded against utility (larger $\sigma_{\mathrm{DP}}$ = more noise per release).

**Sensitivity to $\sigma_T$ and $\varepsilon$ (Theorem 2a $k^*_{\mathrm{event}}$).** The bound is sensitive to legitimate-transaction variance. Holding $\alpha_e = 0.05$, $\beta_e = 0.10$, $\varepsilon = 1.0$, $\delta = 10^{-6}$, $\tau = \$10{,}000$:

|  | $\sigma_T = \$250$ | $\sigma_T = \$500$ | $\sigma_T = \$1{,}000$ | $\sigma_T = \$2{,}000$ | $\sigma_T = \$3{,}000$ |
|---|---:|---:|---:|---:|---:|
| $k^*_{\mathrm{event}}$ | 56,803 | 14,201 | **3,551** | 888 | 395 |

Smaller cohort variance → tighter signal → larger $k^*$ required. A deployer should calibrate $\sigma_T$ from the in-scope transaction-amount distribution at the deployed jurisdictional granularity; the simulation in [§7](#sec-7) reports $\sigma_T$ ranges across realistic retail-transaction calibrations.

Holding $\alpha_e = 0.05$, $\beta_e = 0.10$, $\sigma_T = \$1{,}000$, varying per-period $\varepsilon$:

| $\varepsilon$ | $\sigma_{\mathrm{DP}}$ | $\varepsilon_P$ | $k^*_{\mathrm{event}}$ |
|---:|---:|---:|---:|
| 0.25 | \$211,952 | 0.87 | DP-dominated regime; $k^*$ vacuous (operational bound on amount-disclosure dominates) |
| 0.50 | \$105,976 | 1.77 | DP-dominated |
| **1.00** | **\$52,988** | **3.65** | **3,551** |
| 2.00 | \$26,494 | 7.73 | 5,656 |
| 4.00 | \$13,247 | 17.17 | 6,183 |

The trade-off is explicit: smaller $\varepsilon$ gives more DP noise (which dominates $\sigma_T$ and removes the cohort-variance advantage entirely) and tighter $\tanh(\varepsilon_P/2)$ at the amount-disclosure layer; larger $\varepsilon$ shrinks DP noise (cohort variance dominates and $1/\sqrt{k}$ operates) at the cost of loosening the amount-disclosure bound.

**Reproducibility.** The R script `derivation/theorem2-dual-bound.R` produces all numbers in this section; output is captured in `theorem2-dual-bound-output.txt`. A reader who substitutes a different calibration (different $\sigma_T$, different $\tau$, different $\beta$, different empirical $\alpha$) re-runs the script with one parameter change.

## 5.6 Claim-type map: what is proved, what is calibrated, what is illustrative {#sec-5-6}

Reviewers should know exactly which claims are theorem-backed and which are simulation-backed or empirically calibrated. Every quantitative statement in the paper falls into one of these categories.

| Claim | Type | Source / Anchor |
|---|---|---|
| Theorem 1: individual-transaction hiding under Pedersen + ZK | **Proved** | [Appendix A.1](#app-a-1) (hybrid argument, [@goldreich2001foundations]) |
| Lemma 1: TV-distance posterior-advantage chain rule | **Proved** | [§5.3](#sec-5-3) ([@polyanskiy2025information] Ch. 7 + standard DP hypothesis-testing characterisation) |
| Theorem 2a: event-detection bound $\alpha_e + 2\Phi(\tau / 2\sqrt{k\sigma_T^2 + \sigma_{\mathrm{DP}}^2}) - 1$ | **Proved (closed-form)** | [Appendix A.2](#app-a-2) (Gaussian-LRT marginalization + Lemma 1) |
| Theorem 2b: amount-disclosure bound $\min(\alpha_a + \tanh(\varepsilon_P/2) + \delta_{\mathrm{total}}, 1)$ | **Proved (closed-form, $k$-independent)** | [Appendix A.2](#app-a-2) (zCDP composition [@bun2016concentrated] + Lemma 1) |
| Corollary 1: $k^*_{\mathrm{event}}$ inversion | **Proved (closed-form)** | [Appendix A.3](#app-a-3) (inversion of Theorem 2a) |
| Corollary 2a/2b: infeasibility regimes ($\alpha \geq \beta$ or $\alpha + \tanh \geq \beta$) | **Proved (algebraic corollary)** | [§5.4](#sec-5-4) ([@kifer2011nofreelunch]-style instantiation) |
| Headline numerical $k^*_{\mathrm{event}} = 3{,}551$ at Tier 1 ($\sigma_T = \$1{,}000$) | **Closed-form numerical** | R script `theorem2-dual-bound.R`, output captured |
| Sensitivity table $k^*_{\mathrm{event}}$ vs $(\alpha_e, \sigma_T, \varepsilon)$ | **Closed-form, R-tabulated** | [§5.5](#sec-5-5) tables + R script |
| Monte Carlo verification of Theorem 2a closed form | **Empirical** | R script Monte Carlo battery; [§7](#sec-7) |
| Tier 2 empirical $\alpha_e \approx 0.94$ from de Montjoye-style spatiotemporal uniqueness | **Calibrated (empirical)** | [§3.1](#sec-3-1)(4); [@demontjoye2015unique] |
| Tier 2/3 amount-disclosure infeasibility at standard $\varepsilon = 1.0$ budget | **Proved (Corollary 2b)** | $\tanh(\varepsilon_P/2) \approx 0.95$ at headline budget; [§5.4](#sec-5-4) |
| Side-channel inflation under correlated timing + join | **Simulation-backed (illustrative)** | [§6.4](#sec-6-4); [Appendix A.4](#app-a-4) |

The paper's load-bearing positive result is *Theorem 2a's $k^*_{\mathrm{event}}$ bound at Tier 1 auxiliary information* (cohort variance dominates DP noise above the regime crossover; closed-form $1/\sqrt{k}$ scaling). The paper's load-bearing negative result is *Corollary 2b at empirically-realistic $\alpha_a$* (DP alone at standard budgets cannot deliver per-record amount-privacy; the deployer must either tighten $\varepsilon$ at the cost of utility, accept supplementary mechanisms, or revise the threat model).

---

# 6. Side channels and attacks that survive the cryptographic layer {#sec-6}

Every privacy paper of this shape owes the reader a side-channel catalog. A paper that proved cryptographic properties but did not name the attack classes whose defense is *outside* the cryptography would be a partial paper. Each attack class below is tied to a specific, named prior result in the literature. Handwaving — "timing attacks exist" — is not what this section does.

## 6.1 Catalog and out-of-scope items {#sec-6-1}

Five attack classes survive the cryptographic layer: *timing* [@kocher1996timing; @murdoch2005low] (transaction-submission patterns leak presence/routine even under encrypted content); *size and frequency* [@bonneau2015sok] (aggregate shifts at calendar events leak higher-moment signals beyond pointwise DP noise); *network-level correlation* [@biryukov2014deanonymisation; @biryukov2019privacy] (IP-layer traffic analysis, mitigated by onion routing or mixnet relay at stated latency cost); *pseudonym reuse and linkability* [@meiklejohn2013fistful; @narayanan2008robust] (user-discipline requirement, not a protocol guarantee); and *direct auxiliary-information joins* [@sweeney2002k; @ohm2010broken; @demontjoye2015unique] (the Kifer-Machanavajjhala failure mode made empirical, modeled by Theorems 2a and 2b's $\alpha_e$ and $\alpha_a$).

Out of scope: physical endpoint compromise, user-endpoint key exfiltration, regulatory compulsion of rail operators, network-layer traffic analysis (delegated to mixnet/onion-routing layers if required), post-quantum cryptanalysis of the commitment group, and deployment parameter gaming (non-publicly-verifiable noise source, compromised trusted setup, weakened commitment group). Each is a real attack surface; the paper's contribution is that they are *named*.

Adjacent-layer mitigations and their honest costs: onion routing for network-layer confidentiality (latency in hundreds of ms; subject to network-layer timing analysis); padding and batching for timing/size leakage (batching windows in minutes to hours for meaningful attenuation; bandwidth overhead); pseudonym rotation for linkability (key-management complexity; possible loss of reputational continuity; operational burden distinguishing rotation from Sybil). No mitigation is free; deployments must report the residual side-channel surface explicitly.

## 6.4 Worst-case-realistic side-channel {#sec-6-4}

The side-channel that most damages the paper's positive claim under a plausible deployment is not any single item in [§6.1](#sec-6-1) but the *combination* of a few under a single capable adversary. We commit to one specific combined attack and re-evaluate Theorem 2a against it explicitly.

**The combined attack.** The adversary observes: (i) per-pseudonym transaction-timing patterns from the public rail-issued timestamps; (ii) the public clip-rate statistic, read as a coarse high-amount indicator; (iii) the cohort identifier (jurisdiction at the aggregation granularity, public by design); (iv) one auxiliary dataset — a voter-roll + census join + public social-media geotag scrape — with empirical $\alpha_e \approx 0.94$ in the de Montjoye-style spatiotemporal-uniqueness model.

**Effect on Theorem 2a.** Theorem 2a still holds; what changes is the effective $\alpha_e$ entering the bound. The §6.4 attack inflates $\alpha_e$ but **preserves Lemma 1's conditional-independence assumption (CI)**: the timing observations the adversary reads from the public ledger are independent of the publicly-verifiable-randomness (B2) used to draw the DP noise, so the auxiliary channel $A$ remains independent of $\mathcal{M}$'s coins given the target $X_e$. The TV chain rule of Lemma 1 therefore composes cleanly. The timing-channel adds a derived $\Delta\alpha_{\mathrm{timing}} = 0.027$ (95% CI [0.000, 0.469]; see [Appendix A.4](#app-a-4) for the derivation under stated Gaussian-jitter assumptions, $\sigma \approx 1$ hour, 1-second timestamp resolution, quarterly aggregation), composed with the Tier-2 baseline $\alpha_e \approx 0.94$ via a TV-chain-rule upper bound, producing a composite Tier-3 $\alpha_e$ broadly compatible with the Tier-2 CI for typical cohorts and reaching near-1 in small-cohort regimes. We remind the reader that the Tier-2 baseline $\alpha_e \approx 0.94$ is itself a stylized translation of spatiotemporal-uniqueness data in the style of @demontjoye2015unique, not a measured TV-richness; the composite Tier-3 figure inherits that illustrative status and a deployer must substitute their own observed timing distribution and auxiliary channels to operationalise it.

**Operational consequence.** The composite Tier-3 $\alpha_e$ already exceeds typical operational $\beta_e \in [0.05, 0.10]$ before $1/\sqrt{k}$ has any room to operate. Corollary 2a fires: under the worst-case-realistic side-channel, no cohort size achieves event-detection privacy at typical $\beta_e$. This is the honest negative result for the side-channel-aware setting; the positive result of Theorem 2a is meaningful only in the regime where the deployer can credibly assume Tier-1 auxiliary information ($\alpha_e \ll \beta_e$), which requires that adjacent-layer mitigations (onion routing, padding, pseudonym rotation) drive the empirically-realistic Tier-2/3 $\alpha_e$ back into the Tier-1 range.

**Effect on Theorem 2b.** The amount-disclosure bound is independent of the side-channel inflation: cohort size does not enter, and the timing channel does not alter the amount-disclosure $\alpha_a$. Corollary 2b's infeasibility regime is unchanged by side-channel composition — it is governed by the per-period DP budget alone.

**Why we publish the honest result.** A paper that reported the clean-adversary bound as its headline and buried the worst-case-realistic adversary in a footnote would reproduce the failure mode of prior payment-privacy claims that held in the threat model the authors chose and failed in the threat model the real adversary brought. The feasibility regimes in [§8](#sec-8) are therefore stated under both Tier-1 (positive result for event detection) and Tier-3 (infeasibility for both threats) explicitly.

---

# 7. Attack simulation {#sec-7}

**Scope commitment.** [§7](#sec-7) tests Theorem 2a's closed-form event-detection bound against Monte Carlo simulation of the corresponding LRT attack on synthetic transaction distributions. The simulation does not "validate" Theorem 2a in any formal sense — the bound is closed-form by construction — but it confirms that the analytic expression matches the empirical LRT advantage within sampling noise across the parameter range, which is the operationally meaningful question for a deployer. Theorem 2b's $k$-independence is verified analytically; no simulation is required (zCDP composition is a closed-form calculation).

## 7.1 Synthetic transaction distribution calibration {#sec-7-1}

**Scope of the calibration (illustrative).** The calibration is *illustrative*. Aggregate public sources are used for parameter targets, but the synthetic transaction stream is not validated against microdata. A microdata-backed re-calibration is a natural extension flagged in [§8.5](#sec-8-5).

**Heavy-tailed amounts and cohort variance.** Per-user transaction-amount distributions are fit to a power-law-like distribution [@newman2005powerlaws], with parameter targets informed by aggregate public sources on US payment-rail activity (Federal Reserve Payment Study, Nilson Report aggregates, BEA personal-consumption expenditures). After clipping at $\tau = \$10{,}000$, the cohort transaction std-dev is calibrated in the range $\sigma_T \in [\$250, \$3{,}000]$, with the headline calibration at $\sigma_T = \$1{,}000$. Sensitivity to $\sigma_T$ is reported in [§5.5](#sec-5-5)'s sensitivity table; deployment calibration should use the relevant jurisdiction's in-scope amount distribution.

**Transaction density ρ.** Density enters only through the per-period throughput of in-scope transactions in a given cohort; it does not appear in the Theorem 2a or 2b bounds (the original draft's $1/\sqrt{\rho \cdot k}$ scaling was a category error, since corrected). The simulation uses 750 in-scope transactions per person per year (~187 per person per quarter) as a baseline calibration; deployments substitute their own.

## 7.2 Adversary simulations — event-detection LRT (Theorem 2a) {#sec-7-2}

The simulation runs the Definition 2a attack game: a target anomalous transaction of magnitude $\tau$ is either present or absent in a cohort of size $k$ drawn from the calibrated transaction distribution; the optimal Bayes-classifier on $Y = \sum \mathrm{clip}_\tau(\mathit{amount}) + \eta$ outputs a guess; advantage is $2 \cdot \mathrm{accuracy} - 1$ over $N$ Monte Carlo replications.

**Closed form vs. Monte Carlo (headline parameters: $\tau = \$10{,}000$, $\sigma_T = \$1{,}000$, $\sigma_{\mathrm{DP}} = \$52{,}988$, $\alpha_e = 0$, $N = 20{,}000$ replications per row).**

The Monte Carlo standard error for an empirical advantage of magnitude $\hat{p}$ at $N = 20{,}000$ is approximately $2\sqrt{\hat{p}(1-\hat{p})/N} \approx 7 \times 10^{-3}$. The 95% CI is the empirical advantage $\pm$ this std error.

| $k$ | Closed form | Monte Carlo (mean) | MC 95% CI | Relative error | Within CI? |
|---:|---:|---:|---:|---:|:---:|
| 100 | 0.0739 | 0.0763 | [0.0692, 0.0834] | +3.3% | yes |
| 500 | 0.0693 | 0.0722 | [0.0651, 0.0793] | +4.3% | yes |
| 1,000 | 0.0646 | 0.0623 | [0.0552, 0.0694] | −3.6% | yes |
| 3,000 | 0.0523 | 0.0516 | [0.0445, 0.0587] | −1.5% | yes |
| 10,000 | 0.0352 | 0.0290 | [0.0220, 0.0360] | −17.7% | yes (margin) |
| 50,000 | 0.0174 | 0.0186 | [0.0118, 0.0254] | +7.2% | yes |

The closed form is the exact Gaussian-vs-Gaussian LRT advantage under the Gaussian-aggregate assumption (B3$^{\mathrm{G}}$); the Monte Carlo above is run under the Gaussian-aggregate model and agrees within sampling noise of order $1/\sqrt{N}$. The deviation at $k=10{,}000$ reflects the small absolute size of the LRT advantage at that scale, where Monte Carlo standard error is a large fraction of the signal — not a closed-form mis-statement. Under non-Gaussian cohort distributions, the bound carries the Berry-Esseen correction term $\varepsilon_{\mathrm{CLT}}(k)$ noted in Theorem 2a.

![Figure 1. Theorem 2a closed-form event-detection LRT advantage vs. cohort size $k$ at headline parameters; Monte Carlo overlay with N=20,000 replications. The crossover from DP-dominated to natural-variance-dominated regime occurs at $k \approx 2{,}808$; above this $k$, the $1/\sqrt{k}$ behaviour of cohort-variance dispersal operates.](../simulations/figures/fig01_kstar_vs_alpha.png){width=85%}

**Auxiliary-information sweep ($\alpha_e$, $\beta_e = 0.10$).** At $\alpha_e \in [0, 0.05]$, $k^*_{\mathrm{event}}$ is in the low-thousands range (3,551 at $\alpha_e = 0.05$, $\sigma_T = \$1{,}000$). At $\alpha_e \geq \beta_e$, no $k$ achieves the target — Corollary 2a fires. The simulation confirms the closed-form's regime partition: feasibility for Tier 1 auxiliary information; infeasibility for Tier 2/3.

**Amount-inference under unclipped tail.** A separate battery confirms that under unclipped amounts (the honest-gap scenario of [§5.3](#sec-5-3)), an adversary with the clip-rate statistic and a single known large transaction can recover that transaction's amount — the expected failure mode under (B1) violation. Clipping plus DP at the deployer's $\varepsilon$ controls amount-disclosure exactly to Theorem 2b's $k$-independent bound; no simulation is needed there.

## 7.3 Longitudinal composition {#sec-7-3}

Repeat-observation attack over a multi-year window. The longitudinal contribution is *already captured by Theorem 2b's $\varepsilon_P$ via $P$-fold zCDP composition* [@bun2016concentrated] — there is no separate "longitudinal inflation factor" beyond the standard $\sqrt{P}$ scaling that zCDP produces in the conversion to $(\varepsilon_P, \delta_P)$-DP. The simulation confirms this analytically: the headline $\varepsilon_P \approx 3.65$ at $P = 12$ already encodes the worst-case longitudinal advantage; extending to $P = 60$ (monthly over five years) gives $\varepsilon_P \approx 8.4$, $\tanh(\varepsilon_P/2) \approx 0.999$, and Corollary 2b's amount-disclosure infeasibility is correspondingly tighter.

For Theorem 2a (event detection), longitudinal composition does not directly tighten the per-period bound — each release is a single noisy aggregate against an i.i.d.\ cohort, and a target observed across $P$ periods can exhibit per-period anomalies that the $T$-fold setup amplifies only when the adversary's per-period auxiliary information is itself longitudinally accumulating. Under the conservative assumption that $\alpha_e$ at period $p$ is independent of releases at $p' \neq p$, the per-period bound applies. Under a more aggressive model in which the adversary accumulates side-information across periods, $\alpha_e$ grows period-over-period; this is best modeled by re-running [§7.2](#sec-7-2) with the elevated $\alpha_e$ rather than as a stand-alone "longitudinal multiplier."

**Design implication.** Deployments targeting long observation horizons must either budget per-period $\varepsilon$ tighter than the headline (with the cost of additional DP noise per release) or accept that Theorem 2b's $\tanh(\varepsilon_P/2)$ approaches 1 as $P$ grows. [§8](#sec-8) discusses the trade-off.

## 7.4 Robustness {#sec-7-4}

Three robustness checks against parameters of Theorem 2a.

- *Transaction variance $\sigma_T$.* The bound's $1/\sqrt{k}$ scaling has $\sigma_T$ in the denominator. Halving $\sigma_T$ approximately quadruples $k^*_{\mathrm{event}}$ in the natural-variance-dominated regime; doubling it approximately quarters $k^*$. [§5.5](#sec-5-5) reports the sensitivity table across $\sigma_T \in [\$250, \$3{,}000]$.
- *Clipping threshold $\tau$.* Theorem 2a's bound has $\tau^2$ in the numerator (under inversion). Tighter clipping (smaller $\tau$, more clipping loss) reduces $k^*$ quadratically while increasing the clip-rate side-channel signal that absorbs into $\delta_{\mathrm{total}}$. Looser clipping increases $k^*$ and attenuates the clip-rate signal. [§8.4](#sec-8-4) names the publish-both-clip-threshold-and-clip-rate discipline that makes the trade-off auditable.
- *Noise-generation source.* The simulation assumes (B2)'s publicly-verifiable-randomness requirement holds. Local PRNG is outside the theorems' scope per [§4.3](#sec-4-3); a fingerprint-aware adversary against local-PRNG noise reduces the noise entropy and in the worst case voids the bound entirely. Local PRNG is not a valid deployment choice.

## 7.5 Threshold readings {#sec-7-5}

The simulation reports two operationally meaningful thresholds.

**Theorem 2a event-detection threshold (positive result, Tier 1).** Under headline parameters and Tier 1 auxiliary information ($\alpha_e \leq 0.05$), $k^*_{\mathrm{event}} \approx 3{,}551$ transactions per cohort at $\sigma_T = \$1{,}000$. At a baseline 750 in-scope transactions per person per year, this corresponds to per-quarter cohorts achievable at populations of approximately $3{,}551 / (750/4) \approx 19$ residents — i.e., the event-detection bound is satisfied with substantial margin at any realistic locality scale (hundreds to thousands of residents). The cohort-variance-driven $1/\sqrt{k}$ regime begins above the regime crossover at $k \approx 2{,}808$; below this, DP noise dominates and the bound saturates near its DP-dominated limit, which under headline $\varepsilon$ is comfortable at any $k$.

**Theorem 2b amount-disclosure threshold (negative result, Tier 2/3).** Under headline DP budget ($\varepsilon = 1.0$ per period, $P = 12$), $\tanh(\varepsilon_P/2) \approx 0.95$ alone exceeds typical operational $\beta_a = 0.10$. For any auxiliary-information richness $\alpha_a \geq 0$, Corollary 2b fires: no cohort size delivers per-record amount privacy at standard DP budgets. The deployer must either tighten per-period $\varepsilon$ (e.g., $\varepsilon = 0.25$ giving $\tanh(\varepsilon_P/2) \approx 0.40$, opening a feasibility regime at $\alpha_a \lesssim \beta_a - 0.40$) or accept that amount-disclosure resistance must come from supplementary mechanisms beyond standard Gaussian DP.

![Figure 2. Theorem 2a event-detection $k^*_{\mathrm{event}}$ across $(\alpha_e, \sigma_T)$ at headline $\varepsilon$, $\delta$, $\beta_e = 0.10$. White cells are infeasible ($\alpha_e \geq \beta_e$); shaded cells give the closed-form $k^*$ from inversion of Theorem 2a.](../simulations/figures/fig02_longitudinal.png){width=85%}

![Figure 3. Theorem 2b amount-disclosure bound $\min(\alpha_a + \tanh(\varepsilon_P/2) + \delta, 1)$ across $(\alpha_a, \varepsilon)$. Cohort size does not enter; the operational threshold $\beta_a$ partitions the parameter space into a feasibility regime at small $\alpha_a$ and tight $\varepsilon$ and an infeasibility regime — Corollary 2b's region — that includes the entire empirically-realistic Tier 2/3 calibration at standard DP budgets.](../simulations/figures/fig03_feasibility_boundary.png){width=90%}

The two thresholds together specify the design space [§8](#sec-8) operates in: cohort aggregation suffices for event-detection privacy at Tier 1 auxiliary information; amount-disclosure privacy under standard DP budgets is unachievable at empirically-realistic auxiliary information and requires either tighter $\varepsilon$ or supplementary mechanisms.

## 7.6 Replication

The simulation code is released under a permissive open-source license (see Appendix B). The R script `derivation/theorem2-dual-bound.R` produces all closed-form numbers and the Monte Carlo verification. Python attack-simulation code in `simulations/simulate_attacks.py` reproduces Figures 1–3. Random seeds are fixed. Total runtime is approximately one to two minutes on a modern laptop at the default Monte Carlo count.

---

# 8. Implications and design recommendations {#sec-8}

[§8](#sec-8) translates [§5](#sec-5)'s theorems and [§7](#sec-7)'s simulation into design implications. The section deliberately stops short of policy advocacy — the paper is a tradeoff measurement; policymakers decide how to navigate it.

## 8.1 Event-detection feasibility regime (Theorem 2a)

For event-detection privacy at *Tier 1 auxiliary information* ($\alpha_e \leq \beta_e$, e.g., $\alpha_e \leq 0.05$ at $\beta_e = 0.10$), Theorem 2a's $k^*_{\mathrm{event}}$ bound is satisfied at modest cohort sizes. At the headline calibration ($\sigma_T = \$1{,}000$, $\tau = \$10{,}000$, $\varepsilon = 1.0$), $k^*_{\mathrm{event}} \approx 3{,}551$ transactions per cohort. At realistic per-period throughput (hundreds to thousands of in-scope transactions per person per quarter), this threshold is achievable at locality scales of tens to hundreds of residents — far below the population thresholds that would be operationally useful for jurisdictional attribution.

The Theorem 2a feasibility claim is conditional on:

1. The deployment uses publicly-verifiable randomness for DP noise, not local PRNG ([§4.3](#sec-4-3)).
2. Amount clipping is enforced at $\tau$, with the clip rate published as a separate statistic.
3. The legitimate-cohort transaction distribution has finite variance $\sigma_T^2$ in the calibrated range; the deployer reports the empirical $\sigma_T$ on which the bound is computed.
4. The auxiliary-information richness $\alpha_e$ for event detection is credibly within Tier 1, which under [§6.4](#sec-6-4)'s side-channel analysis requires either weak adjacent-layer auxiliary information *or* effective adjacent-layer mitigations (onion routing, padding, pseudonym rotation) that drive empirically-realistic $\alpha_e$ down to Tier 1.

A deployment that violates any condition is outside the feasibility regime the paper defends.

## 8.2 Amount-disclosure infeasibility regime (Theorem 2b)

For amount-disclosure privacy under standard Gaussian-DP budgets ($\varepsilon = 1.0$ per period, $P = 12$, $\delta = 10^{-6}$), Corollary 2b fires across the empirically-realistic auxiliary-information range. $\tanh(\varepsilon_P/2) \approx 0.95$ alone exceeds typical operational $\beta_a \in [0.05, 0.10]$. No cohort size $k$ rescues this: amount-disclosure is governed by the per-period DP budget, not by aggregation. The deployer has three options:

- *(a) Tighten per-period $\varepsilon$.* At $\varepsilon \leq 0.25$, $\tanh(\varepsilon_P/2) \approx 0.40$, opening a feasibility regime at $\alpha_a \lesssim \beta_a - 0.40$. Cost: noise scale $\sigma_{\mathrm{DP}}$ scales as $1/\varepsilon$, degrading aggregate utility roughly proportionally.
- *(b) Compose with supplementary mechanisms.* Cohort minimum-aggregation thresholds, temporal smoothing (release windows long enough to mask per-transaction signals within natural variation), and adjacent-layer protections together can deliver per-record amount-resistance that DP alone does not. The composition is application-specific and must be proved separately for each candidate stack; [§8.4](#sec-8-4) names the discipline.
- *(c) Revise the threat model.* If the deployer can credibly argue that empirical $\alpha_a$ in the deployment context is small (e.g., the relevant adversary has no useful prior over target amounts), Theorem 2b's feasibility regime opens. This is the auxiliary-information-discipline argument and requires evidence beyond what this paper provides for any specific deployment.

None of (a)-(c) is a cryptographic fix. Each is a deployment-engineering choice with explicit costs.

## 8.3 Side-channel discipline

Theorem 2a and 2b are protocol-layer bounds. Real-world privacy is bounded *above* by adjacent-layer leakage (timing patterns, network correlation, pseudonym reuse) and *below* by the protocol-layer bound. The deployer's actual privacy posture is the composition. [§6.4](#sec-6-4)'s worst-case-realistic side-channel analysis already demonstrates that the empirically-realistic regime drives Theorem 2a's $\alpha_e$ into Corollary 2a's infeasibility region at typical $\beta_e$ — the positive event-detection result of Theorem 2a is meaningful only when adjacent-layer mitigations are in place.

The deployment-reporting discipline: publish (i) the side-channel posture (timing mitigations, network-layer anonymity, pseudonym-rotation policy), (ii) the empirical $\alpha_e, \alpha_a$ assumed under that posture, and (iii) the resulting $k^*_{\mathrm{event}}$ and amount-disclosure regime. Treat $k^*$ as a floor-under-conditions, not a point estimate.

## 8.4 Specific deployment recommendations {#sec-8-4}

Three discipline requirements.

1. *Publish $k^*_{\mathrm{event}}$ per jurisdiction per period* under the deployment's actual $\sigma_T, \alpha_e, \varepsilon$. If $k^*$ is not achievable at the declared aggregation granularity, coarsen the granularity until it is.
2. *Audit-level access restrictions on intermediate state.* The aggregate output is public; individual commitments, pre-noise values, and proof witnesses are not. Intermediate state should not be persisted after the aggregate is computed, so that later compulsion cannot recover it.
3. *Periodic re-evaluation against auxiliary-data drift.* A mechanism evaluated at Tier 2 auxiliary information today may face a richer auxiliary channel tomorrow as public datasets accumulate. Commit to a re-evaluation schedule and to threshold revision in response.

## 8.5 Scope limits this paper does not close {#sec-8-5}

Two follow-ons:

- *Microdata-validated auxiliary-information richness.* The Tier 2 calibrations of $\alpha_e$ and $\alpha_a$ are derived from stylized joint-distribution models anchored to the @demontjoye2015unique uniqueness rate. A direct microdata estimate against an actual transaction dataset would tighten confidence intervals and could reveal joint-distribution effects the stylized model misses. The qualitative conclusions (Tier-1 feasibility, Tier-2/3 infeasibility for amount disclosure under standard budgets) are robust to this refinement; the precise boundary in $\alpha$-space is not.
- *Mechanism-specific quantitative impossibility.* Corollary 2b is stated at the level of the standard Gaussian-DP mechanism; a stronger result for a specific composed stack — including supplementary mechanisms (temporal smoothing, k-anonymity at the disclosure layer) — would require a fresh composition analysis. The dual-bound separation of this paper makes such an analysis tractable but does not carry it out.

## 8.6 Headline

In one sentence: *under the dual-bound separation, cohort aggregation at modest sizes ($k \gtrsim 3{,}500$ at headline calibration) suffices for event-detection privacy at Tier-1 auxiliary information; per-record amount-disclosure privacy under standard Gaussian-DP budgets is infeasible at empirically-realistic auxiliary information regardless of cohort size, and requires either tighter per-period $\varepsilon$, composition with supplementary mechanisms, or a revised threat model.*

A reader who wanted a single $k^*$ feasibility threshold spanning both threats is looking in the wrong place; a reader who wants an honest separation of what cohort aggregation does and does not deliver under standard DP composition will find one.

---

# 9. Conclusion {#sec-9}

The paper set out to specify whether protocol-layer cohort aggregation under Gaussian-DP composition can deliver application-layer privacy in the protocol-level transaction-tax setting. The answer separates by threat. For *event detection*, the cohort transaction variance gives a $1/\sqrt{k}$ bound (Theorem 2a) that is satisfied at modest cohort sizes when auxiliary information about event timing is bounded — Tier 1 in the paper's discipline. For *per-record amount disclosure*, the bound is the standard $(\varepsilon, \delta)$-DP guarantee composed with auxiliary information via the TV chain rule (Theorem 2b), $k$-independent, and at standard annual budgets it saturates: Corollary 2b shows that no cohort size delivers meaningful amount-disclosure privacy for any empirically-realistic auxiliary information, unless the deployer tightens $\varepsilon$ or composes with supplementary mechanisms.

Two mechanism-level theorems carried the formal load. Theorem 1 established individual-transaction hiding from the composition of Pedersen commitments with zero-knowledge validity proofs. Theorem 2's two-part decomposition — 2a (event detection, $k$-dependent, derived from cohort variance) and 2b (amount disclosure, $k$-independent, derived from zCDP composition under a single named accountant [@bun2016concentrated]) — separated two formerly conflated threats and gave each its own closed-form bound. Corollaries 2a and 2b are the closed-form infeasibility carve-outs that fall out of the bounds when auxiliary information meets or exceeds the operational target.

The paper's contribution is the dual-bound separation, the closed-form bounds for each threat, the empirically-anchored three-tier auxiliary-information discipline, and the honest negative result for standard Gaussian-DP at empirically-realistic auxiliary information. The paper closes the auxiliary-information-modelling gap that prior cohort-DP analyses left implicit. The empirical failure modes outside the paper's scope — network-layer correlation, implementation defects, usage-pattern leakage — remain valid concerns and are flagged where they intersect the bound.

A reader who wanted a louder positive defense of protocol-layer cohort aggregation will not find it here. A reader who wanted a formal specification of what the mechanism delivers at each threat layer, and what it does not, will. The boundaries are the contribution. The space on either side of them is where deployment engineers and policymakers, not cryptographers, decide.

---

# Appendix A. Full proofs {#app-a}

This appendix contains the full proofs of Theorems 1, 2a, and 2b, the derivation of the $k^*_{\mathrm{event}}$ bound (Corollary 1) and sensitivity tables, the side-channel inflation factor, and the Corollary 2a / 2b infeasibility carve-outs. All numerical values reported in the paper come from the R script `derivation/theorem2-dual-bound.R`, which is the audit-trail companion to this appendix.

## A.1 Proof of Theorem 1 (individual-transaction hiding) {#app-a-1}

The reduction is a standard hybrid argument. Let $\mathcal{A}$ be a PPT distinguisher on the individual-transaction hiding game. Construct a sequence of hybrids:

- $H_0$: Real protocol — honest commitment to $m_0$, honest proof transcript.
- $H_1$: Real commitment to $m_0$, simulated proof transcript (via the ZK simulator).
- $H_2$: Commitment to $m_1$ instead of $m_0$, simulated proof transcript.
- $H_3$: Commitment to $m_1$, honest proof transcript.

Indistinguishability of $H_0$ from $H_1$ follows from the zero-knowledge property of the proof system under (B4)'s setup assumption. Indistinguishability of $H_1$ from $H_2$ follows from the Pedersen *hiding* property — perfect (information-theoretic), so the reduction is tight under any group satisfying the discrete-logarithm-relation-unknown assumption on the generators. Indistinguishability of $H_2$ from $H_3$ follows again from zero-knowledge. Composition via the triangle inequality yields the claim. ∎

## A.2 Proof of Theorem 2 — dual bound (event detection + amount disclosure) {#app-a-2}

The proof has two parts, one per theorem statement. Both use the same cryptographic-layer absorption (Step 1 below) and Lemma 1 (TV chain rule, [§5.3](#sec-5-3)); they diverge in how the mechanism's TV distance $\mathrm{Adv}_{\mathcal{M}}(X)$ is computed for each threat.

### Step 1 (shared) — Mechanism specification and cryptographic absorption

Per [§4.2](#sec-4-2)–[§4.3](#sec-4-3), the per-period released aggregate for jurisdiction $j$ in period $p$ is

$$ Y_{p,j} = \Big( \sum_{t \in T_{p,j}} \mathrm{clip}_\tau(\mathit{amount}(t)) \Big) + \eta_{p,j}, \qquad \eta_{p,j} \sim \mathcal{N}(0, \sigma_{\mathrm{DP}}^2), $$

with neighbouring-database sensitivity $\Delta = \tau$ and Gaussian noise scale $\sigma_{\mathrm{DP}} = \tau \sqrt{2 \ln(1.25/\delta)} / \varepsilon$, drawn from publicly verifiable randomness (B2). By Theorem 1 ([§5.2](#sec-5-2)), the cryptographic layer (Pedersen + ZK) preserves individual-transaction hiding up to $\mathit{negl}(\lambda) \leq 2^{-100}$ for $\lambda = 128$. Union bound: $\delta_{\mathrm{total}} = \delta_P + 2^{-100}$, dominated by $\delta_P$ for any practical setting.

### Step 2a — Theorem 2a: event-detection bound (Gaussian-LRT marginalization)

Under (B3), legitimate cohort transactions $T_1, \ldots, T_k$ are i.i.d.\ from $\mathcal{D}$ on $[0, \tau]$ with mean $\mu_T$, variance $\sigma_T^2$, and bounded third absolute central moment $\gamma_3 = \mathbb{E}|T - \mu_T|^3$. The clipped sum has the same mean and variance (clipping at $\tau$ has no effect on i.i.d.\ samples in $[0, \tau]$). Under the event-detection attack game (Definition 2a), conditioning on $X_e = b \in \{0, 1\}$:

$$ Y \,\mid\, X_e = b \;=\; \sum_{i=1}^{k} T_i + b \cdot \tau + \eta, $$

with $\eta \sim \mathcal{N}(0, \sigma_{\mathrm{DP}}^2)$ independent of the cohort. Under the Gaussian-aggregate model (B3$^{\mathrm{G}}$) — exact for Gaussian $T_i$, approximate by CLT for non-Gaussian — the marginal distribution of $Y$ is

$$ Y \,\mid\, X_e = b \;\sim\; \mathcal{N}\!\big(k\mu_T + b\tau,\;\; k\sigma_T^2 + \sigma_{\mathrm{DP}}^2\big). $$

The mechanism $\mathcal{M}$'s TV distance on the conditional output distributions is the TV between two normals of common variance $V := k\sigma_T^2 + \sigma_{\mathrm{DP}}^2$ separated by mean $\tau$. Using the closed-form TV distance for Gaussians of equal variance:

$$ \mathrm{Adv}_{\mathcal{M}}(X_e) \;=\; d_{\mathrm{TV}}\big(\mathcal{N}(k\mu_T, V),\, \mathcal{N}(k\mu_T + \tau, V)\big) \;=\; 2\Phi\!\big(\tau / (2\sqrt{V})\big) - 1. $$

When (B3$^{\mathrm{G}}$) holds only approximately (non-Gaussian $T_i$), the cohort-sum law deviates from the Gaussian above by a TV distance bounded via the Berry-Esseen theorem [@polyanskiy2025information Ch. 4]:

$$ \varepsilon_{\mathrm{CLT}}(k) \;:=\; d_{\mathrm{TV}}\!\big(P_{S_k},\, \mathcal{N}(k\mu_T, k\sigma_T^2)\big) \;\leq\; \frac{C \cdot \gamma_3}{\sigma_T^3 \sqrt{k}}, $$

with absolute constant $C \leq 0.4748$. This $\varepsilon_{\mathrm{CLT}}(k)$ is added to the bound as a transparent CLT correction. Lemma 1 with auxiliary channel (B5e) gives

$$ \mathrm{Adv}^{\mathrm{event}} \;\leq\; \alpha_e + 2\Phi\!\big(\tau / (2\sqrt{k\sigma_T^2 + \sigma_{\mathrm{DP}}^2})\big) - 1 + \varepsilon_{\mathrm{CLT}}(k). $$

In the natural-variance-dominated regime $k\sigma_T^2 \gg \sigma_{\mathrm{DP}}^2$, the bracketed term reduces (via $2\Phi(x) - 1 \leq x \sqrt{2/\pi}$ for small $x \geq 0$) to $\tau / (\sqrt{2\pi k}\, \sigma_T) + O(k^{-3/2})$, and $\varepsilon_{\mathrm{CLT}}(k) = O(k^{-1/2})$ is sub-dominant. In the DP-dominated regime $\sigma_{\mathrm{DP}}^2 \gg k\sigma_T^2$, the cohort-distribution shape is irrelevant — the Gaussian DP noise dominates the aggregate so $\varepsilon_{\mathrm{CLT}}(k) \to 0$ effectively — and the bracketed term becomes $\tau / (\sqrt{2\pi}\, \sigma_{\mathrm{DP}})$, $k$-independent. The crossover occurs at $k = \sigma_{\mathrm{DP}}^2 / \sigma_T^2$. ∎ (Theorem 2a)

### Step 2b — Theorem 2b: amount-disclosure bound (zCDP composition)

The per-period Gaussian mechanism with sensitivity $\Delta = \tau$ and noise scale $\sigma_{\mathrm{DP}}$ satisfies $\rho_p$-zCDP exactly with $\rho_p = \Delta^2 / (2\sigma_{\mathrm{DP}}^2) = \varepsilon^2 / (4 \ln(1.25/\delta))$ (@bun2016concentrated Proposition 1.6). $P$-fold linear composition gives $\rho_{\mathrm{total}} = P \cdot \rho_p$ (Lemma 2.3). Conversion to $(\varepsilon_P, \delta_P)$-DP gives $\varepsilon_P(\delta_P) = \rho_{\mathrm{total}} + 2\sqrt{\rho_{\mathrm{total}} \log(1/\delta_P)}$ (Proposition 1.3). For headline parameters ($\varepsilon = 1.0$, $\delta = 10^{-6}$, $P = 12$, $\delta_P = 10^{-6}$), $\rho_{\mathrm{total}} = 0.2137$ and $\varepsilon_P = 3.6502$. (RDP cross-check at the optimal Rényi order [@mironov2017renyi]: 3.6502, agreement to relative difference $1.2 \times 10^{-5}$.)

Under the amount-disclosure attack game (Definition 2b), the discriminative pair is $(a_0, a_1)$ with $|a_0 - a_1| \leq \tau$. The standard hypothesis-testing characterisation of $(\varepsilon_P, \delta_P)$-DP [@kairouz2017composition] gives the optimal binary-distinguisher TV distance

$$ \mathrm{Adv}_{\mathcal{M}}(X_a) \;\leq\; \frac{e^{\varepsilon_P} - 1}{e^{\varepsilon_P} + 1} + \delta_P \;=\; \tanh(\varepsilon_P/2) + \delta_P. $$

The bound is $k$-independent: it is the per-neighbouring-database guarantee, and adding records to the database does not dilute it. Lemma 1 with auxiliary channel (B5a):

$$ \mathrm{Adv}^{\mathrm{amt}} \;\leq\; \alpha_a + \tanh(\varepsilon_P/2) + \delta_{\mathrm{total}}, $$

bounded above by 1 (binary advantage). ∎ (Theorem 2b)

### Recovery cases and monotonicity

At $\alpha_e = 0$, Theorem 2a reduces to the marginal Gaussian-LRT advantage on the cohort-aggregated mean shift. At $\alpha_a = 0$, Theorem 2b reduces to the standard hypothesis-testing form $\tanh(\varepsilon_P/2) + \delta_{\mathrm{total}}$ of $(\varepsilon_P, \delta_P)$-DP. Both bounds are monotonically non-decreasing in $\alpha$ and $\varepsilon$. Theorem 2a's bound is monotonically non-increasing in $k$ (larger cohort $\Rightarrow$ tighter bound).

## A.3 $k^*$ corollary (Theorem 2a inversion) and sensitivity table {#app-a-3}

**Corollary 1 (closed-form $k^*_{\mathrm{event}}$).** Setting $\mathrm{Adv}^{\mathrm{event}} \leq \beta_e$ in Theorem 2a's bound and inverting:

$$ k^*_{\mathrm{event}}(\alpha_e, \beta_e, \tau, \sigma_T, \sigma_{\mathrm{DP}}) \;=\; \left\lceil \frac{(\tau / (2 z^*))^2 - \sigma_{\mathrm{DP}}^2}{\sigma_T^2} \right\rceil_{\geq 0},\qquad z^* := \Phi^{-1}\!\big((1 + \beta_e - \alpha_e)/2\big). $$

When $\beta_e \leq \alpha_e$, no $k$ achieves the target — Corollary 2a fires.

**Headline numerical estimate.** For $\varepsilon = 1.0$, $\delta = 10^{-6}$, $P = 12$, $\delta_P = 10^{-6}$, $\tau = \$10{,}000$, $\sigma_T = \$1{,}000$, $\alpha_e = 0.05$, $\beta_e = 0.10$: $\sigma_{\mathrm{DP}} \approx \$52{,}988$; $z^* = \Phi^{-1}(0.525) \approx 0.0627$; $(\tau/(2z^*))^2 - \sigma_{\mathrm{DP}}^2 \approx 6.36 \times 10^9 - 2.78 \times 10^9 \approx 3.58 \times 10^9$; $k^*_{\mathrm{event}} \approx 3{,}551$. Regime crossover at $k = \sigma_{\mathrm{DP}}^2 / \sigma_T^2 \approx 2{,}808$.

**Sensitivity table (computed by `derivation/theorem2-dual-bound.R`, fixed seed = 2026).**

| $\alpha_e$ | $\sigma_T = \$250$ | $\sigma_T = \$500$ | $\sigma_T = \$1{,}000$ | $\sigma_T = \$1{,}500$ | $\sigma_T = \$2{,}000$ | $\sigma_T = \$3{,}000$ |
|---|---:|---:|---:|---:|---:|---:|
| 0.00 | 0 | 0 | 0 | 0 | 0 | 0 |
| 0.02 | 0 | 0 | 0 | 0 | 0 | 0 |
| 0.05 | 56,803 | 14,201 | **3,551** | 1,578 | 888 | 395 |
| 0.08 | 591,563 | 147,891 | 36,973 | 16,433 | 9,244 | 4,109 |
| 0.09 | 2,501,423 | 625,356 | 156,339 | 69,484 | 39,085 | 17,371 |

(Rows above $\beta_e = 0.10$ are infeasible at any $\sigma_T$; rows at $\alpha_e \in \{0.00, 0.02\}$ are 0 because the DP-dominated regime already meets the target without any cohort-variance contribution.)

**Sensitivity to per-period $\varepsilon$ (at $\alpha_e = 0.05$, $\sigma_T = \$1{,}000$).**

| $\varepsilon$ | $\sigma_{\mathrm{DP}}$ | $\varepsilon_P$ | $\tanh(\varepsilon_P/2)$ | $k^*_{\mathrm{event}}$ |
|---:|---:|---:|---:|---:|
| 0.25 | \$211,952 | 0.872 | 0.40 | 0 (DP-dominated saturates 2a; 2b infeasibility relaxes to $\alpha_a < 0.10 - 0.40$ regime) |
| 0.50 | \$105,976 | 1.772 | 0.71 | 0 (DP-dominated) |
| 1.00 | \$52,988 | 3.650 | 0.95 | **3,551** |
| 2.00 | \$26,494 | 7.728 | $\approx 1$ | 5,656 |
| 4.00 | \$13,247 | 17.165 | $\approx 1$ | 6,183 |

**Monte Carlo confirmation (Theorem 2a, N = 20,000).** Headline parameters, $\alpha_e = 0$. Closed form vs. empirical LRT advantage:

| $k$ | Closed form | Monte Carlo | Rel. error |
|---:|---:|---:|---:|
| 100 | 0.0739 | 0.0763 | +3.3% |
| 500 | 0.0693 | 0.0722 | +4.3% |
| 1,000 | 0.0646 | 0.0623 | −3.6% |
| 3,000 | 0.0523 | 0.0516 | −1.5% |
| 10,000 | 0.0352 | 0.0290 | −17.7% |
| 50,000 | 0.0174 | 0.0186 | +7.2% |

Closed form is exact for the marginal Gaussian-vs-Gaussian LRT against the i.i.d.\ cohort model (B3); Monte Carlo agrees within sampling noise of order $1/\sqrt{N}$. Larger relative errors at $k \in \{10{,}000, 50{,}000\}$ reflect the small absolute LRT advantage in those rows, where Monte Carlo standard error is a large fraction of the signal — not a closed-form mis-statement. ∎

## A.4 Side-channel inflation factor {#app-a-4}

Under the [§6.4](#sec-6-4) combined attack, the adversary's effective $\alpha_e$ is inflated by the timing-channel mutual information about target identity. We derive the inflation step-by-step under stated modelling assumptions; the result is illustrative rather than measured.

### A.4.1 Timing-channel information per observation

Following the timing-channel framework of @kocher1996timing, the bits of timing information leaked per public-ledger observation, under a Gaussian-jitter model of user submission time, are:

$$ I_{\mathrm{timing}} \;=\; \log_2\!\left(\frac{T_{\mathrm{period}}}{T_{\mathrm{res}}}\right) \;-\; \log_2\!\left(\sigma_{\mathrm{jitter}} \cdot \sqrt{2\pi e} \cdot T_{\mathrm{res}}^{-1}\right). $$

The first term is the entropy of the uniform prior over timestamps within the aggregation window (period length divided by timestamp resolution). The second term is the differential entropy of a Gaussian with std-dev $\sigma_{\mathrm{jitter}}$, expressed in resolution-units. Plugging in the headline assumptions ($T_{\mathrm{period}} = 90 \text{ days} = 7.776 \times 10^6 \text{ s}$, $T_{\mathrm{res}} = 1 \text{ s}$, $\sigma_{\mathrm{jitter}} = 3{,}600 \text{ s}$):

$$ I_{\mathrm{timing}} \;=\; \log_2(7.776 \times 10^6) - \log_2(3{,}600 \cdot 4.13) \;\approx\; 22.9 - 13.9 \;=\; 9.0 \text{ bits/observation}. $$

### A.4.2 Translation from timing-bits to TV-richness

The translation from $I_{\mathrm{timing}}$ to a TV-richness contribution $\Delta\alpha_{\mathrm{timing}}$ is **not direct** and is the step driving the wide CI. The key intermediate quantity is the *cohort-overlap count* $N_{\mathrm{overlap}}(k)$ — the expected number of users in a cohort of size $k$ whose timing signature is consistent with the target's timing signature, given the jitter model. For a uniform-prior cohort of $N_{\mathrm{users}}$ users with i.i.d.\ Gaussian-jitter timing patterns:

$$ N_{\mathrm{overlap}}(k, \sigma_{\mathrm{jitter}}) \;\approx\; N_{\mathrm{users}}(k) \cdot \frac{2\sigma_{\mathrm{jitter}}}{T_{\mathrm{period}}}, $$

where $N_{\mathrm{users}}(k)$ is the number of users contributing to a cohort of size $k$ (depends on the per-user transaction rate; we use $N_{\mathrm{users}} \approx k / 50$ for the headline rail-activity calibration). For $k = 10^4$ this gives $N_{\mathrm{overlap}} \approx 200 \cdot 9 \times 10^{-4} \approx 0.18$ — i.e., on average less than one other user shares the target's timing window. The conditional entropy of target identity given timing is then $H(X_e \mid \text{timing}) \approx \log_2(N_{\mathrm{overlap}} + 1)$, and in the binary inference game the residual richness of the timing channel is $\Delta\alpha_{\mathrm{timing}} \approx 1 - H(X_e \mid \text{timing}) / H(X_e)$ when the channel is informative, and $\approx 0$ when $H(X_e \mid \text{timing}) \geq H(X_e) = 1$.

### A.4.3 Why the CI is wide

The above mapping is *cohort-size-dependent*: as $k$ varies, $N_{\mathrm{overlap}}(k)$ varies, and the timing-channel residual richness varies non-monotonically. For large cohorts ($N_{\mathrm{overlap}} \gg 1$), timing is uninformative about identity and $\Delta\alpha_{\mathrm{timing}} \approx 0$. For small cohorts ($N_{\mathrm{overlap}} \ll 1$, near-deterministic regime), timing is highly informative and $\Delta\alpha_{\mathrm{timing}} \to 1 - 0 = 1$, but our prior ($\sigma_{\mathrm{jitter}}$ uniform on a stated range) caps the small-cohort tail. Monte Carlo over the joint prior of $(\sigma_{\mathrm{jitter}}, T_{\mathrm{res}}, k)$ with the Gaussian-jitter assumption (50,000 replications under the prior-draft framing; the qualitative finding survives in the new dual-bound formulation) produced the **mean $\Delta\alpha_{\mathrm{timing}} = 0.027$, 95% CI $[0.000, 0.469]$**. The lower bound corresponds to large-cohort regimes where timing is uninformative; the upper tail corresponds to small-cohort regimes where one or zero other users overlap the target's timing window and the channel becomes near-deterministic. The wide CI is intrinsic to the cohort-size dependence, not an artifact of the prior choice.

### A.4.4 What this is and is not

This is a derivation under **stated assumptions** (Gaussian jitter at fixed $\sigma$, timestamp resolution at fixed $T_{\mathrm{res}}$, no holiday/weekend bimodality, no shift-work clustering), **not an empirical measurement** against any real payment-rail microdata. A deployment would observe the in-scope users' actual submission-time distribution, fit it (likely non-Gaussian), and recompute $\Delta\alpha_{\mathrm{timing}}$ directly from the observed distribution. The qualitative conclusion — that the timing channel inflates $\alpha_e$ by a small amount on average but can be substantial in small-cohort regimes — would survive most plausible microdata corrections; the precise CI would tighten or shift depending on the empirical distribution. Microdata validation is an explicit follow-on flagged in [§8.5](#sec-8-5).

## A.5 Proof of Corollaries 2a, 2b {#app-a-5}

**Corollary 2a.** Under Theorem 2a, $\mathrm{Adv}^{\mathrm{event}} \geq \alpha_e$ regardless of $k$ (the auxiliary channel alone delivers advantage $\alpha_e$). Therefore $\beta_e \leq \alpha_e$ implies $\mathrm{Adv}^{\mathrm{event}} \geq \beta_e$ for all $k$, contradicting the deployer's target. ∎

**Corollary 2b.** Under Theorem 2b, $\mathrm{Adv}^{\mathrm{amt}} \geq \alpha_a + \tanh(\varepsilon_P/2) + \delta_{\mathrm{total}}$ — independent of $k$. Therefore $\alpha_a + \tanh(\varepsilon_P/2) + \delta_{\mathrm{total}} \geq \beta_a$ implies $\mathrm{Adv}^{\mathrm{amt}} \geq \beta_a$ for any $k$; the closed-form infeasibility threshold is $\alpha^*_a = \beta_a - \tanh(\varepsilon_P/2) - \delta_{\mathrm{total}}$, and when $\alpha^*_a \leq 0$ the regime is unconditionally infeasible at any $\alpha_a \in [0, 1]$. ∎

These are direct algebraic consequences of the bounds. The paper does not claim a stronger mechanism-specific impossibility result.

---

# Appendix B. Replication instructions {#app-b}

The audit-traceable R derivation script (closed-form bounds, sensitivity tables, Monte Carlo verification) and the Python attack-simulation workbench are distributed alongside the paper under `derivation/` and `simulations/` respectively. The full replication package is published at `https://github.com/AdansBatista/privacy-preserving-attribution`; the tag corresponding to the IACR ePrint version of record is `eprint-v1`.

**Software.** Python 3.11+ (`numpy ≥ 1.24`, `scipy ≥ 1.10`, `pandas ≥ 2.0`, `matplotlib ≥ 3.7`; `pip install -r simulations/requirements.txt`); R 4.4+ (base R only).

**One-command reproduction.**

```bash
# R: closed-form bounds + Monte Carlo verification
Rscript derivation/theorem2-dual-bound.R \
    > derivation/theorem2-dual-bound-output.txt 2>&1

# Python: attack simulation, figures
cd simulations && python simulate_attacks.py
```

The R run regenerates the headline numbers, sensitivity tables, and Monte Carlo verification of [Appendix A.3](#app-a-3) (runtime ~5 seconds). The Python run regenerates Figures 1–3 (runtime ~1–2 minutes at the default Monte Carlo count $N = 20{,}000$).

**Outputs.** `derivation/theorem2-dual-bound-output.txt` (R derivation log); `simulations/results/headline.csv` and `config.json` (Python simulation outputs); `simulations/figures/fig0{1,2,3}*.png` (figures).

**Reproducibility.** Random seeds fixed (R: `set.seed(2026)`; Python: `rng_seed = 2026` in `Config`). All input parameters consolidated at the top of each script. Runs are fully deterministic given the configuration.

**Invitation to re-parameterize.** Three re-parameterizations are invited: (i) alternative auxiliary-information instantiations (replace the headline $\alpha_e, \alpha_a$ values with deployer-specific calibrations); (ii) alternative cohort-variance calibrations (replace $\sigma_T$ with the empirical std-dev of legitimate transactions in the deployer's jurisdiction); (iii) alternative DP mechanisms or composition frameworks (Laplace mechanism, Rényi DP at different orders). Each is a small configuration edit, not a structural rewrite.

---

# References

::: {#refs}
:::
