#' ---
#' title: "Loch Rannoch Ferox Trout Mark-Recapture Analysis"
#' author: "Joe Thorley"
#' ---
#'
#' ensure required packages are loaded
library(magrittr)
library(dplyr)
library(sp)
library(jaggernaut)
library(ggplot2)
library(scales)
library(ranmrdata)
library(ranmr)

#' create directory to store results
dir.create("results", showWarnings = FALSE, recursive = TRUE)

# load data
ferox <- ranmrdata::ferox
rannoch <- ranmrdata::rannoch

# project in UTM Zone 30N
ferox %<>% sp::spTransform(sp::CRS("+init=epsg:32630"))
rannoch %<>% sp::spTransform(sp::CRS("+init=epsg:32630"))

# convert ferox SpatialPointsDataFrame to data frame
ferox %<>% as.data.frame()
ferox %<>% mutate(Easting = coords.x1 / 1000, Northing = coords.x2 / 1000)

# convert rannoch SpatialPolygons to data frame
rannoch %<>% fortify()
rannoch %<>% mutate(Easting = long / 1000, Northing = lat / 1000)

# fill in missing ages
ferox %<>% fill_in_ages()

# plot and save map of captures and recaptures
png("results/map.png", width = 7.5, height = 2, units = "in", res = getOption("res", 150))
plot_rannoch(rannoch) %>% plot_mr(ferox, xcol = "Easting",  ycol = "Northing", gp = .)
dev.off()

# plot and save length-mass data
png("results/mass.png", width = 3, height = 3, units = "in", res = getOption("res", 150))
plot_mr(ferox, xlab = "Fork Length (mm)", ylab = "Wet Mass (kg)")
dev.off()

# plot and save age-length data
png("results/age.png", width = 3, height = 3, units = "in", res = getOption("res", 150))
plot_mr(ferox, xcol = "Age",  ycol = "Length",
                    xlab = "Scale Age (yr)",  ylab = "Fork Length (mm)")
dev.off()

# print and save summary and table of ferox data
summarise_mr(ferox)
saveRDS(summarise_mr(ferox), "results/data.rds")
tabulate_mr(ferox)
saveRDS(tabulate_mr(ferox), "results/table.rds")

# set number of genuine and pseudoindividuals to be 1000
levels(ferox$Fish) %<>% c(paste0("Pseudo", 1:(1000 - nlevels(ferox$Fish))))

# print JAGS model code
cat(mr_model_code())

# perform mark-recapture analysis and save results
analysis <- analyse_mr(ferox)
summary(analysis)

saveRDS(analysis, "results/analysis.rds")
saveRDS(coef(analysis), "results/coef.rds")

# save pdf of analysis traceplots
pdf("results/traceplots.pdf")
plot(analysis)
dev.off()

# plot and save abundance estimates by year
png("results/abundance.png", width = 3, height = 3, units = "in", res = getOption("res", 150))
plot_abundance(analysis)
dev.off()

# perform posterior predictive check
ppc <- predictive_check(analysis)
print(ppc)
saveRDS(ppc, "results/ppc.rds")
