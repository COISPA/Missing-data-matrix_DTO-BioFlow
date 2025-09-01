#------------------------------Authorship---------------------------------------#
#title: "function"
#lead author: Matteo Chiarini
#contributors: Maria Teresa Spedicato, Walter Zupa, Cosmidano Neglia, Isabella Bitetto, Pierluigi Carbonara, Lola Toomey
#date: "2025-07-19"
#institute: "Fondazione COISPA ETS, Via dei Trulli 18/20 - (Bari), Italy"
#contact: chiarini@fondazionecoispa.org

skills_matrix <- function (db_empty,species,Spat_cov,Temp_cov,Spat_res,Temp_res,Tax_res) {
  
  z=1
  
  db_empty <- db_empty[db_empty$Spat_cov %in% Spat_cov &
                         db_empty$Temp_cov %in% Temp_cov & 
                         db_empty$Spat_res %in% Spat_res & 
                         db_empty$Temp_res %in% Temp_res & 
                         db_empty$Tax_res %in% Tax_res,]
  
  db2 <- as.data.frame(db_empty[,c(1:5)])
  db2[,1:ncol(db2)] <- NA
  
  for (z in 1:nrow(db_empty)){
    
    dq <- db_empty[z,] # the filter!
    
    years <- as.numeric(strsplit(as.character(dq$Temp_cov),"_")[[1]])
    years <- seq(years[1],years[2],1)
    
    dt <- data[data$Ecoregion %in% dq$Spat_cov &
                 data$yearcollected %in% years &
                 data$geom <= dq$Spat_res &
                 data$time <= dq$Temp_res &
                 data$tax <= dq$Tax_res, ] 
    
    if (nrow(dt) == 0){
      db2[z,c(1:5)] <- 1
    } else {
      
      # Spatial Coverage
      db2[z,1] <- 1-(length(unique(dt$ID))/unique(dt$ncell))
      
      # Temporal Coverage 
      db2[z,2] <- 1-(length(unique(dt$yearcollected))/length(years))
      
      # Spatial Resolution
      if (all(dt$geom <= dq$Spat_res)) {
        db2[z,3] <- 0
      } else {
        stop("Spatial Resolution extraction error")
        #db2[i,3] <- NA # NA indicate where is the error!
      }
      
      # Temporal Resolution
      if (all(dt$time <= dq$Temp_res)) {
        db2[z,4] <- 0
      } else {
        stop("Temporal Resolution extraction error")
        #db2[i,4] <- NA # NA indicate where is the error!
      }
      
      # Taxonomical Resolution
      if (all(dt$tax <= dq$Tax_res)) {
        db2[z,5] <- 0
      } else {
        stop("Taxonomical Resolution extraction error")
        #db2[i,5] <- NA # NA indicate where is the error!
      }
    }
    
    db_empty[z,6] <- mean(as.numeric(db2[z,c(1:5)]))
    
  }
  
  db <- db_empty %>% summarize(MD=sum(score)/nrow(db_empty))
  #return(as.numeric(db)) # more precise
  return(percent(as.numeric(db)))
}



unregister <- function() {
  env <- foreach:::.foreachGlobals
  rm(list=ls(name=env), pos=env)
}
