# Myzozoa QUERY_subsets #

#Myzozoa - NO NA - NO Dinophyceae
subdata_1 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                cql_filter = "(phylum='Myzozoa') AND class NOT LIKE 'Dinophyceae%' AND class IS NOT NULL AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Dinophyceae - NO Dinophysales - NO Peridiniales - NO Gonyaulacales
subdata_2 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                cql_filter = "(class='Dinophyceae') AND order NOT LIKE 'Dinophysales%' AND order NOT LIKE 'Peridiniales%' AND order NOT LIKE 'Gonyaulacales%' AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Dinophysales
subdata_3 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                cql_filter = "(order='Dinophysales') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Peridiniales
subdata_4 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                               cql_filter = "(order='Peridiniales') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                               propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Gonyaulacales
subdata_5 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                               cql_filter = "(order='Gonyaulacales') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                               propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 

subdata <- do.call(rbind, mget(paste0("subdata_", 1:5)))