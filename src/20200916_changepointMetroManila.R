# Calculates and plots the changepoint for Google Mobility Reports.
# Author:  Tiago Tamagusko <tamagusko@gmail.com>
# Version: 0.3 (2020-09-16)
# License: CC-BY-NC-ND-4.0

library(tidyverse)  # v1.3.0
library(ggplot2)  # v3.3.0
library(cowplot)  # v1.0.0 - formating graphs for pub
library(ggpubr)  # v0.3.0 - plot figures into a grid
library(changepoint)  # 2.2.2 Changepoint detection


############ PROGRAM SETTINGS ############
# Configured for Metro Manila region
COUNTRY <- 'Philippines'
REGION <- 'Manila Metropolitan Area'
############ END OF SETTINGS ############

GOOGLE_DATASET <- 'https://www.gstatic.com/covid19/mobility/Global_Mobility_Report.csv'

# read data
GlobalMobilityReport <- read.csv(file = GOOGLE_DATASET) %>%
  group_by(date)
GlobalMobilityReport$date <- as.Date(GlobalMobilityReport$date)

# filter data by COUNTRY and REGION
googleDataPT <- GlobalMobilityReport %>%
  filter(country_region == COUNTRY, metro_area == REGION) %>%
  select(date, retail_and_recreation_percent_change_from_baseline, grocery_and_pharmacy_percent_change_from_baseline, parks_percent_change_from_baseline, transit_stations_percent_change_from_baseline, workplaces_percent_change_from_baseline, residential_percent_change_from_baseline) %>%
  group_by(date)

# split data into categories
retail <- googleDataPT %>%
  select(date, retail_and_recreation_percent_change_from_baseline)
colnames(retail) <- c('date','pct_diff')

grocery <- googleDataPT %>%
  select(date , grocery_and_pharmacy_percent_change_from_baseline)
colnames(grocery) <- c('date','pct_diff')

parks <- googleDataPT %>%
  select(date, parks_percent_change_from_baseline)
colnames(parks) <- c('date','pct_diff')

transit <- googleDataPT %>%
  select(date, transit_stations_percent_change_from_baseline)
colnames(transit) <- c('date','pct_diff')

workplaces <- googleDataPT %>%
  select(date, workplaces_percent_change_from_baseline)
colnames(workplaces) <- c('date','pct_diff')

residential <- googleDataPT %>%
  select(date, residential_percent_change_from_baseline)
colnames(residential) <- c('date','pct_diff')

resultMobi <- cbind(
  'Date' = format(retail$date, '%Y-%m-%d'),
  'Retail and recreation' = retail$pct_diff,
  'Grocery and pharmacy' = grocery$pct_diff,
  'Parks' = parks$pct_diff,
  'Transit stations' = transit$pct_diff,
  'Workplaces' = workplaces$pct_diff,
  'Residential' = residential$pct_diff
)

# save results
write.csv(resultMobi, file = 'result.csv')

# graph
# setting 2 lines and 3 columns
par(mfrow=c(2,3))

# analize changepoints in retail 
fitRetailCP = cpt.mean(retail$pct_diff)
# return estimates
c(ints = param.est(fitRetailCP)$mean,
  cp = cpts(fitRetailCP))
# plot result
plot(fitRetailCP,
     ylab='Distance to baseline',
     xlab='Time')
title(main='Retail and recreation')

# analize changepoints in grocery 
fitGroceryCP = cpt.mean(grocery$pct_diff)
# return estimates
c(ints = param.est(fitGroceryCP)$mean,
  cp = cpts(fitGroceryCP))
# plot result
plot(fitGroceryCP,
     ylab='',
     xlab='Time')
title(main='Grocery and pharmacy')

# analize changepoints in parks 
fitParksCP = cpt.mean(parks$pct_diff)
# return estimates
c(ints = param.est(fitParksCP)$mean,
  cp = cpts(fitParksCP))
# plot result
plot(fitParksCP,
     ylab='',
     xlab='Time')
title(main='Parks')

# analize changepoints in transit 
fitTransitCP = cpt.mean(transit$pct_diff)
# return estimates
c(ints = param.est(fitTransitCP)$mean,
  cp = cpts(fitTransitCP))
# plot result
plot(fitTransitCP,
     ylab='Distance to baseline',
     xlab='Time')
title(main='Transit stations')

# analize changepoints in workplaces 
fitWorkplacesCP = cpt.mean(workplaces$pct_diff)
# return estimates
c(ints = param.est(fitWorkplacesCP)$mean,
  cp = cpts(fitWorkplacesCP))
# plot result
plot(fitWorkplacesCP,
     ylab='',
     xlab='Time')
title(main='Workplaces')

# analize changepoints in residential 
fitResidentialCP = cpt.mean(residential$pct_diff)
# return estimates
c(ints = param.est(fitResidentialCP)$mean,
  cp = cpts(fitResidentialCP))
# plot result
plot(fitResidentialCP, 
     ylab='',
     xlab='Time')
title(main='Residential')
