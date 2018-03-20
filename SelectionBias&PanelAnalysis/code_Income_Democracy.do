ssc install outtex, replace
ssc install estout, replace
clear
import excel using /Users/noemiehaouzi/Desktop/ENSAE2A/S2/Econometrie2/
ProjetEcono2/Base_econo.xlsx, sheet(Obs) firstrow
/*---------------------GENERATION DES VARIABLES---------------------*/
///Gnration des variables principales
tsset code_numeric year_numeric
sort code_numeric year_numeric
tab year, gen (yr)
tab code, gen(cd)
gen dem = fhpolrigaug
gen y = lrgdpch
destring dem y, dpcomma replace
// Variables de contrles
gen age1 = age_veryyoung
gen age2 = age_young
gen age3 = age_midage
gen age4 = age_old
gen age5 = age_veryold
gen educ = education
gen l_dem = L.dem
gen l_y =L.y
foreach var of varlist l_dem l_y dem yr* {
bysort code : egen mx = mean (‘var’)
gen w‘var’ = ‘var’ - mx
drop mx
}
sort code_numeric year_numeric
gen d_ldem=d.l_dem
gen d_dem=d.dem
gen d_ly=d.l_y
sort code_numeric year_numeric
gen l2_y =l2.y
gen dl2_y = d.l2_y
foreach var of varlist age1 age2 age3 age4 age5 educ lpop yr*{
gen d‘var’ = d.‘var’
}
gen l2_nsave = l2.nsave
gen dl2_nsave = d.l2_nsave
gen
gen
gen
gen
lworldinc = l.worldincome
l2worldinc = l2.worldincome
dlworldinc =d.lworldinc
dl2worldinc =d.l2worldinc
xtset code_numeric year_numeric
/*----------------------------------GRAPHES----------------------------------*/
//Graph de l’effet brut
egen moy_dem = mean(dem), by(code)
egen moy_y = mean(y), by(code)
reg moy_dem moy_y
twoway (scatter moy_dem moy_y, msymbol(none)
mlabel(code) mlabsize(tiny))
(lfit moy_dem moy_y, clcolor(black)), ytitle("Indice de dmocratie")
xtitle("Log PIB par tte (donnes Madison)")
title("Effet brut du PIB par tte sur la dmocratie")
subtitle("Analyse transversale (cross-section) de 1950 2000")
legend(off) xscale(r(6 10.6))
reg dem y
twoway (scatter dem y, msymbol(none) mlabel(code) mlabsize(tiny)) (lfit dem y,
clcolor(black)),
ytitle("Indice de dmocratie") xtitle("Log PIB par tte (donnes Madison)")
title("Effet brut du PIB par tte sur la dmocratie")
subtitle("Analyse transversale de 1950 2000") legend(off) xscale(r(6 10.6))
histogram dem, title("Distribution du niveau de dmocratie") ytitle("")
xtitle("")
subtitle("Entre 1950 et 2000") color(gray)
/*----------------------------------POOLED OLS--------------------------------*/
eststo: reg dem l_dem l_y yr*
age1 age2 age3 age4 age5 educ lpop,
cluster(code)
label variable dem "démocratie(t)"
label variable l_dem "démocratie(t-1)"
label variable l_y "pib(t-1)"
outtex, labels level plain detail legend title("Estimation par MCO empils")
/*----------- PANER AVEC VARIABLES INSTRUMENTALES POUR Y(t-1)----------*/
//////////////////////////Instrument : Yt
//Instrument = y(t-2) F=10,93
eststo: ivreg d_dem (d_ly = l2_y) d_ldem yr*
dlpop, first robust
age1 age2 age3 age4 age5 deduc
//////////////////////////Instrument : savings
//instrument nsave(t-2) F=9,29
eststo: ivreg d_dem (d_ly = l2_nsave) d_ldem yr*
deduc dlpop, first robust
age1 age2 age3 age4 age5
///////////////////// Plusieurs instruments
//Instruments : nsave(t-2) et y(t-2) F=10,29
eststo : ivreg d_dem (d_ly = l2_nsave l2_y) d_ldem yr*
age5 deduc dlpop, first robust

age1 age2 age3 age4esttab
using "/Users/noemiehaouzi/Desktop/ENSAE2A/S2/Econometrie2/ProjetEcono2/
tableau.tex" , se r2 title(Comparaison des modeles\label{tabcomp})
nonumbers nostar replace booktabs mtitle("VI 1" "VI 2" "VI 3")
//SARGAN TEST
ivregress 2sls d_dem (d_ly = l2_nsave l2_y) d_ldem yr*
age5 deduc dlpop, robust
estat overid
age1 age2 age3 age4
/****************************** MODELE DE SELECTION **************************/
clear
import excel using /Users/noemiehaouzi/Desktop/ENSAE2A/S2/Econometrie2/
ProjetEcono2/Base_econoV2.xlsx, sheet(1960) firstrow
gen dem = fhpolrigaug
gen y = lrgdpch
destring dem y, dpcomma replace
// Variables de contrles
gen age1 = age_veryyoung
gen age2 = age_young
gen age3 = age_midage
gen age4 = age_old
gen age5 = age_veryold
gen educ = education
//regression de comparaison
reg dem y lpop
outtex, labels level plain detail legend title("Estimation par MCO")
//>> biai du 2SLS car tous les pays ne sont pas pris en compte
// Donc modle de slection
xi : heckman dem y lpop, select(obs_dem = age5 lpop y) twostep
outtex, labels level plain detail legend title("Estimation par Heckit")
/* instrument moins significatif*/
xi : heckman dem y, select(obs_dem = age1 y) twostep
xi : heckman dem y, select(obs_dem = age1 age5 y) twostep
