# Teleostei QUERY_subsets #

#Teleostei - NO Pleuronectiformes - NO Gadiformes - NO Perciformes - NO Anguilliformes - NO Scombriformes - NO Clupeiformes - NO Callionymiformes - NO Eupercaria incertae sedis - NO Zeiformes - NO Argentiniformes - NO Tetraodontiformes - NO NA
subdata_1 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                cql_filter = "(class='Teleostei') AND order NOT LIKE 'Pleuronectiformes%' AND order NOT LIKE 'Gadiformes%' AND order NOT LIKE 'Perciformes%' AND order NOT LIKE 'Anguilliformes%' AND order NOT LIKE 'Scombriformes%' 
                                AND order NOT LIKE 'Clupeiformes%' AND order NOT LIKE 'Callionymiformes%' AND order NOT LIKE 'Eupercaria incertae sedis%' AND order NOT LIKE 'Zeiformes%' AND order NOT LIKE 'Argentiniformes%' AND order NOT LIKE 'Tetraodontiformes%' 
                                AND class IS NOT NULL AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Pleuronectiformes - NO Pleuronectidae
subdata_2 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                 cql_filter = "(order='Pleuronectiformes') AND family NOT LIKE 'Pleuronectidae%' AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                 propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Pleuronectidae - NO Platichthys - NO Pleuronectes
subdata_3 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                 cql_filter = "(family='Pleuronectidae') AND genus NOT LIKE 'Platichthys%' AND genus NOT LIKE 'Pleuronectes%' AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                 propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Platichthys
subdata_4 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                 cql_filter = "(genus='Platichthys') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                 propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Pleuronectes
subdata_5 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                 cql_filter = "(genus='Pleuronectes') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                 propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Gadiformes - NO Gadidae
subdata_6 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                 cql_filter = "(order='Gadiformes') AND family NOT LIKE 'Gadidae%' AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                 propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Gadidae - NO Gadus - NO Melanogrammus
subdata_7 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                 cql_filter = "(family='Gadidae') AND genus NOT LIKE 'Gadus%' AND genus NOT LIKE 'Melanogrammus%' AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                 propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Gadus
subdata_8 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                 cql_filter = "(genus='Gadus') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                 propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Melanogrammus
subdata_9 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                 cql_filter = "(genus='Melanogrammus') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                 propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Perciformes - NO Triglidae
subdata_10 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                 cql_filter = "(order='Perciformes') AND family NOT LIKE 'Triglidae%' AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                 propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Triglidae
subdata_11 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                 cql_filter = "(family='Triglidae') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                 propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Anguilliformes
subdata_12 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                 cql_filter = "(order='Anguilliformes') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                 propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Scombriformes
subdata_13 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                 cql_filter = "(order='Scombriformes') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                 propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Clupeiformes
subdata_14 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                 cql_filter = "(order='Clupeiformes') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                 propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Callionymiformes
subdata_15 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                 cql_filter = "(order='Callionymiformes') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                 propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Eupercaria incertae sedis
subdata_16 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                 cql_filter = "(order='Eupercaria incertae sedis') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                 propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Zeiformes
subdata_17 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                 cql_filter = "(order='Zeiformes') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                 propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Argentiniformes
subdata_18 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                 cql_filter = "(order='Argentiniformes') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                 propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Tetraodontiformes
subdata_19 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                 cql_filter = "(order='Tetraodontiformes') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                 propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 

subdata <- do.call(rbind, mget(paste0("subdata_", 1:19)))
