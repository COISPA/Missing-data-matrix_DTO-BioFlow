#------------------------------Authorship---------------------------------------#
#title: "function"
#lead author: Matteo Chiarini
#contributors: Maria Teresa Spedicato, Walter Zupa, Cosmidano Neglia, Isabella Bitetto, Pierluigi Carbonara, Lola Toomey
#date: "2025-07-19"
#institute: "Fondazione COISPA ETS, Via dei Trulli 18/20 - (Bari), Italy"
#contact: chiarini@fondazionecoispa.org

# DTO-BioFlow Modification: Renamed skills_matrix function to missing_data_matrix as part of the Missing Data Matrix renaming.
missing_data_matrix <- function (df_data, db_empty,species,Spat_cov,Temp_cov,Spat_res,Temp_res,Tax_res) {
  
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
    
    # Estrazione lineare originale con esclusione preventiva di record orfani (NA)
    dt <- df_data[df_data$Ecoregion %in% dq$Spat_cov &
                    df_data$yearcollected %in% years &
                    df_data$geom <= dq$Spat_res &
                    df_data$time <= dq$Temp_res &
                    df_data$tax <= dq$Tax_res & 
                    !is.na(df_data$Ecoregion), ] 
    
    if (nrow(dt) == 0){
      db2[z,c(1:5)] <- 1
    } else {
      
      # Spatial Coverage
      db2[z,1] <- 1-(length(unique(dt$ID))/unique(dt$ncell)[1])
      
      # Temporal Coverage 
      db2[z,2] <- 1-(length(unique(dt$yearcollected))/length(years))
      
      # Spatial Resolution
      if (all(dt$geom <= dq$Spat_res, na.rm = TRUE)) {
        db2[z,3] <- 0
      } else {
        stop("Spatial Resolution extraction error")
      }
      
      # Temporal Resolution
      if (all(dt$time <= dq$Temp_res, na.rm = TRUE)) {
        db2[z,4] <- 0
      } else {
        stop("Temporal Resolution extraction error")
      }
      
      # Taxonomical Resolution
      if (all(dt$tax <= dq$Tax_res, na.rm = TRUE)) {
        db2[z,5] <- 0
      } else {
        stop("Taxonomical Resolution extraction error")
      }
    }
    
    db_empty[z,6] <- mean(as.numeric(db2[z,c(1:5)]), na.rm = TRUE)
    
  }
  
  db <- db_empty %>% summarize(MD=sum(score)/nrow(db_empty))
  #return(percent(as.numeric(db)))
  return(as.numeric(db$MD))
}

unregister <- function() {
  env <- foreach:::.foreachGlobals
  rm(list=ls(name=env), pos=env)
}

process_single_species_scoring <- function(species_name, df_data, dir, type, species, Spat_cov, Temp_cov, Spat_res, Temp_res, Tax_res, nrow_val, taxa_folder_name = paste(species, collapse = "_"), session = NULL) {
  # Generate sub-folder output path for the taxa group
  taxa_output_dir <- file.path(dir, type, "Outputs", taxa_folder_name)
  
  # Setup local results list for this species
  out_local <- vector("list", length(Temp_cov))
  names(out_local) <- Temp_cov
  for(l in 1:length(Temp_cov)) {
    out_local[[l]] <- data.frame(matrix(nrow = length(Spat_cov), ncol = 1))
    colnames(out_local[[l]]) <- species_name
    rownames(out_local[[l]]) <- as.character(Spat_cov)
  }
  
  if (is.null(df_data) || nrow(df_data) == 0) {
    for (l in 1:length(Temp_cov)) {
      out_local[[l]][, 1] <- 1.0
    }
    return(out_local)
  }
  
  db_empty = data.frame(Spat_cov=rep(Spat_cov, times=nrow_val/nlevels(Spat_cov)))
  db_empty <- db_empty %>% group_by(Spat_cov) %>% reframe(Temp_cov)
  db_empty <- db_empty %>% group_by(Spat_cov,Temp_cov) %>% reframe(Spat_res)
  db_empty <- db_empty %>% group_by(Spat_cov,Temp_cov,Spat_res) %>% reframe(Temp_res)
  db_empty <- db_empty %>% group_by(Spat_cov,Temp_cov,Spat_res,Temp_res) %>% reframe(Tax_res)
  db_empty$score = NA
  db_empty$Species = species_name
  
  db_local = data.frame(matrix(nrow=length(Spat_cov), ncol=1))
  names(db_local) = species_name
  rownames(db_local) = Spat_cov
  
  for (l in 1:length(Temp_cov)){
    # DTO-BioFlow Modification: Periodically yield control to Shiny event loop during sequential runs to detect abort button or window closure.
    if (!is.null(session)) {
      httpuv::service()
      shiny:::flushReact()
      if (session$isClosed() || (!is.null(session$input$exit_app) && session$input$exit_app > 0)) {
        stop("Exit requested or session closed. Aborting scoring.")
      }
    }
    for (j in 1:length(Spat_cov)){
      # DTO-BioFlow Modification: Updated call to missing_data_matrix.
      db_local[j, 1] = missing_data_matrix(df_data, db_empty, species_name, Spat_cov[j], Temp_cov[l], Spat_res, Temp_res, Tax_res)
    }
    
    write.table(db_local, file.path(taxa_output_dir, paste0("Missing data Matrix_", Temp_cov[l], ".csv")), sep=",", dec=".")
    out_local[[l]][, 1] <- as.numeric(db_local[, 1])
  }
  return(out_local)
}

