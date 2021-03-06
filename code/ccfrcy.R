#install.packages("readxl")
library(readxl)
library(httr)

zmeanHDT <- 13
zsdHDT <- 12.7
zmedianHDT <- 9.1
muHDT <- log(zmedianHDT)
sigmaHDT <- sqrt(2*(log(zmeanHDT) - muHDT))
cCFRBaseline <- 1.38
cCFREstimateRange <- c(1.23, 1.53)
#cCFRIQRRange <- c(1.3, 1.4)


# Functions from https://cmmid.github.io/topics/covid19/severity/global_cfr_estimates.html
# Hospitalisation to death distribution
hospitalisation_to_death_truncated <- function(x)
{
  dlnorm(x, muHDT, sigmaHDT)
}
# Function to work out correction CFR
scale_cfr <- function(data_1_in, death_incidence, delay_fun){
  case_incidence <- data_1_in$confirmados
  death_incidence <- data_1_in$obitos
  cumulative_known_t <- 0 # cumulative cases with known outcome at time tt
  # Sum over cases up to time tt
  for(ii in 1:length(case_incidence)){
    known_i <- 0 # number of cases with known outcome at time ii
    for(jj in 0:(ii - 1)){
      known_jj <- (case_incidence[ii - jj]*delay_fun(jj))
      known_i <- known_i + known_jj
    }
    cumulative_known_t <- cumulative_known_t + known_i # Tally cumulative known
  }
  # naive CFR value
  b_tt <- sum(death_incidence)/sum(case_incidence) 
  # corrected CFR estimator
  p_tt <- sum(death_incidence)/cumulative_known_t
  data.frame(nCFR = b_tt, cCFR = p_tt, total_deaths = sum(death_incidence), 
             cum_known_t = round(cumulative_known_t), total_cases = sum(case_incidence))
}


#url <- paste("https://www.ecdc.europa.eu/sites/default/files/documents/COVID-19-geographic-disbtribution-worldwide-",format(Sys.time(), "%Y-%m-%d"), ".xlsx", sep = "")
url <- "https://www.ecdc.europa.eu/sites/default/files/documents/COVID-19-geographic-disbtribution-worldwide-2020-04-02.xlsx"
GET(url, authenticate(":", ":", type="ntlm"), write_disk(tf <- tempfile(fileext = ".xlsx")))
data <- read_excel(tf)

data<-data[data$geoId=="CY",]
data<-list(confirmados=c(0,cumsum(rev(data$cases))),obitos=c(0,cumsum(rev(data$deaths))))
           

size=length(data$confirmados)
est_ccfr<-rep(NaN,size)

for (rr in 0:(size-2))
{
    last <- size-rr
    data2 <- list(confirmados=diff(data$confirmados[1:last]),obitos=diff(data$obitos[1:last]))
    ccfr<-scale_cfr(data2, delay_fun = hospitalisation_to_death_truncated)
    
    fraction_reported=cCFRBaseline / (ccfr$cCFR*100)
    
    est_ccfr[last]<-data$confirmados[last]*1/fraction_reported
}
#data2 <- list(confirmados=diff(data$confirmados),obitos=diff(data$obitos))
#ccfr<-scale_cfr(data2, delay_fun = hospitalisation_to_death_truncated)
#
#fraction_reported=cCFRBaseline / (ccfr$cCFR*100) 


populationCY<-890900
survey_twitter<-rep(NaN,size+1)
survey_gforms<-rep(NaN,size+1)

#position 18 is March 28 results about March 27 cases
#survey_twitter[8]<-(4/(36*150))*populationCY #17 March

#dunbar
#21 Mar Cf=1, poll 2
survey_gforms[12]<-estimate_cases(file_path = "../data/PlotData/CY/CY-02-20200320-20200321.csv", country_population = 890900, correction_factor = 1)$dunbar_cases
#24 Mar cf=1, poll 3
survey_gforms[15]<-estimate_cases(file_path = "../data/PlotData/CY/CY-03-20200323-20200324.csv", country_population = 890900, correction_factor = 1)$dunbar_cases
#28 Mar cf=1, poll 4
survey_gforms[19]<-estimate_cases(file_path = "../data/PlotData/CY/CY-04-20200325-20200328.csv", country_population = 890900, correction_factor = 1)$dunbar_cases
#30 Mar cf=1, poll 5
survey_gforms[21]<-estimate_cases(file_path = "../data/PlotData/CY/CY-05-20200329-20200330.csv", country_population = 890900, correction_factor = 1)$dunbar_cases
#1 Apr cf=1, poll 6
survey_gforms[23]<-estimate_cases(file_path = "../data/PlotData/CY/CY-06-20200331-20200401.csv", country_population = 890900, correction_factor = 1)$dunbar_cases


#estimated
#21 Mar Cf=1, poll 2
#survey_gforms[12]<-estimate_cases(file_path = "../data/CY-02-20200320-20200321.csv", country_population = 1189265-300000, correction_factor = 1)$estimated_cases
#25 Mar cf=1, poll 3
#survey_gforms[16]<-estimate_cases(file_path = "../data/CY-03-20200323-20200325.csv", country_population = 1189265-300000, correction_factor = 1)$estimated_cases
#28 Mar cf=1, poll 4
#survey_gforms[19]<-estimate_cases(file_path = "../data/CY-04-20200327-20200328.csv", country_population = 1189265-300000, correction_factor = 1)$estimated_cases
#30 Mar cf=1, poll 5
#survey_gforms[21]<-estimate_cases(file_path = "../data/CY-05-20200329-20200330.csv", country_population = 1189265-300000, correction_factor = 1)$estimated_cases



#est_ccfr[size]<-data$confirmados[size]*1/fraction_reported

plot(data$obitos*400,log="y", xlim=c(1,size+1), ylim=c(1,10000),yaxt="n",xaxt="n",type="l",xlab="Days",main="Different estimates of COVID-19 cases in Cyprus",ylab="Total cases",lty=4)
lines(data$confirmados)
points(survey_twitter,pch=23)
points(survey_gforms,pch=24)
print(survey_gforms)
points(est_ccfr,pch=20)
axis(side = 2, at = 10^seq(0, 4),labels=c("1","10","100","1,000","10,000"))
abline(h=10000,lty="dotted"); abline(h=1000,lty="dotted"); abline(h=100,lty="dotted"); abline(h=10,lty="dotted")
axis(side=1,at=c(6,11,16,21,23),labels=c("Mar 15","Mar 20","Mar 25","Mar 30","Apr 1"))
abline(v=6,lty="dotted"); abline(v=11,lty="dotted"); abline(v=16,lty="dotted"); abline(v=21,lty="dotted"); abline(v=23,lty="dotted");

legend("topleft", 
       legend = c("Confirmed cases", "Estimate based on Fatalities", "Estimate based on Fatality ratio", "Estimate based on Coronasurveys"), 
       lty = c(1,2,0,0), 
       pch = c(NA,NA,20,24),
       #bty = "n", 
       text.col = "black")


print(data$confirmados)
print(data$obitos*400)
print(est_ccfr)
print(survey_gforms)
