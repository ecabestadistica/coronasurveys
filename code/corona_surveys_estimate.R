calculate_CI <- function(p_est, level, pop_size) {
  z <- qnorm(level+(1-level)/2)
  se <- sqrt(p_est*(1-p_est))/sqrt(pop_size)
  return(list(low=p_est-z*se, upp=p_est+z*se, error=z*se))
}

estimate_cases <- function(file_path = "../data/ES-06-20200322-20200323.csv", country_population = 46754778,
                           max_ratio = .3, correction_factor = 1) {
  # read data
  dt <- read.csv(file_path)
  names(dt) <- c("date","region","reach","cases")
  n_inital_response <- nrow(dt)
  
  # get name of csv file for later labelling of outliers removed files
  file_names_com <- unlist(strsplit(file_path, split = "/"))
  file_name <- file_names_com[length(file_names_com)] # select the last path of file_path
  
  
  # remove outliers from the reach column
  reach_cutoff <-(boxplot.stats(dt$reach)$stats[5]) # changed cutoff to upper fence
  if(sum(dt$reach > reach_cutoff) > 0 ){
   # write.table(dt[dt$reach >= reach_cutoff, ],
   #             file = paste0("outliers_removed/", file_name, "_", "outliers_reach.txt"),
   #              append = T) # write out outliers from reach column to the ouliers removed folder
    n_reach_outliers <- sum(dt$reach >= reach_cutoff) #number of outliers removed based on reach
    dt <- dt[dt$reach < reach_cutoff, ]
  }else{
    n_reach_outliers <- 0
  }
  
  
  # remove outliers based on max ratio of 0.3
  dt$ratio <- dt$cases/dt$reach
  if(sum(dt$ratio >= max_ratio) > 0 ){
    #write.table(dt[dt$ratio >= max_ratio, ],
    #            file = paste0("outliers_removed/", file_name, "_", "outliers_max_ratio.txt"),
    #            append = T) # write out outliers based on max_Ratio
    n_maxratio_outliers <- sum(dt$ratio >= max_ratio)
    dt <- dt[dt$ratio < max_ratio, ]
  }else{
    n_maxratio_outliers <- 0
  }
  
  
  
  # estimate infection cases
  mean_cases <- mean(dt$cases)
  mean_reach <- mean(dt$reach)
  dunbar_reach <- 150*nrow(dt)
  cases_per_reach <-sum(dt$cases)/sum(dt$reach)
  
  
  out <- calculate_CI(p_est=cases_per_reach, level=0.95, pop_size=sum(dt$reach))
  
  naif_cases<- country_population * cases_per_reach * correction_factor
  dunbar_cases<- country_population * (sum(dt$cases)/dunbar_reach) * correction_factor
  prop_cases <- country_population* mean(dt$cases/dt$reach) * correction_factor
  
  return(list(mean_cases = mean_cases,
              mean_reach = mean_reach,
              cases_per_reach = cases_per_reach,
              error=out$error*country_population*correction_factor,
              estimated_cases = naif_cases,
              dunbar_cases = dunbar_cases,
              prop_cases = prop_cases,
              cases_breakdown = table(dt$cases),
              cases_breakdown_region = table(dt$region, dt$cases),
              n_reach_outliers = n_reach_outliers,
              n_maxratio_outliers = n_maxratio_outliers,
              n_inital_response = n_inital_response,
              n_final_response = nrow(dt)))
}



