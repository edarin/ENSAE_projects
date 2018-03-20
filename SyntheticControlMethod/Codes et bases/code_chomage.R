setwd("C:/Users/Louise/Documents/AENSAE/ProjetStatap/code")
getwd()
dir()
library(Synth)
#library(rgenoud)

#chargement de la table: attention à PACA ! utiliser csv2 pour les virgules
base <- read.csv2("mabase.csv", header=TRUE,sep=";",stringsAsFactors=FALSE)

#sink("C:/Users/Louise/Documents/AENSAE/ProjetStatap/sorties/modele_pib/chomage_depuis_1994_avec_pib_evolution.txt", append=FALSE, split=TRUE) 

#str(base)

dataprep.out <- dataprep(foo = base, 
 predictors = c("pib", "chomage","pop","va_tot"),
 predictors.op = "mean",
 time.predictors.prior = 1990:2002,
 special.predictors = list(

 	list("crea_tot.crea_indus", 1993:2002, "mean"),
 	list("crea_indus",1993:2002, "mean"),
	#list("crea_tot",1993:2002, "mean"),
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
 dependent = "chomage",
 unit.variable = "num_reg",
 unit.names.variable= "regions",
 time.variable = "annees",
 treatment.identifier = "Nord - Pas-de-Calais",
 controls.identifier = c("Alsace","Aquitaine","Auvergne","Basse-Normandie","Bourgogne","Bretagne","Centre","Franche-Comte",
				"Languedoc-Roussillon","Limousin","Midi-Pyrenees","Pays de la Loire","Poitou-Charentes","PACA","Rhone-Alpes"),
 time.optimize.ssr = 1994:2002,
 time.plot = 1994:2008)




 
# run synth
synth.out <- synth(data.prep.obj = dataprep.out, method= "BFGS")

# Get result tables
synth.tables <- synth.tab(
dataprep.res = dataprep.out,
synth.res = synth.out)
# results tables:
print(synth.tables)

#Calcul du MSPE

mspe_pre <- mean((dataprep.out$Y1plot[1:11] - (dataprep.out$Y0plot[1:11,] %*% synth.out$solution.w))^2)
mspe_post <- mean((dataprep.out$Y1plot[11:15] - (dataprep.out$Y0plot[11:15,] %*% synth.out$solution.w))^2)
mspe_pre
mspe_post

# rapport 

rapport <- mspe_post/mspe_pre
rapport

#sink()

gaps_2004 <- (dataprep.out$Y1plot[11] - (dataprep.out$Y0plot[11,] %*% synth.out$solution.w))/(dataprep.out$Y0plot[11,] %*% synth.out$solution.w)
gaps_2004
gaps_2008 <- (dataprep.out$Y1plot[15] - (dataprep.out$Y0plot[15,] %*% synth.out$solution.w))/(dataprep.out$Y0plot[15,] %*% synth.out$solution.w)
gaps_2008


# moyenne du gap sur la période 2004-2008

gaps_moy <- mean((dataprep.out$Y1plot[11:15] - (dataprep.out$Y0plot[11:15,] %*% synth.out$solution.w))/(dataprep.out$Y0plot[11:15,] %*% synth.out$solution.w)*100)
gaps_moy

# plot results:
# path
# -> à mettre pour avoir des sorties
png("C:/Users/Louise/Documents/AENSAE/ProjetStatap/sorties/modele_pib/chomage_depuis_1994_avec_pib-evolution.png")
path.plot(synth.res = synth.out,
dataprep.res = dataprep.out,
Ylab = c("Chômage (base 2010)"),
Xlab = c("Annees"),
#Ylim = c(0,13),
Legend = c("Nord-Pas-de-Calais","Nord-Pas-de-Calais synthetique"),
)
dev.off()
## gaps
#png("C:/Users/Edith/Documents/Bahut/ENSAE/Statap/Output/gap_chomage_depuis_1994_avec_pib-evolution.png")
gaps.plot(synth.res = synth.out,
dataprep.res = dataprep.out,
Ylab = c("Ecart entre taux de chômage réel du NPD et taux de chomage synthétique "),
Xlab = c("Années"),
#Ylim = c(-1.5,1.5),
)
dev.off()

##Placebo
basered <- read.csv2("basered.csv", header=TRUE,sep=";",stringsAsFactors=FALSE)
str(basered)
store <- matrix(NA,length(1990:2008),16)

colnames(store) <- unique(basered$regions)[-1]

for (iter in 1:16)
{
dataprep.out <- dataprep(foo = basered, 
 predictors = c("pib", "chomage","pop","va_tot"),
 predictors.op = "mean",
 time.predictors.prior = 1990:2002,
 special.predictors = list(
 	list("crea_tot.crea_indus", 1993:2002, "mean"),
 	list("crea_indus",1993:2002, "mean"),
	#list("crea_tot",1993:2002, "mean"),
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
 unit.variable = "num",
 unit.names.variable= "regions",
 treatment.identifier = iter,
 time.variable = c("annees"),
 controls.identifier = c(2:16)[-iter+1],
 time.optimize.ssr = c(1990:2002),
 time.plot = 1990:2008)


# run synth
synth.out <- synth(
                   data.prep.obj = dataprep.out,
                   method = "BFGS"
                   )

# store gaps
store[,iter-1] <- dataprep.out$Y1plot - (dataprep.out$Y0plot %*% synth.out$solution.w)
}

# now do figure
data <- store
rownames(data) <- 1990:2008

# Set bounds in gaps data
gap.start     <- 1
gap.end       <- nrow(data)
years         <- 1990:2008
gap.end.pre  <- which(rownames(data)=="2003")

#  MSPE Pre-Treatment
mse        <-             apply(data[ gap.start:gap.end.pre,]^2,2,mean)
basered.mse <- as.numeric(mse[16])
# Exclude states with 5 times higher MSPE than basque
#data <- data[,mse<5*basque.mse]
Cex.set <- .75

# Plot
plot(years,data[gap.start:gap.end,which(colnames(data)=="Nord - Pas-de-Calais")],
     ylim=c(-1000,1000),
     xlab="annees",
     xlim=c(1990,2008),
     ylab="ecart entre PIB réel et PIB synthetique",
     type="l",lwd=2,col="black",
     xaxs="i",yaxs="i"
)

# Add lines for control states
for (i in 1:ncol(data)) { lines(years,data[gap.start:gap.end,i],col="gray") }

## Add Basque Line
lines(years,data[gap.start:gapdata.end,which(colnames(data)=="Nord - Pas-de-Calais")],lwd=2,col="black")



#placebo sensitivete, sur variable d'intéret PIB avec date 2003


dataprep.out <- dataprep(foo = base, 
 predictors = c("pib","pop","va_tot"),
 predictors.op = "mean",
 time.predictors.prior = 1990:2002,
 special.predictors = list(
	
 	list("crea_tot.crea_indus", 1993:2002, "mean"),
 	list("crea_indus",1993:2002, "mean"),
	#list("crea_tot",1993:2002, "mean"),
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
 dependent = "chomage",
 unit.variable = "num_reg",
 unit.names.variable= "regions",
 time.variable = "annees",
 treatment.identifier = "Nord - Pas-de-Calais",
 controls.identifier = c("Alsace","Aquitaine","Auvergne","Basse-Normandie","Bourgogne","Bretagne","Centre","Franche-Comté",
				"Languedoc-Roussillon","Limousin","Midi-Pyrénées","Pays de la Loire","Poitou-Charentes","PACA","Rhône-Alpes"),
 time.optimize.ssr = 1990:2002,
 time.plot = 1990:2008)


# run synth
synth.out <- synth(data.prep.obj = dataprep.out, method= "BFGS" )

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

# rapport 

rapport <- mspe_post/mspe_pre
rapport

sink()


# plot results:
# path
# -> à mettre pour avoir des sorties  png("C:/Users/Louise/Documents/AENSAE/ProjetStatap/sorties/modele_pib/pib.pgn")
path.plot(synth.res = synth.out,
dataprep.res = dataprep.out,
Ylab = c("Chomage"),
Xlab = c("annees"),
#Ylim = c(0,13),
Legend = c("NPC","NPC synthetique"),
)

