# Crustaceans QUERY_subsets #

#Branchiopoda
subdata_1 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                cql_filter = "(class='Branchiopoda') AND class IS NOT NULL AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Remipedia
subdata_2 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                               cql_filter = "(class='Remipedia')AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                               propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Cephalocarida
subdata_3 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                               cql_filter = "(class='Cephalocarida')AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                               propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Ostracoda
subdata_4 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                               cql_filter = "(class='Ostracoda')AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                               propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Copepoda - NO Calanoida
subdata_5 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                cql_filter = "(class='Copepoda') AND order NOT LIKE 'Calanoida%' AND aphiaidaccepted IS NOT NULL",
                                propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Calanoida - NO Calanidae - NO Acartiidae - NO NA
subdata_6 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                cql_filter = "(order='Calanoida') AND family NOT LIKE 'Calanidae%'AND family NOT LIKE 'Acartiidae%' AND family IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Calanidae
subdata_7 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                cql_filter = "(family='Calanidae') AND aphiaidaccepted IS NOT NULL",
                                propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Acartiidae
subdata_8 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                cql_filter = "(family='Acartiidae') AND aphiaidaccepted IS NOT NULL",
                                propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Calanoida - NA (order)
subdata_9 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                cql_filter = "(order='Calanoida') AND family IS NULL AND aphiaidaccepted IS NOT NULL",
                                propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Thecostraca
subdata_10 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                               cql_filter = "(class='Thecostraca')AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                               propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Malacostraca - NO Decapoda - NO Amphipoda
subdata_11 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                cql_filter = "(class='Malacostraca') AND order NOT LIKE 'Decapoda%' AND order NOT LIKE 'Amphipoda%' AND aphiaidaccepted IS NOT NULL",
                                propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Decapoda
subdata_12 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                cql_filter = "(order='Decapoda') AND aphiaidaccepted IS NOT NULL",
                                propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Amphipoda
subdata_13 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                cql_filter = "(order='Amphipoda') AND aphiaidaccepted IS NOT NULL",
                                propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Mystacocarida
subdata_14 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                               cql_filter = "(class='Mystacocarida')AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                               propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Pentastomida
subdata_15 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                               cql_filter = "(class='Pentastomida')AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                               propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 

subdata <- do.call(rbind, mget(paste0("subdata_", 1:15)))