# DTO-BioFlow Modification: Added progress log callback to WFS download chunks helper.
# DTO-BioFlow Modification: Added progress updates and session closed abort check to emodnet_get_layers_paged.
emodnet_get_layers_paged <- function(wfs_bio, cql_filter, log_callback = NULL, update_progress = NULL, session = NULL, progress_weight = 0.7) {
  # Helper to route logs
  log_msg <- function(msg) {
    if (!is.null(log_callback)) {
      log_callback(msg)
    } else {
      cat(msg, "\n")
    }
  }

  # Helper to route progress with weight
  update_progress_local <- function(amount = 0, detail = NULL) {
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

  # 1. Get the total number of records matching the filter using WFS resultType=hits
  base_url <- wfs_bio$getUrl()
  base_url <- sub("[/?]+$", "", base_url)
  
  url_hits <- paste0(
    base_url, 
    "?service=WFS&version=2.0.0&request=GetFeature&typeNames=Dataportal:eurobis",
    "&cql_filter=", utils::URLencode(cql_filter),
    "&resultType=hits"
  )
  
  total_records <- tryCatch({
    h_res <- httr::GET(url_hits)
    content <- httr::content(h_res, as = "text", encoding = "UTF-8")
    xml <- xml2::read_xml(content)
    root <- xml2::xml_find_first(xml, "/*")
    as.numeric(xml2::xml_attr(root, "numberMatched"))
  }, error = function(e) {
    # If the hits query fails, default to NA (which will trigger standard download)
    NA
  })
  
  # Default limit per page
  chunk_size <- 20000 # 20,000 records per page allows frequent yielding to event loop for abort detection
  
  if (is.na(total_records) || total_records <= chunk_size) {
    # DTO-BioFlow Modification: Yield to event loop to detect client abort before direct download.
    if (!is.null(session)) {
      httpuv::service()
      shiny:::flushReact()
      if (session$isClosed() || (!is.null(session$input$exit_app) && session$input$exit_app > 0)) {
        log_msg("Exit requested or session closed. Aborting download.")
        stop("Exit requested or session closed. Aborting download.")
      }
    }
    # Download directly in a single request (or use standard emodnet_get_layers)
    msg <- paste0("Downloading data directly (total records: ", total_records, ")...")
    log_msg(msg)
    update_progress_local(amount = progress_weight, detail = paste("Download in progress:", total_records, "records"))
    return(emodnet_get_layers(
      wfs = wfs_bio, 
      layers = "eurobis", 
      cql_filter = cql_filter, 
      reduce_layers = TRUE, 
      crs = 4326, 
      outputFormat = "CSV",
      propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted"
    ))
  } else {
    # Download in chunks of chunk_size using paging
    pages <- seq(0, total_records, by = chunk_size)
    msg <- paste0("Total records (", total_records, ") exceeds chunk size (", chunk_size, "). Downloading in ", length(pages), " pages...")
    log_msg(msg)
    update_progress_local(amount = 0, detail = paste("Paging download:", total_records, "records in", length(pages), "chunks"))
    
    list_dfs <- list()
    chunk_weight <- progress_weight / length(pages)
    
    for (i in seq_along(pages)) {
      # DTO-BioFlow Modification: Yield control to Shiny event loop to process events and detect exit requests or window closures during paging downloads.
      if (!is.null(session)) {
        httpuv::service()
        shiny:::flushReact()
        if (session$isClosed() || (!is.null(session$input$exit_app) && session$input$exit_app > 0)) {
          log_msg("Exit requested or session closed. Aborting download.")
          stop("Exit requested or session closed. Aborting download.")
        }
      }
      
      start_idx <- pages[i]
      start_idx_str <- sprintf("%.0f", start_idx)
      msg_chunk <- paste0("Downloading chunk ", i, " of ", length(pages), " (startIndex: ", start_idx_str, ")...")
      log_msg(msg_chunk)
      update_progress_local(amount = chunk_weight, detail = paste("Downloading chunk", i, "of", length(pages), "(startIndex:", start_idx_str, ")"))
      
      chunk_data <- tryCatch({
        emodnet_get_layers(
          wfs = wfs_bio, 
          layers = "eurobis", 
          cql_filter = cql_filter, 
          reduce_layers = TRUE, 
          crs = 4326, 
          outputFormat = "CSV",
          propertyName = "id,scientificname,kingdom,phylum,class,order,family,genus,subgenus,species,subspecies,yearcollected,monthcollected,daycollected,timeofday,country,longitude,latitude,season,the_geom,aphiaidaccepted,scientificname_accepted",
          count = sprintf("%.0f", chunk_size),
          startIndex = start_idx_str,
          sortBy = "id"
        )
      }, error = function(e) {
        log_msg(paste0("Error downloading chunk starting at index ", start_idx_str, ": ", conditionMessage(e)))
        NULL
      })
      
      if (!is.null(chunk_data) && nrow(chunk_data) > 0) {
        if (!all(c("longitude", "latitude") %in% colnames(chunk_data))) {
          log_msg("Error: WFS query returned an ExceptionReport or invalid columns instead of CSV data. Response preview:")
          print(head(chunk_data, 5))
          stop("WFS query failed: response did not contain expected columns (longitude/latitude).")
        }
        list_dfs[[length(list_dfs) + 1]] <- chunk_data
      }
    }
    
    if (length(list_dfs) == 0) {
      return(NULL)
    }
    
    # Combine all pages
    combined_df <- do.call(rbind, list_dfs)
    return(combined_df)
  }
}