#------------------------------Authorship---------------------------------------#
#title: "Missing data_matrix"
#lead author: Matteo Chiarini
#contributors: Maria Teresa Spedicato, Walter Zupa, Cosmidano Neglia, Isabella Bitetto, Pierluigi Carbonara, Lola Toomey
#date: "2025-07-19"
#institute: "Fondazione COISPA ETS, Via dei Trulli 18/20 - (Bari), Italy"
#contact: chiarini@fondazionecoispa.org
#-------------------------------Directory--------------------------------------#
rm(list=ls())
dir <- "C:\\Users\\Utente\\OneDrive - Coispa Tecnologia & Ricerca S.C.A.R.L\\Documenti\\DTO BioFlow\\R" 
setwd(dir)
type <- "occurrence"
dir.create(paste0(".\\",type),showWarnings = FALSE) # create main folder
dir.create(paste0(".\\",type,"\\records"),showWarnings = FALSE) # create folder to store data used
dir.create(paste0(".\\",type,"\\Outputs"),showWarnings = FALSE) # create folder to store results
dir.create(paste0(".\\",type,"\\Rdata"),showWarnings = FALSE) # create folder to store Rdata
#-------------------------------Packages---------------------------------------#
#install.packages("pak")
#pak::pak("EMODnet/emodnet.wfs")
library(emodnet.wfs)
library(scales)
library(dplyr)
library(tidyverse)
library(sf)
library(terra)
library(lubridate)
library(openxlsx2)
#-----------------------------Load function------------------------------------#

source(file.path(paste0(dir,"/function.R")))

#-----------------------------Download grid------------------------------------#
# Get EMODnet ecoregions grid
gis <- "Clip_ICES_ecoregions_Estensione_Med"

grid <- terra::vect(paste0(dir,"\\",gis,"\\",gis,".shp"))
grid <- grid[ , c("ID","Ecoregion")]

#----------------------------Selection process---------------------------------#
# Selection process
wfs_bio <- emodnet_init_wfs_client(service = "biology_occurrence_data")

#phylum <- read.csv("2025-14-07_EMODnetBIO_phylum.csv", header = T, sep=";") # To be CHANGED in case of EMODnet update
#phylum <- phylum %>% filter(notes=="accepted")
#phylum <- as.vector(phylum$phylum)
#phylum_milion <- c("Annelida", "Arthropoda", "Chordata", "Foraminifera", "Heterokontophyta", "Mollusca", "Myzozoa") #taxa over 1000000 records
#phylum_filtered <- phylum[!phylum %in% phylum_milion] #remove taxa over milion records from the list to assess

species <- c("Ctenophora")

taxa <- "phylum" #"scientificname_accepted" , "class" <- remember to change here following the desired taxonomical resolution 

add <- " AND aphiaidaccepted IS NOT NULL AND yearcollected IS NOT NULL" # unaccepted taxa & data with no temporal information are not downloaded
#add <- " AND class IS NULL AND aphiaidaccepted IS NOT NULL AND yearcollected IS NOT NULL" ##### TO UNMUTE ONLY for phylum in case of 1000000 #####

Spat_cov <- levels(as.factor(grid$Ecoregion))
Temp_cov <- c("1880_1909","1910_1939","1940_1969","1970_1999","2000_2009","2010_2019","2020_2025")
Tax_res <- c("species","genus","family","order_class")
Temp_res <- c("day_week","month_season","annual")
Spat_res <- c("geom_point","geom_shape")
# create class factors
Spat_cov <- factor(Spat_cov,levels = Spat_cov,ordered = T)
Temp_cov <- factor(Temp_cov,levels = Temp_cov)
Tax_res <- factor(Tax_res,levels = Tax_res,ordered = T)
Temp_res <- factor(Temp_res,levels = Temp_res,ordered = T)
Spat_res <- factor(Spat_res,levels = Spat_res,ordered = T)

# n° of all available combination among levels (=nrow database)
nrow <- nlevels(Spat_cov) * nlevels(Temp_cov) * nlevels(Spat_res) * nlevels(Temp_res) * nlevels(Tax_res)

#----------------------------in case of 1000000--------------------------------#
#################### REMEMBER TO UNMUTE line 47 & 105 !!! #################### 
# Here UNMUTE ONLY the source matching with the phylum analysed # 

#source(file.path(paste0(dir,"/subset/Annelida.R")))
#source(file.path(paste0(dir,"/subset/Arthropoda.R")))
#source(file.path(paste0(dir,"/subset/Chordata.R")))
#source(file.path(paste0(dir,"/subset/Foraminifera.R")))
#source(file.path(paste0(dir,"/subset/Heterokontophyta.R")))
#source(file.path(paste0(dir,"/subset/Mollusca.R")))
#source(file.path(paste0(dir,"/subset/Myzozoa.R")))
#---------------------------------for loop-------------------------------------#
i=1
l=1
j=1
#-------------------------------empty db/list----------------------------------#
# create db [Ecoregions by Species] 
db = data.frame(matrix(nrow=length(Spat_cov), ncol=length(species)))
names(db) = species
rownames(db)= Spat_cov
# create a list [by Temp_cov] to be storage in .xlsx sheets
out = vector("list", length(Temp_cov))
names(out) = Temp_cov

