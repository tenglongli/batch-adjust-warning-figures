
# script to create Figure 3a

starttime = Sys.time()
debug = FALSE
downloaddata=TRUE
set.seed(100)


includelibs = c("Biobase", "sva", "limma")
lapply(includelibs, require, character.only=T)
source("../../scripts/helperfunctions.r")
source("helperfunctions_towfic.r")

print("Re-analysis and figure generation for example taken from Towfic et al. 2014")

ret = loadtowfic(downloaddata)
sampleannotation = ret[["sampleannotation"]]
rawdata = ret[["data"]]

if(debug)
  rawdata = rawdata[1:1000,]

qnormdata = normalizeBetweenArrays(rawdata, method="quantile") 

# combat adjust
combatdata= as.matrix(ComBat(dat=qnormdata,
                             batch=sampleannotation$batch,
                             mod=model.matrix(~as.factor(sampleannotation$covariate)),
                             numCovs=NULL, par.prior=TRUE, prior.plots=FALSE))

# Significance test DP vs N
group = factor(sampleannotation$covariate)
design = model.matrix(~0 + group)
fit = lmFit(combatdata, design)
cont.matrix = makeContrasts ( contrasts="groupDP-groupN", levels=design)  
fit2 = contrasts.fit(fit, cont.matrix)
limma_p_combat = eBayes(fit2)$p.value[,1]
print(paste("ComBat adjusted real data, significant probes (fdr<0.05): ",
            sum(p.adjust(limma_p_combat, method="fdr")<0.05)))

#Limma blocked batch and significance test
group = factor(sampleannotation$covariate)
block = factor(sampleannotation$batch)
design = model.matrix(~0+group+block)
fit = lmFit(qnormdata, design)
cont.matrix = makeContrasts ( contrasts="groupDP-groupN", levels=design)  
fit2 = contrasts.fit(fit, cont.matrix)
limma_ret_woc = eBayes(fit2)
limma_p_woc = limma_ret_woc$p.value[,1]
print(paste("Limma adjusted real data, significant probes (fdr<0.05): ",  
            sum(p.adjust(limma_p_woc, method="fdr")<0.05)))

# random, ComBat adjusted
set.seed(100)
randdata = combatdata
randdata[,] = matrix(rnorm(length(randdata), mean=0, sd=1))
randcombatdata= as.matrix(ComBat(dat=randdata,
                                 batch=sampleannotation$batch,
                                 mod=model.matrix(~as.factor(sampleannotation$covariate)),
                                 numCovs=NULL, par.prior=TRUE, prior.plots=FALSE))
# Significance test DP vs N
group = factor(sampleannotation$covariate)
design = model.matrix(~0 + group)
fit = lmFit(randcombatdata, design)
cont.matrix = makeContrasts ( contrasts="groupDP-groupN", levels=design)
fit2 = contrasts.fit(fit, cont.matrix)
limma_p_rand_combat = eBayes(fit2)$p.value[,1]
print(paste("ComBat adjusted random data, significant probes (fdr<0.05): ",
            sum(p.adjust(limma_p_rand_combat, method="fdr")<0.05)))


# create pvalue plot
#figfile = paste(getwd(), "/towficpvalues.pdf", sep="")
#pdf(file=figfile)

figfile = paste(getwd(), "/towficpvalues.eps", sep="")
cairo_ps(file =figfile)

adhocpvalueplot(limma_p_combat,limma_p_woc,limma_p_rand_combat, main="(a) P-values")
dev.off()
print( paste("Figure created; ", normalizePath(figfile) ))

print(paste( "Figure generated for Towfic et al data set. Time spent ", 
             as.integer(round(difftime(Sys.time(),starttime, units="mins"))  ), 
             " minutes", sep="") )
rm(ret, combatdata, randcombatdata, randdata, rawdata, qnormdata, sampleannotation, block, group, design )
