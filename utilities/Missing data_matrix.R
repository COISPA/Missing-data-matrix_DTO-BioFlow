#------------------------------Authorship---------------------------------------#
#title: "Missing data_matrix"
#lead author: Matteo Chiarini
#contributors: Maria Teresa Spedicato, Walter Zupa, Cosmidano Neglia, Isabella Bitetto, Pierluigi Carbonara, Lola Toomey
#date: "2026-05-19"
#institute: "Fondazione COISPA ETS, Via dei Trulli 18/20 - (Bari), Italy"
#contact: chiarini@fondazionecoispa.org

# DTO-BioFlow Modification: Added progress updates and log callbacks for dynamic execution feedback.
run_missing_data_pipeline <- function(inputs, update_progress, log_callback = NULL, session = NULL) {
  # Log helper function
  log_msg <- function(msg) {
    if (!is.null(log_callback)) {
      log_callback(msg)
    } else {
      cat(msg, "\n")
    }
  }
  
  # Safe progress updater
  update_progress_safe <- function(amount = 0, detail = NULL) {
    if (!is.null(update_progress)) {
      has_amount <- FALSE
      if (is.function(update_progress)) {
        args <- names(formals(update_progress))
        if ("amount" %in% args || "..." %in% args) {
          has_amount <- TRUE
        }
      }
      if (has_amount) {
        update_progress(amount = amount, detail = detail)
      } else {
        update_progress(detail = detail)
      }
    }
  }
  
  dir <- inputs$work_dir
  type <- ifelse(inputs$wfs_service == "biology_abundance_data", "abundance", "occurrence")
  
  dir.create(file.path(dir, type), showWarnings = FALSE) 
  dir.create(file.path(dir, type, "records"), showWarnings = FALSE) 
  dir.create(file.path(dir, type, "Outputs"), showWarnings = FALSE) 
  dir.create(file.path(dir, type, "Rdata"), showWarnings = FALSE) 
  
  species <- trimws(strsplit(inputs$species, ",")[[1]])
  
  if (!is.null(inputs$macrogroup_name) && inputs$macrogroup_name != "") {
    taxa_folder_name <- inputs$macrogroup_name
  } else {
    taxa_folder_name <- paste(species, collapse = "_")
  }
  
  taxa_output_dir <- file.path(dir, type, "Outputs", taxa_folder_name)
  dir.create(taxa_output_dir, showWarnings = FALSE)
  
  # DTO-BioFlow Modification: Sourced from the utilities directory and bound environment for renamed function missing_data_matrix.
  source(file.path(dir, "utilities", "function.R"))
  environment(missing_data_matrix) <- globalenv()
  environment(process_single_species_scoring) <- globalenv()
  environment(emodnet_get_layers_paged) <- globalenv()
  
  gis <- "Clip_ICES_ecoregions_Estensione_Med"
  grid <- terra::vect(file.path(dir, gis, paste0(gis, ".shp")))
  grid <- grid[ , c("ID","Ecoregion")]
  
  wfs_service_name <- inputs$wfs_service
  if (wfs_service_name == "biology_abundance_data") {
    wfs_service_name <- "biology_occurrence_data"
  }
  wfs_bio <- emodnet_init_wfs_client(service = wfs_service_name)
  
  taxa_levels <- inputs$taxa_level
  if (length(taxa_levels) == 1) {
    if (grepl(",", taxa_levels)) {
      taxa_levels <- trimws(strsplit(taxa_levels, ",")[[1]])
    } else {
      taxa_levels <- rep(taxa_levels, length(species))
    }
  }
  
  add <- " AND aphiaidaccepted IS NOT NULL AND yearcollected IS NOT NULL"
  
  selected_tax_res <- switch(inputs$tax_res,
                             "species"     = c("species", "genus", "family", "order_class"),
                             "genus"       = c("genus", "family", "order_class"),
                             "family"      = c("family", "order_class"),
                             "order_class" = c("order_class"))
  
  selected_temp_res <- switch(inputs$temp_res,
                              "day_week"     = c("day_week", "month_season", "annual"),
                              "month_season" = c("month_season", "annual"),
                              "annual"       = c("annual"))
  
  selected_spat_res <- switch(inputs$spat_res,
                              "geom_point" = c("geom_point", "geom_shape"),
                              "geom_shape" = c("geom_shape"))
  
  Spat_cov <- inputs$spat_cov
  Temp_cov <- inputs$temp_cov
  
  Spat_cov <- factor(Spat_cov, levels = Spat_cov, ordered = TRUE)
  Temp_cov <- factor(Temp_cov, levels = Temp_cov)
  Tax_res  <- factor(selected_tax_res,  levels = c("species", "genus", "family", "order_class"),  ordered = TRUE)
  Temp_res <- factor(selected_temp_res, levels = c("day_week", "month_season", "annual"), ordered = TRUE)
  Spat_res <- factor(selected_spat_res, levels = c("geom_point", "geom_shape"), ordered = TRUE)

  

  nrow_val <- nlevels(Spat_cov) * nlevels(Temp_cov) * nlevels(Spat_res) * nlevels(Temp_res) * nlevels(Tax_res)
  
  db = data.frame(matrix(nrow=length(Spat_cov), ncol=length(species)))
  names(db) = species
  rownames(db) = Spat_cov
  
  out = vector("list", length(Temp_cov))
  names(out) = Temp_cov
  
  for(l in 1:length(Temp_cov)) {
    out[[l]] <- data.frame(matrix(nrow = length(Spat_cov), ncol = length(species)))
    colnames(out[[l]]) <- species
    rownames(out[[l]]) <- as.character(Spat_cov)
  }
  
  # Phase 1: Sequential data preparation (Master Process)
  species_preprocessed_list <- list()
  alerts <- c()
  record_counts <- setNames(rep(0, length(species)), species)
  
  log_msg("Phase 1: Preparing species data sequentially...")
  for (i in seq_along(species)) {
    # DTO-BioFlow Modification: Yield to event loop to detect client abort during sequential data preparation.
    if (!is.null(session)) {
      httpuv::service()
      shiny:::flushReact()
      if (session$isClosed() || (!is.null(session$input$exit_app) && session$input$exit_app > 0)) {
        log_msg("Exit requested or session closed. Aborting pipeline execution.")
        stop("Exit requested or session closed. Aborting pipeline execution.")
      }
    }
    species_name <- species[i]
    taxa <- taxa_levels[i]
    update_progress_safe(amount = 0, detail = paste("Preparing data for:", species_name))
    
    rdata_file <- file.path(dir, type, "Rdata", paste0(species_name, ".RData"))
    map_file <- file.path(dir, type, "records", paste0("records_", species_name, ".png"))
    loaded_from_cache <- FALSE
    
    use_cache <- ifelse(is.null(inputs$use_cache), TRUE, inputs$use_cache)
    
    df_data <- data.frame()
    data_NA <- data.frame()
    
    if (use_cache && file.exists(rdata_file)) {
      tmp_env <- new.env()
      load(rdata_file, envir = tmp_env)
      df_data <- tmp_env$df_data
      if ("data_NA" %in% names(tmp_env)) {
        data_NA <- tmp_env$data_NA
      }
      loaded_from_cache <- TRUE
      rec_count <- nrow(df_data) + nrow(data_NA)
      log_msg(paste0("Loading cached data for species: ", species_name, " (", rec_count, " records)"))
      record_counts[species_name] <- rec_count
      update_progress_safe(amount = 0.7 / length(species), detail = paste("Loaded cached data for:", species_name))
    } else {
      # Translate "species" back to Geoserver column "scientificname_accepted"
      query_taxa_level <- ifelse(taxa == "species", "scientificname_accepted", taxa)
      cql_filter <- paste0(query_taxa_level, " = '", species_name, "'", add)
      
      data_extracted <- tryCatch({
        # DTO-BioFlow Modification: Passed update_progress and session down to download helper for logging & abort monitoring.
        emodnet_get_layers_paged(wfs_bio = wfs_bio, cql_filter = cql_filter, log_callback = log_msg, update_progress = update_progress_safe, session = session, progress_weight = 0.7 / length(species)) 
      }, error = function(e) {
        log_msg(paste("WFS extraction failed for", species_name, ":", conditionMessage(e)))
        NULL
      })
      
      if (!is.null(data_extracted) && nrow(data_extracted) > 0) {
        # Optimize spatial extraction by extracting ecoregions only for unique coordinate pairs
        unique_coords <- data_extracted %>% 
          dplyr::distinct(longitude, latitude) %>% 
          dplyr::filter(!is.na(longitude) & !is.na(latitude))
        
        pts_unique <- terra::vect(as.matrix(unique_coords), crs = "+proj=longlat +datum=WGS84")
        points_unique <- terra::extract(grid, pts_unique)
        # Handle points on polygon boundaries that return multiple rows from extract
        points_unique <- points_unique[!duplicated(points_unique$id.y), ]
        
        unique_coords_mapped <- cbind(unique_coords, points_unique)
        unique_coords_mapped <- unique_coords_mapped %>% dplyr::select(longitude, latitude, ID, Ecoregion)
        
        data_all <- dplyr::left_join(data_extracted, unique_coords_mapped, by = c("longitude", "latitude"))
        data_all$id.y <- 1:nrow(data_all)
        
        data_NA <- data_all[is.na(data_all$Ecoregion),]
        df_data <- data_all[!is.na(data_all$Ecoregion),] 
        ifelse(nrow(data_all) == nrow(data_NA) + nrow(df_data), "OK", stop("TO CHECK"))
        
        save(df_data, data_NA, file = rdata_file)
        rec_count <- nrow(data_extracted)
        log_msg(paste0("Downloaded ", rec_count, " records for species: ", species_name))
        record_counts[species_name] <- rec_count
      }
    }
    
    if (is.null(df_data) || nrow(df_data) == 0) {
      msg <- paste0("for taxa ", species_name, ": 0 extracted rows, please check spelling before going on")
      log_msg(paste("Warning:", msg))
      alerts <- c(alerts, msg)
      species_preprocessed_list[[species_name]] <- list(df_data = NULL, alert = msg)
      next
    }
    
    if (!loaded_from_cache || !file.exists(map_file)) {
      crspoints <- "+proj=longlat +datum=WGS84"
      
      # Plot unique coordinates to avoid plotting millions of overlapping points (which takes a long time and lots of memory)
      unique_pts_df <- df_data %>% dplyr::distinct(longitude, latitude)
      pts <- vect(as.matrix(unique_pts_df), crs = crspoints)
      
      png(file=map_file, width = 240, height = 180, units="mm", res=400)
      terra::plot(grid, cex=0.3)
      if (exists("data_NA") && nrow(data_NA) > 0) {
        unique_pts_NA <- data_NA %>% dplyr::distinct(longitude, latitude)
        pts_NA <- vect(as.matrix(unique_pts_NA), crs = crspoints)
        points(pts_NA, col="red", cex=0.5)
      }
      points(pts, col="green", cex=0.5)
      legend(x=57, y=36, legend = c("OCC","NA"), pch = 20, xpd=NA, bg="white", col=c("green","red"))
      dev.off()
    }
    
    Ecoregion <- as.data.frame(grid) %>% group_by(Ecoregion) %>% reframe(ncell=n())
    df_data <- left_join(df_data, Ecoregion, by = join_by(Ecoregion))
    
    df_data$geom <- ifelse(is.na(df_data$the_geom), "geom_shape", "geom_point")
    
    df_data$time <- ifelse(is.na(df_data$timeofday), 
                           ifelse(is.na(df_data$monthcollected), "annual", "month_season"), 
                           "day_week")
    
    df_data$tax <- ifelse(!is.na(df_data$species), "species",
                          ifelse(!is.na(df_data$genus), "genus",
                                 ifelse(!is.na(df_data$family), "family", "order_class")))
    
    species_preprocessed_list[[species_name]] <- list(df_data = df_data, alert = NULL)
  }

  # Phase 2: Parallel or Sequential scoring calculations
  run_in_parallel <- FALSE
  if (length(species) > 1) {
    # Check if any species dataset is large (e.g. > 100,000 rows)
    has_large_dataset <- FALSE
    for (sp_name in names(species_preprocessed_list)) {
      sp_df <- species_preprocessed_list[[sp_name]]$df_data
      if (!is.null(sp_df) && nrow(sp_df) > 100000) {
        has_large_dataset <- TRUE
        break
      }
    }
    
    if (has_large_dataset) {
      log_msg("Large dataset detected (>100,000 rows). Running sequentially to avoid socket connection crashes.")
    } else {
      cl <- tryCatch({
        # Cap cores safely to leave resources for other computer processes (leave at least 2 cores free, max 4 cores)
        num_cores <- max(1, min(parallel::detectCores() - 2, length(species), 4))
        parallel::makeCluster(num_cores, timeout = 5, outfile = file.path(dir, "worker.log"))
      }, error = function(e) {
        log_msg(paste("Parallel cluster creation failed, falling back to sequential execution:", conditionMessage(e)))
        NULL
      })
      
      if (!is.null(cl)) {
        run_in_parallel <- TRUE
        on.exit(tryCatch(parallel::stopCluster(cl), error = function(e) NULL), add = TRUE)
        
        # Export working directory first so workers can source function.R locally
        parallel::clusterExport(cl, "dir", envir = environment())
        
        parallel::clusterEvalQ(cl, {
          library(dplyr)
          library(tidyverse)
          # DTO-BioFlow Modification: Sourced function.R from utilities directory and updated env for missing_data_matrix.
          source(file.path(dir, "utilities", "function.R"))
          # Decouple environments of functions on the workers
          environment(missing_data_matrix) <- globalenv()
          environment(process_single_species_scoring) <- globalenv()
        })
        
        parallel::clusterExport(cl, varlist = c(
          "species_preprocessed_list", "type", "species", "Spat_cov", "Temp_cov",
          "Tax_res", "Temp_res", "Spat_res", "nrow_val", "taxa_folder_name"
        ), envir = environment())
      }
    }
  }

  if (run_in_parallel) {
    log_msg(paste("Running species calculations in parallel across", length(species), "nodes..."))
    parallel_fun <- function(species_name) {
      df_data <- species_preprocessed_list[[species_name]]$df_data
      process_single_species_scoring(
        species_name = species_name,
        df_data = df_data,
        dir = dir,
        type = type,
        species = species,
        Spat_cov = Spat_cov,
        Temp_cov = Temp_cov,
        Spat_res = Spat_res,
        Temp_res = Temp_res,
        Tax_res = Tax_res,
        nrow_val = nrow_val,
        taxa_folder_name = taxa_folder_name
      )
    }
    environment(parallel_fun) <- globalenv()
    results <- parallel::parLapply(cl, species, parallel_fun)
    update_progress_safe(amount = 0.3, detail = "Calculated scores in parallel for all species.")
  } else {
    log_msg("Running species calculations sequentially...")
    results <- vector("list", length(species))
    pb = txtProgressBar(min=0, max=length(species), initial=0, style=3, width=length(species), char="=") 
    for (i in seq_along(species)) {
      # DTO-BioFlow Modification: Yield control to Shiny event loop to detect client abort during sequential scoring.
      if (!is.null(session)) {
        httpuv::service()
        shiny:::flushReact()
        if (session$isClosed() || (!is.null(session$input$exit_app) && session$input$exit_app > 0)) {
          log_msg("Exit requested or session closed. Aborting pipeline execution.")
          stop("Exit requested or session closed. Aborting pipeline execution.")
        }
      }
      species_name <- species[i]
      update_progress_safe(amount = 0.3 / length(species), detail = paste("Calculating scores sequentially for:", species_name))
      df_data <- species_preprocessed_list[[species_name]]$df_data
      results[[i]] <- process_single_species_scoring(
        species_name = species_name,
        df_data = df_data,
        dir = dir,
        type = type,
        species = species,
        Spat_cov = Spat_cov,
        Temp_cov = Temp_cov,
        Spat_res = Spat_res,
        Temp_res = Temp_res,
        Tax_res = Tax_res,
        nrow_val = nrow_val,
        taxa_folder_name = taxa_folder_name,
        session = session
      )
      setTxtProgressBar(pb, i)
    }
    close(pb)
  }

  # Merge single species outputs back into global matrices
  for (i in 1:length(species)) {
    res_out <- results[[i]]
    for (l in 1:length(Temp_cov)) {
      out[[l]][, species[i]] <- res_out[[l]][, 1]
    }
  }

  # Construct the "ALL" sheet
  all_df <- data.frame(matrix(nrow = length(Spat_cov), ncol = length(Temp_cov)))
  colnames(all_df) <- as.character(Temp_cov)
  rownames(all_df) <- as.character(Spat_cov)
  
  for (j in 1:length(Spat_cov)) {
    for (l in 1:length(Temp_cov)) {
      # Get the vector of scores for all species at this Ecoregion and Time Range
      vals <- as.numeric(out[[l]][j, ])
      # Compute the 1st quartile
      all_df[j, l] <- quantile(vals, probs = 0.25, na.rm = TRUE)
    }
  }
  
  out[["ALL"]] <- all_df

  # Write out to Excel using openxlsx2 with customized rownames column headers
  wb <- openxlsx2::wb_workbook()
  
  # Register conditional formatting dxf styles
  wb$add_dxfs_style(name = "green_unlikely", bg_fill = wb_color("#c3e6cb"), font_color = wb_color("#000000"))
  wb$add_dxfs_style(name = "yellow_likely", bg_fill = wb_color("#ffff00"), font_color = wb_color("#000000"))
  wb$add_dxfs_style(name = "red_very_likely", bg_fill = wb_color("#f5c6cb"), font_color = wb_color("#000000"))

  # Add the Execution_log worksheet as the first sheet
  wb$add_worksheet("Execution_log")
  
  # README text
  readme_text <- 'Here the assessment of missing data within EMODnet Biology is showed. For each phyla, and for each area (i.e. spatial coverage) a percentage of missing data from 0 to 1 is calculated togheter with first quartile both by taxa and area. The analysis was repeated for each time range previously selected and showed in different sheets. Furthermore, a summary of first quartile values for each area and time range is showed in "ALL" sheet following temporal, spatial and taxonomic aggregations described here.'
  wb$add_data(sheet = "Execution_log", x = readme_text, dims = "A1")
  wb$merge_cells(sheet = "Execution_log", cols = 1:10, rows = 1)
  wb$add_font(sheet = "Execution_log", dims = "A1", size = 11)
  
  # Selected temporal coverages
  selected_temps <- inputs$temp_cov
  hist_years <- selected_temps[selected_temps %in% c("1880_1909", "1910_1939", "1940_1969", "1970_1999")]
  pres_years <- selected_temps[selected_temps %in% c("2000_2009", "2010_2019", "2020_2026")]

  # Selected spatial coverages
  selected_spats <- inputs$spat_cov
  fao37_eco <- selected_spats[selected_spats %in% c("Adriatic Sea", "Aegean-Levantine Sea", "Ionian Sea and the Central Mediterranean Sea", "Western Mediterranean Sea", "Black Sea")]
  fao27_eco <- selected_spats[selected_spats %in% c("Arctic Ocean", "Azores", "Baltic Sea", "Barents Sea", "Bay of Biscay and the Iberian Coast", "Celtic Seas", "Faroes", "Greater North Sea", "Greenland Sea", "Iceland Sea", "Norwegian Sea", "Oceanic Northeast Atlantic")]

  fao37_eco_all <- c("Adriatic Sea", "Aegean-Levantine Sea", "Ionian Sea and the Central Mediterranean Sea", "Western Mediterranean Sea", "Black Sea")
  fao27_eco_all <- c("Arctic Ocean", "Azores", "Baltic Sea", "Barents Sea", "Bay of Biscay and the Iberian Coast", "Celtic Seas", "Faroes", "Greater North Sea", "Greenland Sea", "Iceland Sea", "Norwegian Sea", "Oceanic Northeast Atlantic")

  # Headers
  wb$add_data(sheet = "Execution_log", x = "Time ranges (arranged by sheet):", dims = "A5")
  wb$add_font(sheet = "Execution_log", dims = "A5", bold = TRUE)

  wb$add_data(sheet = "Execution_log", x = "Spatial coverage:", dims = "E5")
  wb$add_font(sheet = "Execution_log", dims = "E5", bold = TRUE)

  wb$add_data(sheet = "Execution_log", x = "Species analyzed:", dims = "J5")
  wb$add_font(sheet = "Execution_log", dims = "J5", bold = TRUE)

  # Table 1: Time ranges
  current_r <- 6
  if (length(hist_years) > 0) {
    wb$add_data(sheet = "Execution_log", x = "Historical", dims = paste0("A", current_r))
    wb$add_font(sheet = "Execution_log", dims = paste0("A", current_r), bold = TRUE, color = wb_color("#7030a0"))
    for (y_idx in seq_along(hist_years)) {
      r_val <- current_r + y_idx - 1
      wb$add_data(sheet = "Execution_log", x = hist_years[y_idx], dims = paste0("B", r_val))
      wb$add_font(sheet = "Execution_log", dims = paste0("B", r_val), color = wb_color("#7030a0"))
    }
    last_r <- current_r + length(hist_years) - 1
    wb$add_border(sheet = "Execution_log", dims = paste0("A", last_r, ":B", last_r), bottom_border = "thin", left_border = "", right_border = "", top_border = "")
    wb$add_border(sheet = "Execution_log", dims = paste0("B", current_r, ":B", last_r), left_border = "thin", right_border = "thin", top_border = "", bottom_border = "")
    current_r <- current_r + length(hist_years)
  }

  if (length(pres_years) > 0) {
    wb$add_data(sheet = "Execution_log", x = "Present", dims = paste0("A", current_r))
    wb$add_font(sheet = "Execution_log", dims = paste0("A", current_r), bold = TRUE, color = wb_color("#cc00cc"))
    for (y_idx in seq_along(pres_years)) {
      r_val <- current_r + y_idx - 1
      wb$add_data(sheet = "Execution_log", x = pres_years[y_idx], dims = paste0("B", r_val))
      wb$add_font(sheet = "Execution_log", dims = paste0("B", r_val), color = wb_color("#cc00cc"))
    }
    last_r <- current_r + length(pres_years) - 1
    wb$add_border(sheet = "Execution_log", dims = paste0("A", last_r, ":B", last_r), bottom_border = "thin", left_border = "", right_border = "", top_border = "")
    wb$add_border(sheet = "Execution_log", dims = paste0("B", current_r, ":B", last_r), left_border = "thin", right_border = "thin", top_border = "", bottom_border = "")
    current_r <- current_r + length(pres_years)
  }

  # Table 2: Spatial coverage
  current_spat_r <- 6
  if (length(fao37_eco) > 0) {
    wb$add_data(sheet = "Execution_log", x = "FAO 37", dims = paste0("E", current_spat_r))
    wb$add_font(sheet = "Execution_log", dims = paste0("E", current_spat_r), bold = TRUE, color = wb_color("#385723"))
    for (e_idx in seq_along(fao37_eco)) {
      r_val <- current_spat_r + e_idx - 1
      wb$add_data(sheet = "Execution_log", x = fao37_eco[e_idx], dims = paste0("F", r_val))
      wb$add_font(sheet = "Execution_log", dims = paste0("F", r_val), color = wb_color("#385723"))
    }
    last_r <- current_spat_r + length(fao37_eco) - 1
    wb$add_border(sheet = "Execution_log", dims = paste0("E", last_r, ":F", last_r), bottom_border = "thin", left_border = "", right_border = "", top_border = "")
    wb$add_border(sheet = "Execution_log", dims = paste0("F", current_spat_r, ":F", last_r), left_border = "thin", right_border = "thin", top_border = "", bottom_border = "")
    current_spat_r <- current_spat_r + length(fao37_eco)
  }

  if (length(fao27_eco) > 0) {
    wb$add_data(sheet = "Execution_log", x = "FAO 27", dims = paste0("E", current_spat_r))
    wb$add_font(sheet = "Execution_log", dims = paste0("E", current_spat_r), bold = TRUE, color = wb_color("#595959"))
    for (e_idx in seq_along(fao27_eco)) {
      r_val <- current_spat_r + e_idx - 1
      wb$add_data(sheet = "Execution_log", x = fao27_eco[e_idx], dims = paste0("F", r_val))
      wb$add_font(sheet = "Execution_log", dims = paste0("F", r_val), color = wb_color("#595959"))
    }
    last_r <- current_spat_r + length(fao27_eco) - 1
    wb$add_border(sheet = "Execution_log", dims = paste0("E", last_r, ":F", last_r), bottom_border = "thin", left_border = "", right_border = "", top_border = "")
    wb$add_border(sheet = "Execution_log", dims = paste0("F", current_spat_r, ":F", last_r), left_border = "thin", right_border = "thin", top_border = "", bottom_border = "")
    current_spat_r <- current_spat_r + length(fao27_eco)
  }

  # Table 3: Species analyzed
  wb$add_data(sheet = "Execution_log", x = "Macrogroup", dims = "J6")
  wb$add_font(sheet = "Execution_log", dims = "J6", bold = TRUE)

  wb$add_data(sheet = "Execution_log", x = "Species", dims = "K6")
  wb$add_font(sheet = "Execution_log", dims = "K6", bold = TRUE)

  wb$add_data(sheet = "Execution_log", x = "ALL", dims = "J7")
  wb$add_font(sheet = "Execution_log", dims = "J7", bold = TRUE, color = wb_color("#0b5a82"))

  for (s_idx in seq_along(species)) {
    col_letter <- int2col(10 + s_idx)
    cell_coord <- paste0(col_letter, "7")
    wb$add_data(sheet = "Execution_log", x = species[s_idx], dims = cell_coord)
    wb$add_font(sheet = "Execution_log", dims = cell_coord, color = wb_color("#0b5a82"))
  }

  last_col_idx <- 10 + length(species)
  headers_dims <- paste0("J6:", int2col(last_col_idx), "6")
  wb$add_border(sheet = "Execution_log", dims = headers_dims, bottom_border = "thin", left_border = "", right_border = "", top_border = "")

  data_row_dims <- paste0("J7:", int2col(last_col_idx), "7")
  wb$add_border(sheet = "Execution_log", dims = data_row_dims, bottom_border = "thin", left_border = "", right_border = "", top_border = "")
  wb$add_border(sheet = "Execution_log", dims = "J6:J7", right_border = "thin", left_border = "", top_border = "", bottom_border = "")

  # Execution Alerts / Warnings section
  alert_start_row <- max(current_r, current_spat_r, 8) + 3
  wb$add_data(sheet = "Execution_log", x = "Execution Alerts / Warnings", dims = paste0("A", alert_start_row))
  wb$add_font(sheet = "Execution_log", dims = paste0("A", alert_start_row), bold = TRUE, size = 11)
  
  if (length(alerts) > 0) {
    for (idx in 1:length(alerts)) {
      r_val <- alert_start_row + idx
      wb$add_data(sheet = "Execution_log", x = alerts[idx], dims = paste0("A", r_val))
      wb$add_font(sheet = "Execution_log", dims = paste0("A", r_val), color = openxlsx2::wb_color("#ff0000"), size = 10)
    }
  } else {
    r_val <- alert_start_row + 1
    wb$add_data(sheet = "Execution_log", x = "No warnings. All taxa extracted successfully.", dims = paste0("A", r_val))
    wb$add_font(sheet = "Execution_log", dims = paste0("A", r_val), color = openxlsx2::wb_color("#2b8a3e"), size = 10)
  }

  wb$set_col_widths(sheet = "Execution_log", cols = 1:(last_col_idx + 1), widths = "auto")
  wb$set_grid_lines(sheet = "Execution_log", show = TRUE)

  for (sheet_name in names(out)) {
    wb$add_worksheet(sheet_name)
    
    # Calculate grid data frame to write
    if (sheet_name == "ALL") {
      df_to_write <- out[[sheet_name]]
    } else {
      raw_matrix <- as.data.frame(out[[sheet_name]])
      species_cols <- colnames(raw_matrix)
      
      matrix_with_stats <- raw_matrix
      matrix_with_stats$`1st_Quartile` <- apply(raw_matrix[species_cols], 1, quantile, probs = 0.25, na.rm = TRUE)
      
      col_quartiles <- apply(matrix_with_stats[species_cols], 2, quantile, probs = 0.25, na.rm = TRUE)
      col_summary_row <- c(col_quartiles, NA)
      names(col_summary_row) <- c(species_cols, "1st_Quartile")
      
      df_to_write <- rbind(matrix_with_stats, col_summary_row)
      rownames(df_to_write)[nrow(df_to_write)] <- "1st_Quartile"
    }

    wb$add_data(
      sheet = sheet_name,
      x = df_to_write,
      row_names = TRUE,
      col_names = TRUE
    )
    
    # Write "ALL TAXA" to cell A1
    wb$add_data(
      sheet = sheet_name,
      x = "ALL TAXA",
      dims = "A1"
    )
    wb$add_font(sheet = sheet_name, dims = "A1", bold = TRUE)

    # Format numbers as percentage
    dims_grid <- wb_dims(rows = 2:(nrow(df_to_write) + 1), cols = 2:(ncol(df_to_write) + 1))
    wb$add_numfmt(sheet = sheet_name, dims = dims_grid, numfmt = "0.0%")

    # Color Ecoregion names in Column A
    num_ecoregions <- nrow(out[[sheet_name]])
    for (r_idx in 1:num_ecoregions) {
      r_val <- r_idx + 1
      eco_name <- rownames(out[[sheet_name]])[r_idx]
      cell_coord <- paste0("A", r_val)
      
      if (eco_name %in% fao37_eco_all) {
        wb$add_font(sheet = sheet_name, dims = cell_coord, color = wb_color("#385723"), bold = TRUE)
      } else if (eco_name %in% fao27_eco_all) {
        wb$add_font(sheet = sheet_name, dims = cell_coord, color = wb_color("#595959"), bold = TRUE)
      }
    }

    # Color Column Headers in "ALL" sheet (time range names)
    if (sheet_name == "ALL") {
      num_cols <- ncol(out[["ALL"]])
      for (c_idx in 1:num_cols) {
        col_val <- c_idx + 1
        time_range <- colnames(out[["ALL"]])[c_idx]
        cell_coord <- paste0(int2col(col_val), "1")
        
        if (time_range %in% c("1880_1909", "1910_1939", "1940_1969", "1970_1999")) {
          wb$add_font(sheet = sheet_name, dims = cell_coord, color = wb_color("#7030a0"), bold = TRUE)
        } else if (time_range %in% c("2000_2009", "2010_2019", "2020_2026")) {
          wb$add_font(sheet = sheet_name, dims = cell_coord, color = wb_color("#cc00cc"), bold = TRUE)
        }
      }
      
      # For ALL sheet: apply 3-level conditional formatting to all data cells
      wb$add_conditional_formatting(sheet = sheet_name, dims = dims_grid, type = "expression", rule = "<=0.33", style = "green_unlikely")
      wb$add_conditional_formatting(sheet = sheet_name, dims = dims_grid, type = "between", rule = c(0.330001, 0.660000), style = "yellow_likely")
      wb$add_conditional_formatting(sheet = sheet_name, dims = dims_grid, type = "expression", rule = ">0.66", style = "red_very_likely")
      
    } else {
      # Make "1st_Quartile" row name and col name bold
      wb$add_font(sheet = sheet_name, dims = paste0("A", nrow(df_to_write) + 1), bold = TRUE)
      wb$add_font(sheet = sheet_name, dims = paste0(int2col(ncol(df_to_write) + 1), "1"), bold = TRUE)
      
      # Add medium borders to separate 1st quartile row/col
      # Left border for 1st_Quartile column
      wb$add_border(sheet = sheet_name, dims = wb_dims(rows = 1:(nrow(df_to_write) + 1), cols = ncol(df_to_write) + 1), left_border = "medium", top_border = "", bottom_border = "", right_border = "")
      # Top border for 1st_Quartile row
      wb$add_border(sheet = sheet_name, dims = wb_dims(rows = nrow(df_to_write) + 1, cols = 1:(ncol(df_to_write) + 1)), top_border = "medium", left_border = "", bottom_border = "", right_border = "")
      
      # Apply conditional formatting to the 1st_Quartile column
      dims_col_q <- wb_dims(rows = 2:nrow(df_to_write), cols = ncol(df_to_write) + 1)
      wb$add_conditional_formatting(sheet = sheet_name, dims = dims_col_q, type = "expression", rule = "<=0.33", style = "green_unlikely")
      wb$add_conditional_formatting(sheet = sheet_name, dims = dims_col_q, type = "between", rule = c(0.330001, 0.660000), style = "yellow_likely")
      wb$add_conditional_formatting(sheet = sheet_name, dims = dims_col_q, type = "expression", rule = ">0.66", style = "red_very_likely")
      
      # Apply conditional formatting to the 1st_Quartile row
      dims_row_q <- wb_dims(rows = nrow(df_to_write) + 1, cols = 2:ncol(df_to_write))
      wb$add_conditional_formatting(sheet = sheet_name, dims = dims_row_q, type = "expression", rule = "<=0.33", style = "green_unlikely")
      wb$add_conditional_formatting(sheet = sheet_name, dims = dims_row_q, type = "between", rule = c(0.330001, 0.660000), style = "yellow_likely")
      wb$add_conditional_formatting(sheet = sheet_name, dims = dims_row_q, type = "expression", rule = ">0.66", style = "red_very_likely")
    }

    # Add first quartile likelihood legend at the end of each sheet
    start_row <- nrow(df_to_write) + 5
    
    wb$add_data(sheet = sheet_name, x = "Colour legend", dims = paste0("A", start_row))
    wb$add_font(sheet = sheet_name, dims = paste0("A", start_row), bold = TRUE, size = 11)
    
    wb$add_data(sheet = sheet_name, x = "(X = first quartile)", dims = paste0("A", start_row + 1))
    wb$add_data(sheet = sheet_name, x = "LIKELIHOOD", dims = paste0("B", start_row + 1))
    wb$add_font(sheet = sheet_name, dims = paste0("A", start_row + 1, ":B", start_row + 1), bold = TRUE, size = 11)
    
    wb$add_data(sheet = sheet_name, x = "X <= 33%", dims = paste0("A", start_row + 2))
    wb$add_data(sheet = sheet_name, x = "UNLIKELY", dims = paste0("B", start_row + 2))
    wb$add_data(sheet = sheet_name, x = "the percentage of missing data at the first quartile (25th percentile) is less than or equal to 33%", dims = paste0("C", start_row + 2))
    
    wb$add_data(sheet = sheet_name, x = "33% < X <= 66%", dims = paste0("A", start_row + 3))
    wb$add_data(sheet = sheet_name, x = "LIKELY", dims = paste0("B", start_row + 3))
    wb$add_data(sheet = sheet_name, x = "the percentage of missing data at the first quartile (25th percentile) is between 33% and 66%", dims = paste0("C", start_row + 3))
    
    wb$add_data(sheet = sheet_name, x = "X > 66%", dims = paste0("A", start_row + 4))
    wb$add_data(sheet = sheet_name, x = "VERY LIKELY", dims = paste0("B", start_row + 4))
    wb$add_data(sheet = sheet_name, x = "the percentage of missing data at the first quartile (25th percentile) is greater than 66%", dims = paste0("C", start_row + 4))
    
    # Apply fills and black text for green/yellow/red
    wb$add_fill(sheet = sheet_name, dims = paste0("A", start_row + 2, ":B", start_row + 2), color = openxlsx2::wb_color("#c3e6cb")) # Green
    wb$add_font(sheet = sheet_name, dims = paste0("A", start_row + 2, ":B", start_row + 2), color = openxlsx2::wb_color("#000000"), bold = TRUE)

    wb$add_fill(sheet = sheet_name, dims = paste0("A", start_row + 3, ":B", start_row + 3), color = openxlsx2::wb_color("#ffff00")) # Yellow
    wb$add_font(sheet = sheet_name, dims = paste0("A", start_row + 3, ":B", start_row + 3), color = openxlsx2::wb_color("#000000"), bold = TRUE)

    wb$add_fill(sheet = sheet_name, dims = paste0("A", start_row + 4, ":B", start_row + 4), color = openxlsx2::wb_color("#f5c6cb")) # Red
    wb$add_font(sheet = sheet_name, dims = paste0("A", start_row + 4, ":B", start_row + 4), color = openxlsx2::wb_color("#000000"), bold = TRUE)

    # Set centering
    wb$add_cell_style(sheet = sheet_name, dims = paste0("A", start_row + 2, ":B", start_row + 4), horizontal = "center")
    
    # Border for the legend table
    wb$add_border(sheet = sheet_name, dims = paste0("A", start_row + 1, ":C", start_row + 4), left_border = "thin", right_border = "thin", top_border = "thin", bottom_border = "thin")

    # Set gridlines and column widths for the entire sheet
    wb$set_col_widths(sheet = sheet_name, cols = 1:(ncol(df_to_write) + 1), widths = "auto")
    wb$set_grid_lines(sheet = sheet_name, show = TRUE)
  }
  wb$save(file.path(taxa_output_dir, "Missing data by TempCov.xlsx"))

  attr(out, "alerts") <- alerts
  attr(out, "record_counts") <- record_counts
  return(out)
}
