# Skills-Matrix_DTO-BioFlow
A tool to assess the status of missing data within EMODnet Biology

**Authors**: M. Chiarini
COISPA ETS Foundation 

## Description
Skills_Matrix is a **flexible and adaptable tool** developed under the framework of Task 2.3 (“Assessing the impact of missing data”) within the Work Package 2 (“Increasing flow of relevant biodiversity data”) of [DTO-BioFlow](https://dto-bioflow.eu/) project. Skills_Matrix performs a **semi-quantitative assessment of the status of missing biodiversity data** (intended as lacking or absent data because they do not exist or are unavailable or inaccessible) included in the European Marine Observation and Data Network (EMODnet). The main script `skills_matrix()` is divided in different sections designed to deal with each element of the assessment: i) information extraction, ii) scoring and selection process, iii) skills matrix outcomes. Biodiversity data are downloaded from EMODnet directly into an R environment by means of the EMODnet_Web Feature Service (WFS) package. More information about how users can download and select data sources within EMODnet_WFS are provided here: https://github.com/EMODnet/emodnet.wfs/tree/main.
The main script `skills_matrix()` has been developed with the intention of being flexible, thus a hypothetical user could easily adapt the tools to its needs and run the assessment process. A bullet point describing the sections of the code that need to be adapted according to the user's needs follows:

-	**Directory**_ here you have to specify the directory `dir` and `layer` to be assessed as intended in [EMODnet_WFS package](https://github.com/EMODnet/emodnet.wfs). 
``` r
dir <- "C:\\Users\\Utente\\OneDrive - Coispa Tecnologia & Ricerca S.C.A.R.L\\Documenti\\DTO BioFlow\\R" # set here your directory
layer <- "eurobis" # set here the desired layer, more info at: https://github.com/EMODnet/emodnet.wfs 
```
The outputs will be stored within 3 folders: 1) "records", a folder storing maps with the location of every single data downloaded, whether it is inside or outside the spatial domain; 2) "Outputs", a folder that includes the results of skills matrices by time interval both in .csv and .xlsx formats; 3) “Rdata”, where the R objects are saved. 
*Note*. The main script `skills_matrix()` working together with `function()` including all the useful functions. Be sure that both `skills_matrix()` and `function()` are stored in the same folder you are setting here.

-	**Packages**_ here you call the packages. You can download them directly from CRAN:
``` r
install.packages("scales","dplyr","tidyverse","sf","terra","lubridate","openxlsx2")
```

-	**Selection process**_ it acts as a filter to visualize different outcomes of the missing data assessment; this process allows the user to get enough flexibility to investigate the missing data percentages across different spatio-temporal coverages and resolutions.
*Note*. In case of information with a default resolution, it is recommended to use this selection process filtering for the pertinent resolutions; for instance, if the data to be assessed is an abundance index, which by its intrinsic nature does not consider resolutions at the level of geographical coordinates, it is advisable to filter for lower spatial resolution level that, in this example, is “local, regional, by country or by sea”.
You can filter specific levels of the classification factors by removing them from the provided full list.
``` r
Temp_cov <- c("1880_1909","1910_1939","1940_1969","1970_1999","2000_2009","2010_2019","2020_2025")
Tax_res <- c("species","genus","family","order_class")
Temp_res <- c("day_week","month_season","annual")
Spat_res <- c("geom_point","geom_shape")
```
*Note*. Since the levels of classification factors have been defined based on the current characteristics and dimensions of the data contained in the [EMODnet Biology lot](https://emodnet.ec.europa.eu/en/biology), changing these is not recommended.

Furthermore, in such a section you can set:

  * i)	the desired `service` according to [EMODnet_WFS package](https://github.com/EMODnet/emodnet.wfs):
``` r
wfs_bio <- emodnet_init_wfs_client(service = "biology_occurrence_data") # set the service
```
  
  * ii)	the `species` to be assessed (enter the full accepted scientific name according to aphiaID available on [WoRMS](https://www.marinespecies.org/index.php)) 
``` r
species <- c("Ctenophora",”Platyhelmintes”)
```
  *Note*. All taxa entered must correspond to the same taxonomic level.
  
  * iii)	and the desired taxonomic level `taxa` choosing from this list `("species", "genus", "family", "order_class", "phylum")`
``` r
taxa <- "phylum"
```

-	**in case of 1000000**_ this section was developed ad-hoc for the purposes of deliverable D2.8. Follow the instructions within that section to set the code correctly.

The resulting missing data assessment was summarized with percentages in the form of a skills matrix where data coverages and resolutions are intended as skills, while the matrix format is the framework for the combination of these data features.

More information about the workflow and elements to assess the status of missing data as well as examples of Skills_Matrix applications could be found within the Deliverable 2.8 of [DTO-BioFlow project](http//)
