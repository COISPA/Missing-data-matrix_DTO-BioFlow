# Chordata QUERY_subsets #

#Chordata - NO NA - NO Aves - NO Mammalia - NO Teleostei - NO Elasmobranchii
subdata_1 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                cql_filter = "(phylum='Chordata') AND class NOT LIKE 'Aves%' AND class NOT LIKE 'Mammalia%' AND class NOT LIKE 'Teleostei%' AND class NOT LIKE 'Elasmobranchii%' AND class IS NOT NULL AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Aves - NO Charadriiformes- NO Procellariiformes
subdata_2 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                cql_filter = "(class='Aves') AND order NOT LIKE 'Charadriiformes%' AND order NOT LIKE 'Procellariiformes%' AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Charadriiformes - NO Laridae - NO Charadriidae
subdata_6 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                cql_filter = "(order='Charadriiformes') AND family NOT LIKE 'Laridae%' AND family NOT LIKE 'Charadriidae%' AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Laridae - NO Larus
subdata_8 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                cql_filter = "(family='Laridae') AND genus NOT LIKE 'Larus%' AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted")
#Larus - NO argentatus - NO fuscus
subdata_9 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                cql_filter = "(genus='Larus') AND species NOT LIKE 'argentatus%' AND species NOT LIKE 'fuscus%' AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted")
#Larus argentatus (137138) - summer
subdata_10 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                cql_filter = "(aphiaidaccepted='137138') AND season LIKE 'summer%' AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted")
#Larus argentatus (137138) - autumn
subdata_11 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                 cql_filter = "(aphiaidaccepted='137138') AND season LIKE 'autumn%' AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                 propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted")
#Larus argentatus (137138) - winter
subdata_12 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                 cql_filter = "(aphiaidaccepted='137138') AND season LIKE 'winter%' AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                 propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted")
#Larus argentatus (137138) - spring
subdata_13 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                 cql_filter = "(aphiaidaccepted='137138') AND season LIKE 'spring%' AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                 propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted")
#Larus fuscus (137142) - summer
subdata_14 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                 cql_filter = "(aphiaidaccepted='137142') AND season LIKE 'summer%' AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                 propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted")
#Larus fuscus (137142)- autumn
subdata_15 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                 cql_filter = "(aphiaidaccepted='137142') AND season LIKE 'autumn%' AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                 propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted")
#Larus fuscus (137142) - winter
subdata_16 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                 cql_filter = "(aphiaidaccepted='137142') AND season LIKE 'winter%' AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                 propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted")
#Larus fuscus (137142) - spring
subdata_17 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                 cql_filter = "(aphiaidaccepted='137142') AND season LIKE 'spring%' AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                 propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted")
#Charadriidae - NO Haematopus
subdata_7 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                cql_filter = "(family='Charadriidae') AND genus NOT LIKE 'Haematopus%' AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted")
#Haematopus ostralegus (147436) - summer
subdata_18 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                 cql_filter = "(aphiaidaccepted='147436') AND season LIKE 'summer%' AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                 propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted")
#Haematopus ostralegus (147436) - autumn
subdata_19 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                 cql_filter = "(aphiaidaccepted='147436') AND season LIKE 'autumn%' AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                 propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted")
#Haematopus ostralegus (147436) - winter
subdata_20 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                 cql_filter = "(aphiaidaccepted='147436') AND season LIKE 'winter%' AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                 propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted")
#Haematopus ostralegus (147436) - spring
subdata_21 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                 cql_filter = "(aphiaidaccepted='147436') AND season LIKE 'spring%' AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                 propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted")
#Procellariiformes
subdata_22 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                cql_filter = "(order='Procellariiformes') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Mammalia - NO Cetartiodactyla
subdata_3 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                cql_filter = "(class='Mammalia') AND order NOT LIKE 'Cetartiodactyla%' AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Cetartiodactyla
subdata_23 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                cql_filter = "(order='Cetartiodactyla') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Teleostei - NO Pleuronectiformes - NO Gadiformes - NO Perciformes - NO Anguilliformes - NO Scombriformes - NO Clupeiformes - NO Callionymiformes - NO Eupercaria incertae sedis - NO Zeiformes - NO Argentiniformes - NO Tetraodontiformes
subdata_4 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                cql_filter = "(class='Teleostei') AND order NOT LIKE 'Pleuronectiformes%' AND order NOT LIKE 'Gadiformes%' AND order NOT LIKE 'Perciformes%' AND order NOT LIKE 'Anguilliformes%' AND order NOT LIKE 'Scombriformes%' 
                                AND order NOT LIKE 'Clupeiformes%' AND order NOT LIKE 'Callionymiformes%' AND order NOT LIKE 'Eupercaria incertae sedis%' AND order NOT LIKE 'Zeiformes%' AND order NOT LIKE 'Argentiniformes%' AND order NOT LIKE 'Tetraodontiformes%' AND aphiaidaccepted IS NOT NULL",
                                propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Pleuronectiformes - NO Pleuronectidae
