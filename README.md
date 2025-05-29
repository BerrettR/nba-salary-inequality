# NBA Salary Inequality & Team Performance

## Project Overview

This repository examines how NBA intra-team salary structures influence team performance over the 2017-18 through 2023-24 seasons (210 team-season observations). By measuring pay dispersion among active players with an *Active Gini* and mapping it against a new *Composite Score*, the study quantifies whether concentrating salary on a few stars yields on-court benefits.

**Motivation:** NBA front offices allocate payroll between star talent and role players under a hard cap. This research asks: *Do teams that pay top players disproportionately more than role players achieve better results?* Read the full paper in `docs/berrett-nba-competitive-roster-salary-inequality.pdf`.

---

## Repository Structure

```bash
nba-salary-inequality/
├── data/
│   ├── local-berrett-nba-data.xlsx      # Raw inputs: cash salaries, Adjusted Net Rating, VORP, valuations, GM data
│   └── NBA_Data_Processed.xlsx          # Cleaned panel data (sheet: combined_ts)
├── docs/
│   └── berrett-nba-competitive-roster-salary-inequality.pdf  # Final research paper
├── scripts/
│   └── nba-data-analysis.Rmd            # R: merges raw inputs, integrity checks, exports combined_ts
├── do/
│   └── nba-analysis.do                  # Stata: filters panel, generates lags, computes Ginis, runs models
├── logs/
│   └── nba-prep.log                     # Stata console log from nba-analysis.do (Season 2017–2023)
├── results/
│   ├── tables/                          # Regression tables (HTML, CSV)
│   └── figures/                         # Visualizations (PNG)
└── README.md                            # You are here
```

---

## Data Sources & Integration

1. **Data Collection**

   * **Salaries:** Spotrac for player cash salaries by contract type (active, retained, dead cap, cap holds).
   * **Performance Metrics:** Basketball-Reference via Stathead for player VORP and team Adjusted Net Rating.
   * **Valuations:** Forbes NBA team valuations (2016–2023) downloaded from Forbes.com archives.
   * **GM Histories:** RealGM and Basketball-Reference for general manager tenure and turnover dates.

2. **Panel Preparation**
   Raw data are merged on team and season in R (`scripts/nba-data-analysis.Rmd`), cleaned, and saved as `combined_ts` in `NBA_Data_Processed.xlsx`. The Stata do-file (`do/nba-analysis.do`) imports `combined_ts`, restricts seasons 2017–2023, constructs lagged variables, and flags GM turnover and luxury-tax status.

3. **Gini Computations & Modeling**

   * **Active Gini**: Gini coefficient of active players’ share of cash payroll.
   * **Overall Gini**: Gini across all contract types (robustness check).
     Models include OLS (with team fixed effects), IV (2SLS), quadratic tests, ordered probit, interactions, and lagged DV specifications.

---

## Key Metrics

| Variable            | Definition                                                                                                    |
| ------------------- | ------------------------------------------------------------------------------------------------------------- |
| **Composite Score** | Rescale Adjusted Net Rating and team-summed VORP to \[0,1] (min–max) then multiply (0 = worst, 1 = best).     |
| **Active Gini**     | Gini coefficient of each active player’s share of cash salary (0 = perfect equality, 1 = extreme inequality). |
| **Overall Gini**    | Gini across all contract types (active, retained, dead-cap, cap holds).                                       |
| **Win–Loss %**      | Regular-season win percentage (alternative DV for robustness).                                                |

---

## Controls & Instruments

**Controls** (all lagged one season except where noted):

* `ln_Team_Total`        : ln(prior-season total cash payroll)
* `Pct_Inactive`         : Share of payroll tied up in non-playing contracts
* `Injury_Cash_Share`    : Share of payroll paid to injured players
* `Luxury_Tax`           : Dummy = 1 if team exceeded luxury-tax threshold
* `ln_Franchise_Valuation`: ln(prior-season Forbes valuation)
* `GM_Turnover`          : Dummy = 1 if general manager changed

**Instruments** for Active Gini (2SLS):

* `ln_CapMax_USD` (salary-cap ceiling, pre-season)
* `ln_Team_Total` (prior-season payroll)
* `MinJump_Pct` (minimum-salary room) – dropped in IV2 for strength

---

## Methodology

* **Sample:** 30 NBA teams, post-2017 CBA era (2017-18 to 2023-24), final estimation on 210 obs.
* **OLS + Team FE:** Baseline effect of Active Gini on Composite Score.
* **IV (2SLS):** Instrument Active Gini with lagged cap ceiling & payroll; preferred IV2 yields coef = 0.902 (p < .05).
* **Quadratic Spec:** Tests inverted-U pay-dispersion effects.
* **Ordered Probit:** Models playoff-round advancement as ordered categories.
* **Interactions & Dynamics:** Tests Active Gini × Luxury Tax and Active Gini × GM Turnover; includes lagged Composite Score.
* **Robustness:** Uses Win–Loss %, Overall Gini, CBA pre-/post-subsamples.
* **Inference:** SEs clustered by team; diagnostics include AIC/BIC and VIFs (< 2).

---

## Key Findings

1. **OLS Baseline:** A one-unit increase in Active Gini predicts a 0.547-point rise in Composite Score (p < .01, R² = 0.0449).
2. **Preferred OLS (Model 5):** Controlling for payroll, inactive/injury share, and luxury tax, Active Gini adds 0.345 points (p < .05; AIC = –219.3).
3. **Causal IV (IV2):** Instrumented Active Gini yields 0.902 (p < .05), confirming a causal link.
4. **Performance Persistence:** Lagged Composite Score coefficient ≈ 0.413 (p < .01), highlighting momentum effects.
5. **Non-productive Payroll:** A 0.10 increase in Pct\_Inactive or Injury Cash Share reduces Composite Score by \~0.06 (p < .01).
6. **Nonlinear Test:** Quadratic specification did not yield precise estimates due to instrument limitations.
7. **Robustness:** Findings hold when using Win–Loss % and Overall Gini, as well as across CBA subsamples.

For full tables and detailed discussion, see `results/tables/` and the paper’s conclusion in `docs/berrett-nba-competitive-roster-salary-inequality.pdf`.

---

Thank you for exploring this project!
