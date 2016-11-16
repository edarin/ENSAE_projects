setwd("/Users/marcginestet/Desktop/ENSAE/2A/Projet statistiques appliquées/Sorties 14 avril")
getwd()
dir()
library(Synth)

#chargement de la table: attention à PACA ! utiliser csv2 pour les virgules
base <- read.csv2("base1.csv", header=TRUE,sep=";",stringsAsFactors=FALSE)
sink("/Users/marcginestet/Desktop/ENSAE/2A/Projet statistiques appliquées/Sorties 14 avril/Output3.txt", append=TRUE, split=TRUE) 

str(base)

dataprep.out <- dataprep(foo = base, 
 predictors = c("pib", "chomage","agr", "indus_agr", "indus_conso", "indus_auto", "indus_equip", "indus_interm", "energie", "cstrct", "commerce", "transport", "finance.immo", "serv_entr", "serv_part", "social", "pop"),
 predictors.op = "mean",
 time.predictors.prior = 1990:2002,
 special.predictors = list(
 	list("crea_tot.crea_indus", 1993:2002, "mean"),
 	list("crea_indus",1993:2002, "mean"),
 	list("def_indus", 1993:2002, "mean"),
 	list("def_ens.def_indus",1993:2002, "mean"),
	list("rnb", 1994:2002, "mean"),
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
 treatment.identifier = 17,
 controls.identifier = c(2,3,13,14,16,20:22),
 time.optimize.ssr = 1990:2002,
 time.plot = 1990:2013)


# run synth
synth.out <- synth(data.prep.obj = dataprep.out)
# Get result tables
synth.tables <- synth.tab(
dataprep.res = dataprep.out,
synth.res = synth.out)
# results tables:
print(synth.tables)

sink()
# plot results:
# path
png("C:/Users/Edith/Documents/Bahut/ENSAE/Statap/Output/pib3.png")
path.plot(synth.res = synth.out,
dataprep.res = dataprep.out,
Ylab = c("pib par tete"),
Xlab = c("annees"),
#Ylim = c(0,13),
Legend = c("Nord-Pas-de-Calais","Nord-Pas-de-Calais synthétique"),
)
dev.off()
## gaps
png("C:/Users/Edith/Documents/Bahut/ENSAE/Statap/Output/gap3.png")
gaps.plot(synth.res = synth.out,
dataprep.res = dataprep.out,
Ylab = c("gap in real per-capita GDP (1986 USD, thousand)"),
Xlab = c("year"),
#Ylim = c(-1.5,1.5),
)
dev.off()
