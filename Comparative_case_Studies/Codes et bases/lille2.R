setwd("/Users/marcginestet/Desktop/ENSAE/2A/Projet statistiques appliquées/Sorties 14 avril")
getwd()
dir()
library(Synth)
library(rgenoud)

#chargement de la table: attention à PACA ! utiliser csv2 pour les virgules
base <- read.csv2("base1.csv", header=TRUE,sep=";",stringsAsFactors=FALSE)
# -> à mettre pour avoir des sorties sink("C:/Users/Edith/Documents/Bahut/ENSAE/Statap/Output/placebo_geo_pib.txt", append=TRUE, split=TRUE) 

str(base)

dataprep.out <- dataprep(foo = base, 
 predictors = c("pib","va_tot","pop", "chomage"),
 predictors.op = "mean",
 time.predictors.prior = 1990:2002,
 special.predictors = list(
 	list("crea_tot.crea_indus", 1993:2002, "mean"),
 	list("crea_indus",1993:2002, "mean"),
 	list("def_indus", 1993:2002, "mean"),
 	list("def_ens.def_indus",1993:2002, "mean"),
	#list("rnb", 1994:2002, "mean"),
	list("offre_emploi", 1996:2002, "mean"),
	list("dipl_auc",c(1990,1999), "mean"),
	list("dipl_bepc",c(1990,1999), "mean"),
	list("dipl_cep",c(1990,1999), "mean"),
	list("dipl_cap_cep",c(1990,1999), "mean"),
	list("dipl_bac",c(1990,1999), "mean"),
	list("dipl_sup",c(1990,1999), "mean")),
 dependent = "pib",
 unit.variable = "num_reg",
 unit.names.variable= "regions",
 time.variable = "annees",
 treatment.identifier = "Nord - Pas-de-Calais",
 controls.identifier = c("Alsace","Aquitaine","Auvergne","Basse-Normandie","Bourgogne","Bretagne","Centre","Franche-Comte","Languedoc-Roussillon","Limousin","Midi-Pyrenees","Pays de la Loire","Poitou-Charentes","PACA","Rhone-Alpes"
 ),
 time.optimize.ssr = 1990:2002,
 time.plot = 1990:2008)


# run synth
synth.out <- synth(data.prep.obj = dataprep.out, method= "BFGS", genoud= FALSE)

# Get result tables
synth.tables <- synth.tab(
dataprep.res = dataprep.out,
synth.res = synth.out)
# results tables:
print(synth.tables)

#Calcul du MSPE

mspe_pre <- mean((dataprep.out$Y1plot[1:14] - (dataprep.out$Y0plot[1:14,] %*% synth.out$solution.w))^2)
mspe_post <- mean((dataprep.out$Y1plot[15:19] - (dataprep.out$Y0plot[15:19,] %*% synth.out$solution.w))^2)
mspe_pre
mspe_post
rapport_mspe <- mspe_post/mspe_pre
rapport_mspe
# -> à mettre pour avoir des sorties sink()

#plot results:
#path
#-> à mettre pour avoir des sorties  
png("/Users/marcginestet/Desktop/ENSAE/2A/Projet statistiques appliquées/Sorties 14 avril/Chômage variation, PIB niveau/Chomage_NPDC_chomagevar2.png")
path.plot(synth.res = synth.out,
dataprep.res = dataprep.out,
Ylab = c("Chômage"),
Xlab = c("annees"),
#Ylim = c(0,13),
Legend = c("NPDC","NPDC synthétique"),
)
dev.off()
# -> à mettre pour avoir des sorties dev.off()
#gaps
png("/Users/marcginestet/Desktop/ENSAE/2A/Projet statistiques appliquées/Sorties 14 avril/Chômage variation, PIB niveau/Chomage_gap_NPDC_chomagevar2.png")
gaps.plot(synth.res = synth.out,
dataprep.res = dataprep.out,
Ylab = c("Écart de Chomage"),
Xlab = c("Années"),
#Ylim = c(-1.5,1.5),
)
dev.off()

##Placebo
store <- matrix(NA,length(1990:2008),17)

for(iter in 2:18)
 {

dataprep.out <- dataprep(foo = base, 
 predictors = c("pib", "chomage",
	"agr", "indus_agr", "indus_conso", "indus_auto", "indus_equip", "indus_interm",
	"energie", "cstrct", "commerce", "transport", "finance.immo", "serv_entr", "serv_part", "social",
	"pop"),
 predictors.op = "mean",
 time.predictors.prior = 1990:2002,
 special.predictors = list(
 	list("crea_tot.crea_indus", 1993:2002, "mean"),
	#list("crea_tot", 1993:2002, "mean"),
 	list("crea_indus",1993:2002, "mean"),
 	list("def_indus", 1993:2002, "mean"),
 	list("def_ens.def_indus",1993:2002, "mean"),
	#list("rnb", 1994:2002, "mean"),
	list("offre_emploi", 1996:2002, "mean"),
	list("dipl_auc",c(1990,1999), "mean"),
	list("dipl_bepc",c(1990,1999), "mean"),
	list("dipl_cep",c(1990,1999), "mean"),
	list("dipl_cap_cep",c(1990,1999), "mean"),
	list("dipl_bac",c(1990,1999), "mean"),
	list("dipl_sup",c(1990,1999), "mean")),
 dependent = "pib",
 unit.variable = "num_reg",
 unit.names.variable= "regions",
 time.variable = "annees",
 treatment.identifier = "Nord - Pas-de-Calais",
 controls.identifier = c("Aquitaine","Auvergne", 
				"Languedoc-Roussillon","Limousin","Midi-Pyrénées",
				"Poitou-Charentes","PACA","Rhône-Alpes", "Basse-Normandie", 
				"Bourgogne", "Alsace","Franche-Comté", "Centre", "Pays de la Loire",		
				"Bretagne"),
 time.optimize.ssr = 1990:2002,
 time.plot = 1990:2008)