subdata_24 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                cql_filter = "(order='Pleuronectiformes') AND family NOT LIKE 'Pleuronectidae%' AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Pleuronectidae - NO Platichthys - NO Pleuronectes
subdata_25 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                 cql_filter = "(family='Pleuronectidae') AND genus NOT LIKE 'Platichthys%' AND genus NOT LIKE 'Pleuronectes%' AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                 propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Platichthys
subdata_26 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                 cql_filter = "(genus='Platichthys') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                 propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Pleuronectes
subdata_27 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                 cql_filter = "(genus='Pleuronectes') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                 propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Gadiformes - NO Gadidae
subdata_28 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                 cql_filter = "(order='Gadiformes') AND family NOT LIKE 'Gadidae%' AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                 propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Gadidae - NO Gadus - NO Melanogrammus
subdata_29 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                 cql_filter = "(family='Gadidae') AND genus NOT LIKE 'Gadus%' AND genus NOT LIKE 'Melanogrammus%' AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                 propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Gadus
subdata_30 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                 cql_filter = "(genus='Gadus') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                 propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Melanogrammus
subdata_31 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                 cql_filter = "(genus='Melanogrammus') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                 propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Perciformes - NO Triglidae
subdata_32 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                               cql_filter = "(order='Perciformes') AND family NOT LIKE 'Triglidae%' AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                               propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Triglidae
subdata_33 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                 cql_filter = "(family='Triglidae') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                                 propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Anguilliformes
subdata_34 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                               cql_filter = "(order='Anguilliformes') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                               propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Scombriformes
subdata_35 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                               cql_filter = "(order='Scombriformes') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                               propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Clupeiformes
subdata_36 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                               cql_filter = "(order='Clupeiformes') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                               propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Callionymiformes
subdata_37 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                               cql_filter = "(order='Callionymiformes') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                               propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Eupercaria incertae sedis
subdata_38 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                               cql_filter = "(order='Eupercaria incertae sedis') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                               propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Zeiformes
subdata_39 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                               cql_filter = "(order='Zeiformes') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                               propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Argentiniformes
subdata_40 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                               cql_filter = "(order='Argentiniformes') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                               propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Tetraodontiformes
subdata_41 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                               cql_filter = "(order='Tetraodontiformes') AND yearcollected IS NOT NULL AND aphiaidaccepted IS NOT NULL",
                               propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 
#Elasmobranchii
subdata_5 <- emodnet_get_layers(wfs = wfs_bio, layers = "eurobis", reduce_layers = T, outputFormat = "CSV", crs=4326, 
                                cql_filter = "(class='Elasmobranchii') AND aphiaidaccepted IS NOT NULL",
                                propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted") 

subdata <- do.call(rbind, mget(paste0("subdata_", 1:41)))
