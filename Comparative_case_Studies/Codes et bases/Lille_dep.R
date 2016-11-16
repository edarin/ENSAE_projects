setwd("/Users/marcginestet/Desktop/ENSAE/2A/Projet statistiques appliquées/Sortie départementales")
getwd()
dir()
library(Synth)
library(rgenoud)

#chargement de la table: attention à PACA ! utiliser csv2 pour les virgules
base <- read.csv2("base_dep_form.csv", header=TRUE,sep=";",stringsAsFactors=FALSE)
# -> à mettre pour avoir des sorties sink("C:/Users/Edith/Documents/Bahut/ENSAE/Statap/Output/placebo_geo_pib.txt", append=TRUE, split=TRUE) 

str(base)


dataprep.out <- dataprep(foo = base, 
 predictors = c("emploi_salarie","emploi_salarie_hebergement_restau","emploi_salarie_indus","emploi_salarie_tertiaire_marchand","chomage","pop_dep"),
 predictors.op = "mean",
 time.predictors.prior = 1990:2002,
 special.predictors = list(
 	list("nuitees", 2002, "mean"),
 	list("crea_entreprise", 2000:2002, "mean"),
 	list("def_entreprise",1993:2002, "mean"),
 	list("offre_emploi_durable", 1996:2002, "mean"),
 	list("rev_imp", 1998:2002, "mean")),
 dependent = "nuitees",
 unit.variable = "num_dep",
 unit.names.variable= "dep",
 time.variable = "annees",
 treatment.identifier = "Nord",
 controls.identifier = c("Ain","Aisne","Allier","Alpes-de-Haute-Provence","Hautes-Alpes","Alpes-Maritimes","Ardeche","Ardennes","Ariege","Aube","Aude","Aveyron","Bouches-du-Rhone","Calvados","Cantal","Charente","Charente-Maritime","Cher","Correze","Cote-d'Or","Cotes-d'Armor","Creuse","Dordogne","Doubs","Drome","Eure","Eure-et-Loir","Finistere","Gard","Haute-Garonne","Gers","Gironde","Herault","Ille-et-Vilaine","Indre","Indre-et-Loire","Isere","Jura","Landes","Loir-et-Cher","Loire","Haute-Loire","Loire-Atlantique","Loiret","Lot","Lot-et-Garonne","Lozere","Maine-et-Loire","Manche","Marne","Haute-Marne","Mayenne","Meurthe-et-Moselle","Meuse","Morbihan","Moselle","Nievre","Oise","Orne","Puy-de-Dome","Pyrenees-Atlantiques","Hautes-Pyrenees","Pyrenees-Orientales","Bas-Rhin","Haut-Rhin","Rhone","Haute-Saone","Saone-et-Loire","Sarthe","Savoie","Haute-Savoie","Paris","Seine-Maritime","Seine-et-Marne","Yvelines","Deux-Sevres","Somme","Tarn","Tarn-et-Garonne","Var","Vaucluse","Vendee","Vienne","Haute-Vienne","Vosges","Yonne","Territoire de Belfort","Essonne","Hauts-de-Seine","Seine-Saint-Denis","Val-de-Marne"
 ),
 time.optimize.ssr = 1999:2002,
 time.plot = 1999:2005)

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
png("/Users/marcginestet/Desktop/ENSAE/2A/Projet statistiques appliquées/Sortie départementales/nuitees.png")
path.plot(synth.res = synth.out,
dataprep.res = dataprep.out,
Ylab = c("Nuitées"),
Xlab = c("annees"),
#Ylim = c(0,13),
Legend = c("Nord","Nord synthétique"),
)
dev.off()
# -> à mettre pour avoir des sorties dev.off()
#gaps
png("//Users/marcginestet/Desktop/ENSAE/2A/Projet statistiques appliquées/Sortie départementales/gap nuitees.png")
gaps.plot(synth.res = synth.out,
dataprep.res = dataprep.out,
Ylab = c("Écart de Nuitées"),
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
