# Zooplankton QUERY_subsets #

#Chaetognatha
subdata_1 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                cql_filter = "(phylum='Chaetognatha') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Globothalamea
subdata_2 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                cql_filter = "(class='Globothalamea') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Tubothalamea
subdata_3 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                cql_filter = "(class='Tubothalamea') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Monothalamea
subdata_4 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                cql_filter = "(class='Monothalamea') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Acantharia
subdata_5 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                cql_filter = "(class='Acantharia') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Hydrozoa
subdata_6 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                cql_filter = "(class='Hydrozoa') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Scyphozoa
subdata_7 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                cql_filter = "(class='Scyphozoa') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Copepoda
subdata_8 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                cql_filter = "(class='Copepoda') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Euphausiacea
subdata_9 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                cql_filter = "(class='Euphausiacea') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Amphipoda
subdata_10 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                cql_filter = "(class='Amphipoda') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Ostracoda
subdata_11 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                               cql_filter = "(class='Ostracoda') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                               propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Thaliacea
subdata_12 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                               cql_filter = "(class='Thaliacea') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                               propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Appendicularia
subdata_13 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                               cql_filter = "(class='Appendicularia') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                               propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Phaeodaria
subdata_14 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                 cql_filter = "(order='Phaeodaria') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                               propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Tintinnina
subdata_15 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                               cql_filter = "(order='Tintinnina') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                               propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Heteropoda
subdata_16 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                               cql_filter = "(order='Heteropoda') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                               propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Pteropoda
subdata_17 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                               cql_filter = "(order='Pteropoda') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                               propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 

subdata <- do.call(rbind, mget(paste0("subdata_", 1:17)))