for (i in 1:length(species)){
  #--------------------------Hierarchical database-------------------------------#
  # Create database
  db_empty = data.frame(Spat_cov=rep(Spat_cov,times=nrow/nlevels(Spat_cov)))
  db_empty <- db_empty %>% group_by(Spat_cov) %>% reframe(Temp_cov)
  db_empty <- db_empty %>% group_by(Spat_cov,Temp_cov) %>% reframe(Spat_res)
  db_empty <- db_empty %>% group_by(Spat_cov,Temp_cov,Spat_res) %>% reframe(Temp_res)
  db_empty <- db_empty %>% group_by(Spat_cov,Temp_cov,Spat_res,Temp_res) %>% reframe(Tax_res)
  db_empty$score = NA
  db_empty$Species = species[i]
  ifelse(any(duplicated(db_empty)),stop("TO CHECK"),"OK") #check
  
  #-----------------------------Download data------------------------------------#
  cql_filter <- paste0(taxa," = '",species[i], "'",add) 
  data <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", cql_filter = cql_filter, reduce_layers = T, crs = 4326, outputFormat = "CSV",
                             propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
  
  #data <- rbind(data,subdata) #### UNMUTE ONLY in case of 1000000 ####
  #-----------------------------Data extraction----------------------------------#
  points <- terra::extract(grid,data[,c("longitude","latitude")])
  points <- points[!duplicated(points$id.y),]
  
  # extract the Ecoregion of belonging
  data_all <- cbind(data,points)
  data_NA <- data_all[is.na(data_all$Ecoregion),]
  data <- data_all[!is.na(data_all$Ecoregion),] #remove external points to the ICES_ecoregion (possible internal fresh waters)
  ifelse(nrow(data_all) == nrow(data_NA) + nrow(data),"OK",stop("TO CHECK")) # check
  save(data, file = paste0(type,"/Rdata/",species[i],".RData"))
  
  # plot NA records (i.e. outside the ICES Ecoregion boundaries)
  crspoints <- "+proj=longlat +datum=WGS84" # CRS
  longlat_NA <- cbind(data_NA$longitude, data_NA$latitude) # extract longitude and latitude values
  pts_NA <- vect(longlat_NA, atts= as.data.frame(data_NA$id.y), crs = crspoints)
  longlat <- cbind(data$longitude, data$latitude) # extract longitude and latitude values
  pts <- vect(longlat, atts= as.data.frame(data$id.y), crs = crspoints)

  png(file=paste0(type,"/records/records_",species[i],".png"), width = 240, height = 180, units="mm", res=400)
  terra::plot(grid,cex=0.3)
  points(pts_NA,col="red",cex=0.5)
  points(pts,col="green",cex=0.5)
  legend(x=57, y=36, legend = c("OCC","NA"), pch = 20, xpd=NA, bg="white", col=c("green","red"))
  dev.off()
  #write.table(data_NA,paste0("NA_records/NA_records_",species[i],".csv"),sep=",",dec=".")
  
  # ncell by Ecoregion
  Ecoregion <- as.data.frame(grid) %>% group_by(Ecoregion) %>% reframe(ncell=n())
  data <- left_join(data,Ecoregion, by = join_by(Ecoregion))
  
  # Create new column for occurrence of logical factors (i.e. data resolution)
  data$geom <- ifelse(is.na(data$the_geom), "geom_shape", "geom_point")
  
  data$time <- ifelse(is.na(data$timeofday), "other", "day_week")
  data$time[data$time=="other"] <- ifelse(is.na(data[which(data$time =="other"),]$monthcollected), "annual", "month_season")
  ifelse(length(data[which(data$time =="other")])==0,"OK",stop("TO CHECK")) # check
  
  data$tax <- ifelse(is.na(data$species), "other", "species")
  data$tax[data$tax=="other"] <- ifelse(is.na(data[which(data$tax =="other"),]$genus), "other", "genus")
  data$tax[data$tax=="other"] <- ifelse(is.na(data[which(data$tax =="other"),]$family), "order_class", "family")
  ifelse(length(data[which(data$tax =="other")])==0,"OK",stop("TO CHECK")) # check
  
  # Initialise a progress bar
  pb=txtProgressBar(min=0,max=length(Temp_cov),initial=0,style=3,width=length(Temp_cov),char="=") 
  init <- numeric(length(Temp_cov))
  end <- numeric(length(Temp_cov))
  # Loop
  for (l in 1:length(Temp_cov)){
    
    init[l] <- Sys.time()
    
    for (j in 1:length(Spat_cov)){
      #---------------------------------Function-------------------------------------#
      db[j,i] = skills_matrix(db_empty,species[i],
                              Spat_cov[j],
                              Temp_cov[l],
                              Spat_res,
                              Temp_res,
                              Tax_res)
    }
    write.table(db,paste0(type,"/Outputs/Missing data Matrix_",Temp_cov[l],".csv"),sep=",",dec=".")
    
    out[[l]][[i]] <- db[i]

    Sys.sleep(0.01) # Sleep for 0.1 seconds
    end[l] <- Sys.time()
    setTxtProgressBar(pb,l)  # Print progress bar
    time <- round(seconds_to_period(sum(end - init)), 2) # Execution time
    # Estimated remaining time based on the mean time that took to run the previous iterations
    est <- length(Temp_cov) * (mean(end[end != 0] - init[init != 0])) - time 
    remainining <- round(seconds_to_period(est), 2) 
    cat(paste(" // Execution time:", time,
              " // Estimated time remaining:", remainining), "")
  }
  print(species[i])
  close(pb)
}

openxlsx2::write_xlsx(out, paste0(type,"/Outputs/Missing data by TempCov.xlsx"), as_table = F, col.names = TRUE, row.names = TRUE)
save.image(file=paste0(type,'/environment.RData'))
