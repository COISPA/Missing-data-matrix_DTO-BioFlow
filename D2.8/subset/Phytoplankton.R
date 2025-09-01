# Phytoplankton QUERY_subsets #

#Chlorophyta
subdata_1 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                cql_filter = "(phylum='Chlorophyta') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Bacillariophyceae
subdata_2 <-load("C:/Users/Utente/OneDrive - Coispa Tecnologia & Ricerca S.C.A.R.L/Documenti/DTO BioFlow/R/occurrence2/Rdata/Heterokontophyta.RData")

#Coccolithophyceae
subdata_3 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                cql_filter = "(class='Coccolithophyceae') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Dinophyceae
subdata_4 <- load("C:/Users/Utente/OneDrive - Coispa Tecnologia & Ricerca S.C.A.R.L/Documenti/DTO BioFlow/R/occurrence2/Rdata/Myzozoa.RData")

subdata <- do.call(rbind, mget(paste0("subdata_", 1:4)))