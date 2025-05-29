* Fresh start & logging
clear all
set more off
log using "C:\Users\rwb16854\Desktop\NBA_prep.log", replace
ssc install estout, replace
ssc install ivreg2, replace
ssc install ranktest, replace 
eststo clear
* Import & clean
import excel "C:\Users\rwb16854\Downloads\NBA_Data_Processed.xlsx", sheet("combined_ts") firstrow clear
ds, has(type string)
foreach v of varlist _all { 
  capture destring `v', replace ignore(".") 
}
compress
encode Team, gen(team_id)
encode Furthest_RoundReached, gen(round_id)
encode GM_Name, gen(gm_id)
encode GM_LastYear, gen(prev_gm_id)

* Declare panel & create derived vars
tsset team_id Season

* Transformations
gen Gini2 = Gini^2
gen Active_Gini2 = Active_Gini^2
gen ln_Team_Total = ln(Team_Total)
gen ln_Team_Val = ln(Valuation_B_adj)
gen Pct_Inactive = Pct_Dead + Pct_Retained + Pct_CapHold + Pct_ReserveSuspended
gen ln_CapMax_USD = ln(CapMax_USD)

* Centering Key Variables to reduce Multicollinearity 
summarize Gini, meanonly
gen cGini = Gini - r(mean)
gen cGini2 = cGini^2

sum Active_Gini, meanonly
gen cActive_Gini = Active_Gini - r(mean)
gen cActive_Gini2 = cActive_Gini^2

* Building lags on full panel
by team_id (Season), sort: gen L_Gini        = L.Gini
by team_id (Season), sort: gen L_Gini2       = L.Gini2
by team_id (Season), sort: gen L_Active_Gini = L.Active_Gini
by team_id (Season), sort: gen L2_Active_Gini = L2.Active_Gini
by team_id (Season), sort: gen L_GM_Turnover = L.GM_Turnover
by team_id (Season), sort: gen L_Pays_LuxTax = L.Pays_LuxTax
by team_id (Season), sort: gen L_Pct_Active  = L.Pct_Active
by team_id (Season), sort: gen L_Pct_Inactive  = L.Pct_Inactive
by team_id (Season), sort: gen L_Pct_ln_Team_Val  = L.ln_Team_Val
by team_id (Season), sort: gen L_Pct_ln_Team_Total  = L.ln_Team_Total
by team_id (Season), sort: gen L_Injury_Cash_Share  = L.Injury_Cash_Share
by team_id (Season), sort: gen L_ln_CapMax_USD  = L.ln_CapMax_USD
by team_id (Season), sort: gen L_MinJump_Pct  = L.MinJump_Pct
by team_id (Season), sort: gen L_Win_Loss_Pct  = L.Win_Loss_Pct

gen c_Linj = L_Injury_Cash_Share - r(mean)

* Trim to estimation seasons
keep if inlist(Season,2017,2018,2019,2020,2021,2022,2023)
tsset team_id Season

* Save prepared data (optional)
save "NBA_prepared.dta", replace

/////////////////////////////////////////////////////////////////////////////
* DV justification (full panel)

* Create lags of DVs
gen lag_win_pct   = L.Win_Loss_Pct
gen lag_composite = L.Composite_Score

* Predict next season’s Win%
regress Win_Loss_Pct lag_win_pct, vce(cluster team_id)
eststo winpct_pred
regress Win_Loss_Pct lag_composite, vce(cluster team_id)
eststo comp_pred
estimates table winpct_pred comp_pred, stats(r2 rmse)

* OLS + Theory-Driven Controls GINI (All Salary Types)

* Baseline model - Full GINI
regress Composite_Score Gini, vce(robust)
eststo base
estat ic

* Block 1: Resource capacity - Full GINI
regress Composite_Score Gini ln_Team_Total, vce(robust)
eststo block1
testparm ln_Team_Total
estat vif
estat ic

* Block 2: Roster composition - Full GINI
regress Composite_Score Gini ln_Team_Total Pct_Inactive, vce(robust)
eststo block2
testparm Pct_Inactive
estat vif
estat ic

* Block 3: Injury slack - Full GINI
regress Composite_Score Gini ln_Team_Total Pct_Inactive Injury_Cash_Share, vce(robust)
eststo block3
testparm Injury_Cash_Share
estat vif
estat ic

* Block 4: Market power - Full GINI
regress Composite_Score Gini ln_Team_Total Pct_Inactive Injury_Cash_Share Pays_LuxTax, vce(robust)
eststo block4
testparm Pays_LuxTax
estat vif
estat ic

* Block 5: Market valuation - Full GINI
regress Composite_Score Gini ln_Team_Total Pct_Inactive Injury_Cash_Share Pays_LuxTax L.ln_Team_Val, vce(robust)
eststo block5
testparm L.ln_Team_Val
estat vif
estat ic
ovtest


/////////////////////////////////////////////////////////////////////////////
// OLS + Theory-Driven Controls ACTIVE GINI (Only Active Salary Types)

* Baseline model- ACTIVE GINI
regress Composite_Score Active_Gini, vce(robust)
eststo base_act
estat ic

* Block 1: Resource capacity- ACTIVE GINI
regress Composite_Score Active_Gini ln_Team_Total, vce(robust)
eststo block1_act
testparm ln_Team_Total
estat vif
estat ic

* Block 2: Roster composition- ACTIVE GINI
regress Composite_Score Active_Gini ln_Team_Total Pct_Inactive, vce(robust)
eststo block2_act
testparm Pct_Inactive
estat vif
estat ic

* Block 3: Injury slack- ACTIVE GINI
regress Composite_Score Active_Gini ln_Team_Total Pct_Inactive Injury_Cash_Share, vce(robust)
eststo block3_act
testparm Injury_Cash_Share
estat vif
estat ic

* Block 4: Market power- ACTIVE GINI
regress Composite_Score Active_Gini ln_Team_Total Pct_Inactive Injury_Cash_Share Pays_LuxTax, vce(robust)
eststo block4_act
testparm Pays_LuxTax
estat vif
estat ic

* Block 5: Market valuation- ACTIVE GINI
regress Composite_Score Active_Gini ln_Team_Total Pct_Inactive Injury_Cash_Share Pays_LuxTax L.ln_Team_Val, vce(robust)
eststo block5_act
testparm L.ln_Team_Val
estat vif
estat ic
ovtest


/////////////////////////////////////////////////////////////////////////////
// FE-IV Quadratic Gini → Composite Score (ACTIVE GINI)

* -------------------------------------------------------------------
* First-Stage Regressions for IV Models
* -------------------------------------------------------------------
* Clear previous stored estimates

* IV1- Gini IV- Basic IV
regress Active_Gini L.ln_CapMax_USD L.ln_Team_Total MinJump_Pct, vce(cluster team_id)
eststo iv1_first
* IV2- Gini IV- Drop L.MinJump_Pct
regress Active_Gini L.ln_CapMax_USD L.ln_Team_Total, vce(cluster team_id)
eststo iv2_first
* IV3- IV with lagged dep var
regress Active_Gini L.ln_CapMax_USD L.ln_Team_Total, vce(cluster team_id)
eststo iv3_first
* IV4- IV Quadratic
regress cActive_Gini L.ln_CapMax_USD L.ln_Team_Total, vce(cluster team_id)
eststo iv4_first


/////////////////////////////////////////////////////////////////////////////
* Second-Stage IV Regressions

* Gini IV- Basic IV
ivreg2 Composite_Score ln_Team_Total Pct_Inactive Injury_Cash_Share (cActive_Gini= L.ln_CapMax_USD L.MinJump_Pct L.Pays_LuxTax L.GM_Turnover), cluster(team_id) first
eststo iv_basic

* Gini IV- Drop L.MinJump_Pct
ivreg2 Composite_Score ln_Team_Total Pct_Inactive Injury_Cash_Share (cActive_Gini= L.ln_CapMax_USD L.Pays_LuxTax), cluster(team_id) first
eststo iv_1

* IV with lagged dep var
ivreg2 Composite_Score L.Composite_Score ln_Team_Total Pct_Inactive Injury_Cash_Share (cActive_Gini = L.ln_CapMax_USD L.Pays_LuxTax), cluster(team_id) first
eststo iv_lagdep

* IV Quadratic
ivreg2 Composite_Score ln_Team_Total Pct_Inactive Injury_Cash_Share (cActive_Gini cActive_Gini2 = L.ln_CapMax_USD L.Pays_LuxTax), cluster(team_id) first
eststo iv_quad

///////////////////////////////////////////////////////////////////////////////
// Alternative DVs: Win_Loss_Pct IV models

ivreg2 Win_Loss_Pct ln_Team_Total Pct_Inactive Injury_Cash_Share (cActive_Gini= L.ln_CapMax_USD L.MinJump_Pct L.Pays_LuxTax L.GM_Turnover), cluster(team_id) first
eststo iv_basic_wlp

ivreg2 Win_Loss_Pct ln_Team_Total Pct_Inactive Injury_Cash_Share (cActive_Gini= L.ln_CapMax_USD L.Pays_LuxTax), cluster(team_id) first
eststo iv_1_wlp

ivreg2 Win_Loss_Pct L.Win_Loss_Pct ln_Team_Total Pct_Inactive Injury_Cash_Share (cActive_Gini = L.ln_CapMax_USD L.Pays_LuxTax), cluster(team_id) first
eststo iv_lagdep_wlp

ivreg2 Win_Loss_Pct ln_Team_Total Pct_Inactive Injury_Cash_Share (cActive_Gini cActive_Gini2 = L.ln_CapMax_USD L.Pays_LuxTax), cluster(team_id) first
eststo iv_quad_wlp


///////////////////////////////////////////////////////////////////////////////
// Probit Model for Round Indicators

tostring Furthest_RoundReached, replace force
replace Furthest_RoundReached = "" if Furthest_RoundReached == "."

gen round_ord = .
replace round_ord = 1 if Furthest_RoundReached == "Conference First Round"
replace round_ord = 2 if Furthest_RoundReached == "Conference Semifinals"
replace round_ord = 3 if Furthest_RoundReached == "Conference Finals"
replace round_ord = 4 if Furthest_RoundReached == "Finals"
replace round_ord = 0 if missing(round_ord)
label define round_lbl 0 "DNQ" 1 "R1" 2 "R2" 3 "R3" 4 "Finals"
label values round_ord round_lbl

preserve
collapse (mean) Injury_Cash_Share Pct_Inactive ln_Team_Total, by(team_id Season round_ord)
oprobit round_ord c.Injury_Cash_Share c.Pct_Inactive ln_Team_Total i.Season, vce(cluster team_id)
eststo probit_round
margins, dydx(*) atmeans
restore

///////////////////////////////////////////////////////////////////////////////
// Salary-depth × Injury Interaction

summarize top3_share, meanonly
gen c_top3 = top3_share - r(mean)

summarize Injury_Cash_Share, meanonly
gen c_inj  = Injury_Cash_Share - r(mean)

gen c_top3_inj = c_top3*c_inj
gen year_trend = Season-2016

*1. Full-sample pooled OLS
reg Composite_Score ln_Team_Total Pct_Inactive c_top3 c_inj c_top3_inj year_trend, vce(cluster team_id)
eststo interact_full
estat vif

*2. Contender subsample
preserve
keep if L.Win_Loss_Pct >= .50
reg Composite_Score ln_Team_Total Pct_Inactive c_top3 c_inj c_top3_inj year_trend, vce(cluster team_id)
eststo interact_contender
estat vif
restore

*3. Robustness DV = Win%
reg Win_Loss_Pct ln_Team_Total Pct_Inactive c_top3 c_inj c_top3_inj year_trend, vce(cluster team_id)
eststo interact_wlp
estat vif

*4. Two-way FE
xtset team_id Season
xtreg Composite_Score ln_Team_Total Pct_Inactive c_top3 c_inj c_top3_inj i.Season, fe vce(cluster team_id)
eststo interact_fe

* Export all OLS-GINI results to Desktop
esttab base block1 block2 block3 block4 block5 ///
    using "C:\Users\rwb16854\Desktop\ols_controls_gini.rtf", ///
    replace se star(* 0.10 ** 0.05 *** 0.01) ///
    stats(r2 r2_a aic N, labels("R-squared" "Adj. R-squared" "AIC" "Observations"))

* Export all OLS-ACTIVE GINI results to Desktop
esttab base_act block1_act block2_act block3_act block4_act block5_act ///
    using "C:\Users\rwb16854\Desktop\ols_controls_act.rtf", ///
    replace se star(* 0.10 ** 0.05 *** 0.01) ///
    stats(r2 r2_a aic N, labels("R-squared" "Adj. R-squared" "AIC" "Observations"))

* Export all 1st stages in one table
esttab iv1_first iv2_first iv3_first iv4_first using ///
    "C:\Users\rwb16854\Desktop\FirstStage_AllIVs.rtf", ///
    replace se star(* 0.10 ** 0.05 *** 0.01) ///
    stats(r2 r2_a N, labels("R-squared" "Adj. R-squared" "Observations")) ///
    title("First-Stage Regressions for IV Models") ///
    mtitles("IV1" "IV2" "IV3" "IV4") ///
    varlabels(L.ln_CapMax_USD "Lagged Cap" ///
              L.ln_Team_Total "Lagged Payroll" ///
              MinJump_Pct "Min Salary Jump %")


* Export all Composite IV results to Desktop
esttab iv_basic iv_1 iv_lagdep iv_quad ///
    using "C:\Users\rwb16854\Desktop\iv_results_COMPOSITE.rtf", ///
    replace se star(* 0.10 ** 0.05 *** 0.01) ///
    stats(r2 r2_a aic N, labels("R-squared" "Adj. R-squared" "AIC" "Observations"))
	
* Export all WIN_LOSS_ PCT IV results to Desktop
esttab iv_basic_wlp iv_1_wlp iv_lagdep_wlp iv_quad_wlp ///
    using "C:\Users\rwb16854\Desktop\iv_results_WINPCT.rtf", ///
	replace se star(* 0.10 ** 0.05 *** 0.01) ///
	stats(r2 r2_a aic N, labels("R-squared" "Adj. R-squared" "AIC" "Observations"))

* Export interaction results to Desktop
esttab interact_full interact_contender interact_wlp interact_fe ///
    using "C:\Users\rwb16854\Desktop\interaction_results.rtf", ///
    replace se star(* 0.10 ** 0.05 *** 0.01) ///
	stats(r2 r2_a aic N, labels("R-squared" "Adj. R-squared" "AIC" "Observations"))
	
* Export probit results to Desktop
esttab probit_round ///
    using "C:\Users\rwb16854\Desktop\probit_round.rtf", ///
	replace se star(* 0.10 ** 0.05 *** 0.01) ///
	stats(r2_p df_m) label
	
	
log close
