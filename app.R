#------------------------------Authorship---------------------------------------#
# title: "app"
# lead author: Matteo Chiarini
# contributors: Maria Teresa Spedicato, Walter Zupa, Cosmidano Neglia, Isabella Bitetto, Pierluigi Carbonara, Lola Toomey
# date: "2026-05-19"
# institute: "Fondazione COISPA ETS, Via dei Trulli 18/20 - (Bari), Italy"
# contact: chiarini@fondazionecoispa.org

library(shiny)
library(bslib)
library(emodnet.wfs)
library(tidyverse)
library(sf)
library(terra)
library(openxlsx2)
library(DT)
library(plotly)

# DTO-BioFlow Modification: Register asset path and define Light Theme brand settings.
addResourcePath("assets", getwd())

light_theme <- bs_theme(
  version = 5,
  bg = "#f7fafc",
  fg = "#2b303a",
  primary = "#0b4f8c",
  secondary = "#167fc9",
  success = "#00a896",
  base_font = font_google("Inter"),
  heading_font = font_google("Outfit")
)

# Helper function for first quartile legend table
get_first_quartile_legend <- function() {
  HTML('
    <div style="margin-top: 15px; margin-bottom: 25px; max-width: 800px;">
      <h6 style="font-weight: bold; color: #495057; margin-bottom: 10px;">Colour legend (X = first quartile)</h6>
      <table class="table table-bordered text-center align-middle" style="margin-bottom: 0; font-size: 0.85rem; border: 1px solid #dee2e6;">
        <thead>
          <tr style="background-color: #f8f9fa;">
            <th style="width: 25%; font-weight: bold; border: 1px solid #dee2e6; text-align: center;">Percentage Range</th>
            <th style="width: 25%; font-weight: bold; border: 1px solid #dee2e6; text-align: center;">LIKELIHOOD</th>
            <th style="width: 50%; font-weight: bold; text-align: left; border: 1px solid #dee2e6;">Description</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td style="background-color: #c3e6cb; color: black; font-weight: bold; border: 1px solid #dee2e6; text-align: center;">X &lt;= 33%</td>
            <td style="background-color: #c3e6cb; color: black; font-weight: bold; border: 1px solid #dee2e6; text-align: center;">UNLIKELY</td>
            <td style="text-align: left; border: 1px solid #dee2e6;">the percentage of missing data at the first quartile (25th percentile) is less than or equal to 33%</td>
          </tr>
          <tr>
            <td style="background-color: #fcc419; color: black; font-weight: bold; border: 1px solid #dee2e6; text-align: center;">33% &lt; X &lt;= 66%</td>
            <td style="background-color: #fcc419; color: black; font-weight: bold; border: 1px solid #dee2e6; text-align: center;">LIKELY</td>
            <td style="text-align: left; border: 1px solid #dee2e6;">the percentage of missing data at the first quartile (25th percentile) is between 33% and 66%</td>
          </tr>
          <tr>
            <td style="background-color: #f5c6cb; color: black; font-weight: bold; border: 1px solid #dee2e6; text-align: center;">X &gt; 66%</td>
            <td style="background-color: #f5c6cb; color: black; font-weight: bold; border: 1px solid #dee2e6; text-align: center;">VERY LIKELY</td>
            <td style="text-align: left; border: 1px solid #dee2e6;">the percentage of missing data at the first quartile (25th percentile) is greater than 66%</td>
          </tr>
        </tbody>
      </table>
    </div>
  ')
}

# Helper function for comparison legend table
# DTO-BioFlow Modification: Realigned comparative table labels for missingness variations.
get_comparison_legend <- function() {
  HTML('
    <div style="margin-top: 15px; margin-bottom: 25px; max-width: 600px;">
      <h6 style="font-weight: bold; color: #495057; margin-bottom: 10px;">Colour legend (Difference: Focus - Reference)</h6>
      <table class="table table-bordered text-center align-middle" style="margin-bottom: 0; font-size: 0.85rem; border: 1px solid #dee2e6;">
        <thead>
          <tr style="background-color: #f8f9fa;">
            <th style="width: 50%; font-weight: bold; border: 1px solid #dee2e6; text-align: center;">Difference Range (X)</th>
            <th style="width: 50%; font-weight: bold; border: 1px solid #dee2e6; text-align: center;">Description</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td style="background-color: #fcd5d9; color: black; font-weight: bold; border: 1px solid #dee2e6; text-align: center;">X &gt; 60%</td>
            <td style="color: #212529; font-weight: bold; border: 1px solid #dee2e6; text-align: center; background-color: #ffffff;">high increase in missing data</td>
          </tr>
          <tr>
            <td style="background-color: #ffd8be; color: black; font-weight: bold; border: 1px solid #dee2e6; text-align: center;">30% &lt; X &lt;= 60%</td>
            <td style="color: #212529; font-weight: bold; border: 1px solid #dee2e6; text-align: center; background-color: #ffffff;">increase in missing data</td>
          </tr>
          <tr>
            <td style="background-color: #fff3cd; color: black; font-weight: bold; border: 1px solid #dee2e6; text-align: center;">0% &lt; X &lt;= 30%</td>
            <td style="color: #212529; font-weight: bold; border: 1px solid #dee2e6; text-align: center; background-color: #ffffff;">slight increase in missing data</td>
          </tr>
          <tr>
            <td style="background-color: #ffffff; color: black; font-weight: bold; border: 1px solid #dee2e6; text-align: center;">X = 0%</td>
            <td style="color: #212529; font-weight: bold; border: 1px solid #dee2e6; text-align: center; background-color: #ffffff;">no change</td>
          </tr>
          <tr>
            <td style="background-color: #d4edda; color: black; font-weight: bold; border: 1px solid #dee2e6; text-align: center;">X &lt; 0%</td>
            <td style="color: #212529; font-weight: bold; border: 1px solid #dee2e6; text-align: center; background-color: #ffffff;">decrease in missing data (improvement)</td>
          </tr>
        </tbody>
      </table>
    </div>
  ')
}

# =============================================================================
# USER INTERFACE (UI)
# =============================================================================
# DTO-BioFlow Modification: Set Light Theme and style header bar in brand light blue.
ui <- page_sidebar(
  title = tags$div(
    style = "display: flex; justify-content: space-between; align-items: center; width: 100%; font-weight: bold;",
    tags$strong("DTO-BioFlow: Missing Data Matrix Tool"),
    tags$img(src = "assets/utilities/Logo_DTO_Bio-Flow.svg", style = "height: 40px; width: auto; margin-right: 15px;")
  ),
  theme = light_theme,
  tags$head(
    tags$style(HTML("
      /* Custom header bar brand color background */
      .navbar {
        background-color: #e6f0fa !important; /* Soft light brand blue */
        border-bottom: 1px solid #c8dcf0 !important;
      }
      .navbar-brand, .navbar-title {
        color: #0b4f8c !important; /* Brand dark blue */
        font-weight: bold;
      }
      /* Custom CSS Spinner for Shiny recalculating outputs */
      .shiny-plot-output.shiny-recalculating, 
      .datatables.shiny-recalculating, 
      .plotly.shiny-recalculating {
        position: relative;
        opacity: 0.6;
        transition: opacity 250ms ease-in-out;
      }
      .shiny-plot-output.shiny-recalculating::after,
      .datatables.shiny-recalculating::after,
      .plotly.shiny-recalculating::after {
        content: '';
        position: absolute;
        top: 50%;
        left: 50%;
        width: 40px;
        height: 40px;
        margin-top: -20px;
        margin-left: -20px;
        border: 4px solid rgba(0,0,0,0.1);
        border-left-color: #0b4f8c; /* Brand primary color */
        border-radius: 50%;
        animation: shiny-spinner 1s linear infinite;
        z-index: 9999;
      }
      @keyframes shiny-spinner {
        0% { transform: rotate(0deg); }
        100% { transform: rotate(360deg); }
      }
    ")),
    tags$script(HTML("
      $(document).on('shiny:connected', function(event) {
        Shiny.addCustomMessageHandler('clear_log', function(message) {
          var el = document.getElementById('console_log');
          if (el) {
            el.innerText = message;
          }
        });
        Shiny.addCustomMessageHandler('append_log', function(message) {
          var el = document.getElementById('console_log');
          if (el) {
            el.innerText = el.innerText + '\\n' + message;
            // Scroll to bottom
            el.scrollTop = el.scrollHeight;
          }
        });
      });
    "))
  ),
  sidebar = sidebar(
    title = "Configuration Panel",
    width = 380,
    tags$h5("Working Directory", style = "font-weight: bold; margin-top: 10px;"),
    textInput(inputId = "work_dir", label = "Absolute local path", value = getwd()),
    hr(),
    tags$h5("Information extraction", style = "font-weight: bold; margin-top: 10px;"),
    selectInput(inputId = "wfs_service", label = "EMODnet WFS Service Client", choices = c("biology_occurrence_data", "biology_abundance_data"), selected = "biology_occurrence_data"),
    selectizeInput(
      inputId = "species", 
      label = "Target Taxon or Taxa(comma-separated)", 
      choices = NULL, 
      options = list(
        create = TRUE, 
        placeholder = "Select prebuilt group or type custom taxa..."
      )
    ),
    uiOutput("taxa_level_ui"),
    # DTO-BioFlow Modification: Reposition cache toggle checkbox.
    checkboxInput(inputId = "use_cache", label = "Use local cache (if available)", value = TRUE),
    hr(),
    tags$h5("Selection process", style = "font-weight: bold; margin-top: 10px;"),

    # Grouped and colored inputs for Temporal Coverage
    tags$div(
      style = "font-weight: bold; margin-bottom: 5px;", "Temporal Coverage (time-range)"
    ),
    tags$div(
      style = "color: #7030a0; border-left: 3px solid #7030a0; padding-left: 10px; margin-bottom: 10px;",
      tags$div(
        class = "checkbox",
        style = "margin-top: 0; margin-bottom: 5px; color: #7030a0;",
        tags$label(
          tags$input(id = "select_all_historical", type = "checkbox"),
          tags$span("Historical", style = "font-weight: bold; color: #7030a0;")
        )
      ),
      checkboxGroupInput(
        inputId = "temp_cov_historical",
        label = NULL,
        choices = c("1880_1909", "1910_1939", "1940_1969", "1970_1999"),
        selected = character(0)
      )
    ),
    tags$div(
      style = "color: #cc00cc; border-left: 3px solid #cc00cc; padding-left: 10px; margin-bottom: 15px;",
      tags$div(
        class = "checkbox",
        style = "margin-top: 0; margin-bottom: 5px; color: #cc00cc;",
        tags$label(
          tags$input(id = "select_all_present", type = "checkbox"),
          tags$span("Present", style = "font-weight: bold; color: #cc00cc;")
        )
      ),
      # DTO-BioFlow Modification: Clear defaults in present temporal coverage.
      checkboxGroupInput(
        inputId = "temp_cov_present",
        label = NULL,
        choices = c("2000_2009", "2010_2019", "2020_2026"),
        selected = character(0)
      )
    ),

    # Grouped and colored inputs for Spatial Coverage
    tags$div(
      style = "font-weight: bold; margin-bottom: 5px;", "Spatial Coverage (Ecoregion)"
    ),
    tags$div(
      style = "color: #385723; border-left: 3px solid #385723; padding-left: 10px; margin-bottom: 10px;",
      tags$div(
        class = "checkbox",
        style = "margin-top: 0; margin-bottom: 5px; color: #385723;",
        tags$label(
          tags$input(id = "select_all_fao37", type = "checkbox"),
          tags$span("FAO 37", style = "font-weight: bold; color: #385723;")
        )
      ),
      # DTO-BioFlow Modification: Clear defaults in FAO 37 spatial coverage.
      checkboxGroupInput(
        inputId = "spat_cov_fao37",
        label = NULL,
        choices = c(
          "Adriatic Sea", "Aegean-Levantine Sea", "Ionian Sea and the Central Mediterranean Sea",
          "Western Mediterranean Sea", "Black Sea"
        ),
        selected = character(0)
      )
    ),
    tags$div(
      style = "color: #595959; border-left: 3px solid #595959; padding-left: 10px; margin-bottom: 15px;",
      tags$div(
        class = "checkbox",
        style = "margin-top: 0; margin-bottom: 5px; color: #595959;",
        tags$label(
          tags$input(id = "select_all_fao27", type = "checkbox"),
          tags$span("FAO 27", style = "font-weight: bold; color: #595959;")
        )
      ),
      checkboxGroupInput(
        inputId = "spat_cov_fao27",
        label = NULL,
        choices = c(
          "Arctic Ocean", "Azores", "Baltic Sea", "Barents Sea", "Bay of Biscay and the Iberian Coast",
          "Celtic Seas", "Faroes", "Greater North Sea", "Greenland Sea", "Iceland Sea",
          "Norwegian Sea", "Oceanic Northeast Atlantic"
        ),
        selected = character(0)
      )
    ),
    selectInput(inputId = "tax_res", label = "Taxonomic Resolution", choices = c("species", "genus", "family", "order_class"), selected = "species"),
    selectInput(inputId = "temp_res", label = "Temporal Resolution", choices = c("day_week", "month_season", "annual"), selected = "day_week"),
    # DTO-BioFlow Modification: Replaced choices labels.
    selectInput(inputId = "spat_res", label = "Spatial Resolution", choices = c("geographical coordinates" = "geom_point", "shape/grid" = "geom_shape"), selected = "geom_point"),
    hr(),
    actionButton("run_query", "Run Pipeline Execution", class = "btn-success w-100"),
    actionButton("exit_app", "Exit Application", class = "btn-danger w-100 mt-2", icon = icon("power-off"))
  ),
  # DTO-BioFlow Modification: Added container ID and value for Records panel.
  navset_card_tab(
    id = "tabs_container",
    title = "Analysis & Visualizations",
    nav_panel(
      title = "Execution Log", 
      icon = icon("terminal"), 
      card_body(
        verbatimTextOutput("console_log"),
        uiOutput("download_xlsx_ui")
      )
    ),
    nav_panel(
      title = "Records",
      value = "Records",
      icon = icon("map"),
      card_body(
        fillable = FALSE,
        fluidRow(column(4, selectInput("select_species_plot", "Taxa:", choices = NULL))),
        hr(),
        plotlyOutput("records_image_plotly", height = "550px")
      )
    ),
    nav_panel(
      title = "by TempCov",
      icon = icon("table"),
      card_body(
        fillable = FALSE,
        fluidRow(column(4, selectInput("select_sheet", "Select TempCov:", choices = NULL))),
        hr(),
        tags$h5("Missing Data Matrix"),
        div(style = "overflow-x: auto; margin-bottom: 20px;", DTOutput("interactive_matrix")),
        get_first_quartile_legend(),
        hr(),
        tags$h5("Distribution Profile by Ecoregion"),
        plotlyOutput("distribution_plot", height = "450px")
      )
    ),
    nav_panel(
      title = "ALL",
      icon = icon("globe"),
      card_body(
        fillable = FALSE,
        tags$h5("Missing Data Matrix"),
        div(style = "overflow-x: auto; margin-bottom: 20px;", DTOutput("all_matrix")),
        get_first_quartile_legend(),
        hr(),
        tags$h5("Distribution Profile by Ecoregion"),
        plotlyOutput("radar_plot", height = "600px")
      )
    ),
    nav_panel(
      title = "Comparison",
      icon = icon("scale-balanced"),
      card_body(
        fillable = FALSE,
        fluidRow(
          column(6, selectInput("comparison_group_a", "Select TempCov (Group A - Focus):", choices = NULL, multiple = TRUE)),
          column(6, selectInput("comparison_group_b", "Select TempCov (Group B - Reference):", choices = NULL, multiple = TRUE))
        ),
        hr(),
        tags$h5("Comparison Matrix (Difference: Group A - Group B)"),
        div(style = "overflow-x: auto; margin-bottom: 20px;", DTOutput("comparison_matrix")),
        get_comparison_legend()
      )
    )
  )
)

# =============================================================================
# SERVER LOGIC
# =============================================================================
server <- function(input, output, session) {
  stored_outputs <- reactiveVal(NULL)
  # DTO-BioFlow Modification: Initialised log_output reactiveVal.
  log_output <- reactiveVal("Ready. Configure parameters on the left panel and click 'Run Pipeline Execution'.")

  # Reactive to load macrogroups from CSV dynamically
  macrogroups_data <- reactive({
    # DTO-BioFlow Modification: Sourced macrogroups.csv from utilities folder.
    csv_file <- file.path(input$work_dir, "utilities", "macrogroups.csv")
    if (!file.exists(csv_file)) {
      csv_file <- file.path("utilities", "macrogroups.csv")
    }
    if (file.exists(csv_file)) {
      tryCatch({
        # Read the file. Try reading with semicolon first.
        df <- read.csv(csv_file, sep = ";", stringsAsFactors = FALSE)
        # If it doesn't have multiple columns, try comma.
        if (ncol(df) <= 1) {
          df <- read.csv(csv_file, sep = ",", stringsAsFactors = FALSE)
        }
        
        # Standardize column names to lowercase
        colnames(df) <- tolower(colnames(df))
        
        # Check if the CSV has the new hierarchical columns
        taxa_cols <- c("phylum", "class", "order", "family", "genus", "species")
        if ("macrogroup" %in% colnames(df) && any(taxa_cols %in% colnames(df))) {
          # Parse hierarchical CSV to flat macrogroup, taxon, level format
          parsed_rows <- list()
          for (i in 1:nrow(df)) {
            row_data <- df[i, ]
            macro_val <- trimws(as.character(row_data$macrogroup))
            if (is.na(macro_val) || macro_val == "") next
            
            # Find the rightmost non-empty taxonomic column
            target_taxon <- ""
            target_level <- ""
            
            # Search from lowest (species) to highest (phylum)
            for (col in rev(taxa_cols)) {
              if (col %in% colnames(df)) {
                val <- row_data[[col]]
                if (!is.null(val) && !is.na(val)) {
                  val_str <- trimws(as.character(val))
                  if (val_str != "") {
                    target_taxon <- val_str
                    target_level <- col
                    break
                  }
                }
              }
            }
            
            if (target_taxon != "") {
              parsed_rows[[length(parsed_rows) + 1]] <- data.frame(
                macrogroup = macro_val,
                taxon = target_taxon,
                level = target_level,
                stringsAsFactors = FALSE
              )
            }
          }
          if (length(parsed_rows) > 0) {
            return(do.call(rbind, parsed_rows))
          }
        } else if (all(c("macrogroup", "taxon", "level") %in% colnames(df))) {
          # Old format support
          df$macrogroup <- trimws(df$macrogroup)
          df$taxon <- trimws(df$taxon)
          df$level <- trimws(df$level)
          return(df)
        }
      }, error = function(e) {
        cat("Error parsing macrogroups.csv:", conditionMessage(e), "\n")
        NULL
      })
    }
    return(data.frame(macrogroup = character(), taxon = character(), level = character()))
  })

  # Check if the current species input is a macrogroup
  active_macrogroup <- reactive({
    req(input$species)
    df <- macrogroups_data()
    if (nrow(df) > 0 && input$species %in% df$macrogroup) {
      return(input$species)
    }
    return(NULL)
  })

  # Dynamically render Target Taxonomic Level field
  output$taxa_level_ui <- renderUI({
    macro <- active_macrogroup()
    if (!is.null(macro)) {
      textInput(
        inputId = "taxa_level_disabled", 
        label = "Taxa Level", 
        value = "(Defined in Macrogroup)", 
        width = "100%"
      )
    } else {
      # DTO-BioFlow Modification: Replaced scientificname_accepted with species in dropdown choices.
      selectInput(
        inputId = "taxa_level", 
        label = "Taxa Level", 
        choices = c("phylum", "class", "order", "family", "genus", "species"), 
        selected = "phylum",
        width = "100%"
      )
    }
  })

  # Dynamically update species dropdown choices when CSV updates
  # DTO-BioFlow Modification: Added display mapping label for the default selection choices.
  observe({
    df <- macrogroups_data()
    macros <- if (nrow(df) > 0) unique(df$macrogroup) else character(0)
    
    current_val <- isolate(input$species)
    
    # Map values to their user-facing display names
    # DTO-BioFlow Modification: Initialized choices_list as empty instead of containing default "Acidobacteria, Ctenophora"
    choices_list <- character(0)
    if (length(macros) > 0) {
      for (m in macros) {
        choices_list[m] <- m
      }
    }
    if (!is.null(current_val) && current_val != "" && !(current_val %in% choices_list)) {
      choices_list[current_val] <- current_val
    }
    
    # DTO-BioFlow Modification: Leave selected_val empty on initial app launch.
    selected_val <- if (is.null(current_val)) "" else current_val
    
    updateSelectizeInput(
      session, 
      "species", 
      choices = choices_list, 
      selected = selected_val,
      server = TRUE
    )
  })

  # 1. Pipeline Execution
  # DTO-BioFlow Modification: Changed from lazy eventReactive to eager observeEvent to ensure execution on click,
  # and added explicit user notifications for missing fields (species and work_dir).
  observeEvent(input$run_query, {
    if (is.null(input$species) || input$species == "") {
      showNotification("Please select or enter Target Taxa before running pipeline execution.", type = "error")
      return()
    }
    if (is.null(input$work_dir) || input$work_dir == "") {
      showNotification("Please specify the Working Directory path.", type = "error")
      return()
    }

    if (!dir.exists(input$work_dir)) {
      showNotification("The specified Working Directory does not exist. Please check the path.", type = "error")
      return()
    }

    # DTO-BioFlow Modification: Sourced Missing data_matrix.R from utilities folder.
    engine_path <- file.path(input$work_dir, "utilities", "Missing data_matrix.R")
    if (!file.exists(engine_path)) {
      showNotification(paste("File not found at:", engine_path), type = "error")
      return()
    }
    source(engine_path)

    log_output("Starting pipeline execution...")
    if (!is.null(session)) {
      session$sendCustomMessage("clear_log", "Starting pipeline execution...")
    }
    log_callback <- function(message) {
      new_log <- paste0(log_output(), "\n", message)
      log_output(new_log)
      cat(message, "\n")
      # DTO-BioFlow Modification: Flush log update to client immediately using custom messaging
      if (!is.null(session)) {
        session$sendCustomMessage("append_log", message)
      }
    }

    withProgress(message = "Processing pipeline execution...", value = 0, {
      macro <- isolate(active_macrogroup())
      if (!is.null(macro)) {
        macro_df <- isolate(macrogroups_data()) %>% filter(macrogroup == macro)
        species_input <- paste(macro_df$taxon, collapse = ", ")
        taxa_level_input <- macro_df$level # character vector of levels
        macro_name_input <- macro
      } else {
        species_input <- input$species
        taxa_level_input <- input$taxa_level
        macro_name_input <- NULL
      }

      current_inputs <- list(
        work_dir        = input$work_dir,
        wfs_service     = input$wfs_service,
        species         = species_input,
        taxa_level      = taxa_level_input,
        macrogroup_name = macro_name_input,
        spat_cov        = c(input$spat_cov_fao37, input$spat_cov_fao27),
        temp_cov        = c(input$temp_cov_historical, input$temp_cov_present),
        tax_res         = input$tax_res,
        temp_res        = input$temp_res,
        spat_res        = input$spat_res,
        use_cache       = input$use_cache
      )

      # DTO-BioFlow Modification: Passed session to support execution cancellation.
      # DTO-BioFlow Modification: Wrap running pipeline in tryCatch to handle aborting cleanly.
      res_list <- tryCatch({
        run_missing_data_pipeline(current_inputs, incProgress, log_callback, session)
      }, error = function(e) {
        err_msg <- conditionMessage(e)
        log_callback(paste("Pipeline execution interrupted:", err_msg))
        stopApp()
        return(NULL)
      })
      
      # If pipeline was aborted and returned NULL, stop further reactivity
      req(res_list)
      stored_outputs(res_list)
      
      # Show warning popup if any taxa returned 0 records (e.g. incorrect taxonomic level or spelling)
      alerts <- attr(res_list, "alerts")
      if (!is.null(alerts) && length(alerts) > 0) {
        showModal(modalDialog(
          title = HTML('<span style="color: #d9534f; font-weight: bold;"><i class="fas fa-exclamation-triangle"></i> Taxa Query Warnings</span>'),
          HTML(paste0(
            "<p>Some of the specified target taxa did not return any records. Please verify their spelling and taxonomic level configuration:</p>",
            "<ul>",
            paste0("<li style='color: #d9534f;'>", htmltools::htmlEscape(alerts), "</li>", collapse = ""),
            "</ul>"
          )),
          footer = modalButton("Dismiss"),
          size = "m",
          easyClose = TRUE
        ))
      }
      
      # Update UI choices for sheet, species plot, and comparison dropdowns
      sheet_choices <- setdiff(names(res_list), "ALL")
      updateSelectInput(session, "select_sheet", choices = sheet_choices, selected = sheet_choices[1])
      
      species_vec <- trimws(strsplit(species_input, ",")[[1]])
      updateSelectInput(session, "select_species_plot", choices = species_vec, selected = species_vec[1])
      
      # DTO-BioFlow Modification: Removed pre-selections for Comparison tab groups to start empty.
      updateSelectInput(session, "comparison_group_a", choices = sheet_choices, selected = character(0))
      updateSelectInput(session, "comparison_group_b", choices = sheet_choices, selected = character(0))

      # Report successful completion in log
      taxa_folder_name <- if (!is.null(macro_name_input)) macro_name_input else paste(species_vec, collapse = "_")
      
      record_counts <- attr(res_list, "record_counts")
      counts_summary <- ""
      if (!is.null(record_counts) && length(record_counts) > 0) {
        counts_summary <- paste0(
          "\nRecords summary:\n",
          paste0("- ", names(record_counts), ": ", record_counts, " records", collapse = "\n"),
          "\n"
        )
      }
      
      type_folder <- ifelse(input$wfs_service == "biology_abundance_data", "abundance", "occurrence")
      completion_msg <- paste0(
        "\n========================================\n",
        "Process completed successfully!\n",
        counts_summary,
        "\nCSV and XLSX files generated in:\n",
        input$work_dir, "/", type_folder, "/Outputs/", taxa_folder_name, "/\n",
        "========================================"
      )
      log_callback(completion_msg)
    })
  })

  output$console_log <- renderText({
    log_output()
  })

  output$download_xlsx_ui <- renderUI({
    req(stored_outputs())
    downloadButton("download_xlsx", "Download Excel Export (.xlsx)", class = "btn-primary mt-3")
  })

  output$download_xlsx <- downloadHandler(
    filename = function() {
      "Missing_data_by_TempCov.xlsx"
    },
    content = function(file) {
      species_vec <- trimws(strsplit(input$species, ",")[[1]])
      taxa_folder_name <- paste(species_vec, collapse = "_")
      type_folder <- ifelse(input$wfs_service == "biology_abundance_data", "abundance", "occurrence")
      local_file <- file.path(input$work_dir, type_folder, "Outputs", taxa_folder_name, "Missing data by TempCov.xlsx")
      if (file.exists(local_file)) {
        file.copy(local_file, file)
      } else {
        writeLines("File not found.", file)
      }
    }
  )

  # 2. Interactive Matrix (DT)
  output$interactive_matrix <- renderDT({
    req(stored_outputs(), input$select_sheet)
    req(input$select_sheet %in% names(stored_outputs()))

    raw_matrix <- as.data.frame(stored_outputs()[[input$select_sheet]])
    species_cols <- colnames(raw_matrix)

    matrix_with_stats <- raw_matrix
    matrix_with_stats$`1st_Quartile` <- apply(raw_matrix[species_cols], 1, quantile, probs = 0.25, na.rm = TRUE)

    col_quartiles <- apply(matrix_with_stats[species_cols], 2, quantile, probs = 0.25, na.rm = TRUE)
    col_summary_row <- c(col_quartiles, NA)
    names(col_summary_row) <- c(species_cols, "1st_Quartile")

    matrix_complete <- rbind(matrix_with_stats, col_summary_row)
    rownames(matrix_complete)[nrow(matrix_complete)] <- "1st_Quartile"

    all_values <- as.vector(as.matrix(raw_matrix[species_cols]))
    all_values <- all_values[!is.na(all_values)]

    if (length(all_values) == 0) all_values <- c(0, 0.5, 1)

    min_val <- min(all_values)
    max_val <- max(all_values)
    mid_val <- quantile(all_values, probs = 0.50, na.rm = TRUE)

    low_brks <- seq(min_val, mid_val, length.out = 30)
    high_brks <- seq(mid_val, max_val, length.out = 30)
    brks <- unique(c(low_brks, high_brks))
    brks <- brks[brks > min_val & brks < max_val]

    clrs <- colorRampPalette(c("#d4edda", "#fff3cd", "#f8d7da"))(length(brks) + 1)

    # Generate conditional formatting for the horizontal row of 1st quartile
    style_standard <- as.character(styleInterval(brks, clrs))
    style_1st_quartile <- as.character(styleInterval(c(0.33, 0.66), c("#c3e6cb", "#fcc419", "#f5c6cb")))
    # DTO-BioFlow Modification: Removed cell conditional formatting gradient (style_standard) for individual species, maintaining 1st_Quartile formatting.
    js_bg_code <- sprintf(
      "dataIndex + 1 === %d ? (%s) : null",
      nrow(matrix_complete),
      style_1st_quartile
    )

    style_1st_quartile_color <- as.character(styleInterval(c(0.33, 0.66), c("black", "black", "black")))
    js_color_code <- sprintf(
      "dataIndex + 1 === %d ? (%s) : null",
      nrow(matrix_complete),
      style_1st_quartile_color
    )

    # DTO-BioFlow Modification: Removed "ALL TAXA" row names column header.
    datatable(matrix_complete,
      colnames = c("", colnames(matrix_complete)),
      options = list(
        pageLength = 20,
        dom = "t",
        scrollX = TRUE,
        columnDefs = list(list(className = "dt-center", targets = "_all"))
      ),
      rownames = TRUE
    ) %>%
      formatPercentage(colnames(matrix_complete), 1) %>%
      formatStyle(species_cols,
        backgroundColor = JS(js_bg_code),
        color = JS(js_color_code)
      ) %>%
      formatStyle(0,
        fontWeight = styleRow(nrow(matrix_complete), "bold"),
        borderTop = styleRow(nrow(matrix_complete), "3px solid #333333")
      ) %>%
      formatStyle(c(species_cols, "1st_Quartile"),
        fontWeight = styleRow(nrow(matrix_complete), "bold"),
        borderTop = styleRow(nrow(matrix_complete), "3px solid #333333")
      ) %>%
      formatStyle("1st_Quartile",
        fontWeight = "bold",
        borderLeft = "3px solid #333333",
        backgroundColor = styleInterval(c(0.33, 0.66), c("#c3e6cb", "#fcc419", "#f5c6cb")),
        color = styleInterval(c(0.33, 0.66), c("black", "black", "black"))
      ) %>%
      formatStyle("1st_Quartile",
        backgroundColor = styleRow(nrow(matrix_complete), "#ffffff"),
        color = styleRow(nrow(matrix_complete), "#ffffff")
      )
  })

  # 2b. Interactive Matrix for ALL (DT)
  output$all_matrix <- renderDT({
    req(stored_outputs())
    req("ALL" %in% names(stored_outputs()))

    all_matrix <- as.data.frame(stored_outputs()[["ALL"]])
    temp_cols <- colnames(all_matrix)

    datatable(all_matrix,
      colnames = c("ALL TAXA", temp_cols),
      options = list(
        pageLength = 20,
        dom = "t",
        scrollX = TRUE,
        columnDefs = list(list(className = "dt-center", targets = "_all"))
      ),
      rownames = TRUE
    ) %>%
      formatPercentage(temp_cols, 1) %>%
      formatStyle(temp_cols,
        backgroundColor = styleInterval(c(0.33, 0.66), c("#c3e6cb", "#fcc419", "#f5c6cb")),
        color = styleInterval(c(0.33, 0.66), c("black", "black", "black"))
      )
  })

  # 3. Distribution Profile Plot (Replicating Excel Floating Bars) - Interactive via Plotly
  output$distribution_plot <- renderPlotly({
    req(stored_outputs(), input$select_sheet)
    req(input$select_sheet %in% names(stored_outputs()))

    raw_matrix <- as.data.frame(stored_outputs()[[input$select_sheet]])
    species_cols <- colnames(raw_matrix)

    # Compute all distribution benchmarks per row (Ecoregion)
    plot_data <- data.frame(
      Ecoregion = rownames(raw_matrix),
      Min = apply(raw_matrix[species_cols], 1, min, na.rm = TRUE),
      Q1 = apply(raw_matrix[species_cols], 1, quantile, probs = 0.25, na.rm = TRUE),
      Median = apply(raw_matrix[species_cols], 1, median, na.rm = TRUE),
      Q3 = apply(raw_matrix[species_cols], 1, quantile, probs = 0.75, na.rm = TRUE),
      Max = apply(raw_matrix[species_cols], 1, max, na.rm = TRUE),
      stringsAsFactors = FALSE
    )

    # Dynamic sizing based on number of ecoregions (boxplot grain)
    num_regions <- nrow(plot_data)
    size_q1_q3 <- max(3, min(25, 60 / num_regions))
    size_min_max <- max(0.5, min(4, 15 / num_regions))
    size_median <- max(4, min(15, 40 / num_regions))

    p <- ggplot(plot_data, aes(x = Ecoregion, text = paste0(
      "Ecoregion: ", Ecoregion, "<br>",
      "Min: ", scales::percent(Min, accuracy = 0.1), "<br>",
      "Q1: ", scales::percent(Q1, accuracy = 0.1), "<br>",
      "Median: ", scales::percent(Median, accuracy = 0.1), "<br>",
      "Q3: ", scales::percent(Q3, accuracy = 0.1), "<br>",
      "Max: ", scales::percent(Max, accuracy = 0.1)
    ))) +
      # Floating solid blocks tracking Q1 to Q3 distribution spans
      geom_linerange(aes(ymin = Q1, ymax = Q3, color = Ecoregion), linewidth = size_q1_q3, alpha = 0.85) +
      # Outer line range showing full data dispersion (Min to Max)
      geom_linerange(aes(ymin = Min, ymax = Max, color = Ecoregion), linewidth = size_min_max) +
      # Distinct indicators for structural checkpoints (Median and limits)
      geom_point(aes(y = Median), color = "black", shape = 95, size = size_median) +
      geom_point(aes(y = Q1), color = "black", shape = 4, size = max(1.5, size_min_max * 1.5)) +
      scale_y_continuous(
        labels = scales::percent_format(accuracy = 1),
        limits = c(0, 1),
        breaks = seq(0, 1, by = 0.1)
      ) +
      theme_minimal() +
      labs(
        title = paste("Data Distribution Profile (Temporal Coverage:", input$select_sheet, ")"),
        y = "Missing Data Value Range (%)",
        x = NULL
      ) +
      theme(
        plot.margin      = margin(10, 10, 10, 10, "pt"),
        axis.text.x      = element_text(angle = 35, hjust = 1, face = "bold"),
        panel.grid.minor = element_blank(),
        legend.position  = "bottom",
        legend.title     = element_blank()
      )

    ggplotly(p, tooltip = "text")
  })

  # 3b. Radar Plot for ALL
  output$radar_plot <- renderPlotly({
    req(stored_outputs())
    req("ALL" %in% names(stored_outputs()))

    all_matrix <- as.data.frame(stored_outputs()[["ALL"]])
    ecoregions <- rownames(all_matrix)
    temp_covs <- colnames(all_matrix)

    color_map <- c(
      "1880_1909" = "#e26d2e",
      "1910_1939" = "#008ece",
      "1940_1969" = "#43a047",
      "1970_1999" = "#8d4f20",
      "2000_2009" = "#0b5a82",
      "2010_2019" = "#215d2a",
      "2020_2026" = "#f58b4b"
    )

    p <- plot_ly(type = "scatterpolar", mode = "lines+markers")

    for (col in temp_covs) {
      r_vals <- all_matrix[[col]]
      # Close the radar path by appending the first element to the end
      r_vals_closed <- c(r_vals, r_vals[1])
      theta_closed <- c(ecoregions, ecoregions[1])

      line_color <- if (col %in% names(color_map)) color_map[col] else NULL

      p <- p %>% add_trace(
        r = r_vals_closed,
        theta = theta_closed,
        name = col,
        line = list(color = line_color, width = 3),
        marker = list(color = line_color, size = 6),
        hoverinfo = "text",
        text = paste0(
          "Ecoregion: ", theta_closed, "<br>",
          "Time Range: ", col, "<br>",
          "Missing Data: ", scales::percent(r_vals_closed, accuracy = 0.1)
        )
      )
    }

    p <- p %>% layout(
      polar = list(
        gridshape = "polygon",
        radialaxis = list(
          visible = TRUE,
          tickformat = ".0%",
          range = c(0, max(c(0.8, max(all_matrix, na.rm = TRUE))))
        )
      ),
      showlegend = TRUE
    )

    p
  })

  # Serve local files from the occurrence/records or abundance/records directory dynamically
  observe({
    req(input$work_dir)
    type_folder <- ifelse(input$wfs_service == "biology_abundance_data", "abundance", "occurrence")
    records_dir <- file.path(input$work_dir, type_folder, "records")
    if (dir.exists(records_dir)) {
      addResourcePath("records_dir", records_dir)
    }
  })



  # Render zoomable records image dynamically using plotly
  # DTO-BioFlow Modification: Hide and block plotting when spatial resolution is shape/grid.
  output$records_image_plotly <- renderPlotly({
    # Reactive dependency to refresh image when the pipeline finishes running
    stored_outputs()

    req(input$work_dir, input$select_species_plot)

    if (input$spat_res == "geom_shape") {
      return(
        plot_ly() %>%
          layout(
            title = list(
              text = "not possible to plot shape/grid data",
              font = list(color = "red", size = 16)
            ),
            xaxis = list(visible = FALSE),
            yaxis = list(visible = FALSE)
          )
      )
    }

    img_name <- paste0("records_", input$select_species_plot, ".png")
    type_folder <- ifelse(input$wfs_service == "biology_abundance_data", "abundance", "occurrence")
    img_path <- file.path(input$work_dir, type_folder, "records", img_name)

    if (!file.exists(img_path)) {
      return(
        plot_ly() %>%
          layout(
            title = list(
              text = paste(
                "Record image not found for taxon:", input$select_species_plot,
                "<br>Please run pipeline execution first."
              ),
              font = list(color = "red", size = 16)
            ),
            xaxis = list(visible = FALSE),
            yaxis = list(visible = FALSE)
          )
      )
    }

    img_uri <- base64enc::dataURI(file = img_path, mime = "image/png")

    plot_ly() %>%
      layout(
        images = list(
          list(
            source = img_uri,
            xref = "x",
            yref = "y",
            x = 0,
            y = 1,
            sizex = 1,
            sizey = 1,
            sizing = "stretch",
            xanchor = "left",
            yanchor = "top"
          )
        ),
        xaxis = list(
          range = c(0, 1),
          showgrid = FALSE,
          zeroline = FALSE,
          showticklabels = FALSE
        ),
        yaxis = list(
          range = c(0, 1),
          showgrid = FALSE,
          zeroline = FALSE,
          showticklabels = FALSE
        ),
        margin = list(t = 20, b = 20, l = 20, r = 20)
      ) %>%
      config(
        scrollZoom = TRUE,
        displayModeBar = TRUE,
        modeBarButtonsToRemove = c("select2d", "lasso2d", "hoverCompareCartesian", "hoverClosestCartesian")
      )
  })

  # Render Comparison Matrix
  output$comparison_matrix <- renderDT({
    req(stored_outputs())
    req(input$comparison_group_a, input$comparison_group_b)

    res_list <- stored_outputs()
    group_a <- input$comparison_group_a
    group_b <- input$comparison_group_b

    first_sheet <- res_list[[1]]
    species_cols <- colnames(first_sheet)
    ecoregions <- rownames(first_sheet)

    comp_matrix <- data.frame(matrix(nrow = length(ecoregions), ncol = length(species_cols)))
    colnames(comp_matrix) <- species_cols
    rownames(comp_matrix) <- ecoregions

    for (s in species_cols) {
      for (e in ecoregions) {
        vals_a <- sapply(group_a, function(t) {
          if (t %in% names(res_list)) as.numeric(res_list[[t]][e, s]) else NA
        })
        mean_a <- mean(vals_a, na.rm = TRUE)

        vals_b <- sapply(group_b, function(t) {
          if (t %in% names(res_list)) as.numeric(res_list[[t]][e, s]) else NA
        })
        mean_b <- mean(vals_b, na.rm = TRUE)

        comp_matrix[e, s] <- mean_a - mean_b
      }
    }

    datatable(comp_matrix,
      colnames = c("ALL TAXA", colnames(comp_matrix)),
      options = list(
        pageLength = 20,
        dom = "t",
        scrollX = TRUE,
        columnDefs = list(list(className = "dt-center", targets = "_all"))
      ),
      rownames = TRUE
    ) %>%
      formatPercentage(colnames(comp_matrix), 1) %>%
      # DTO-BioFlow Modification: Re-mapped cell format coloring for missingness comparisons.
      formatStyle(species_cols,
        backgroundColor = styleInterval(c(-0.60, -0.30, -1e-9, 1e-9, 0.30, 0.60), 
                                        c('#c3e6cb', '#d4edda', '#e6f4ea', '#ffffff', '#fff3cd', '#ffd8be', '#fcd5d9')),
        color = styleInterval(c(-0.60, -0.30, -1e-9, 1e-9, 0.30, 0.60), 
                              c('black', 'black', 'black', 'transparent', 'black', 'black', 'black'))
      )
  })



  # --- Select/Deselect All Observers ---

  # Historical group
  observe({
    choices <- c("1880_1909", "1910_1939", "1940_1969", "1970_1999")
    all_selected <- all(choices %in% input$temp_cov_historical)
    updateCheckboxInput(session, "select_all_historical", value = all_selected)
  })
  observeEvent(input$select_all_historical,
    {
      choices <- c("1880_1909", "1910_1939", "1940_1969", "1970_1999")
      current_selected <- input$temp_cov_historical
      if (input$select_all_historical && length(current_selected) < length(choices)) {
        updateCheckboxGroupInput(session, "temp_cov_historical", selected = choices)
      } else if (!input$select_all_historical && length(current_selected) == length(choices)) {
        updateCheckboxGroupInput(session, "temp_cov_historical", selected = character(0))
      }
    },
    ignoreInit = TRUE
  )

  # Present group
  observe({
    choices <- c("2000_2009", "2010_2019", "2020_2026")
    all_selected <- all(choices %in% input$temp_cov_present)
    updateCheckboxInput(session, "select_all_present", value = all_selected)
  })
  observeEvent(input$select_all_present,
    {
      choices <- c("2000_2009", "2010_2019", "2020_2026")
      current_selected <- input$temp_cov_present
      if (input$select_all_present && length(current_selected) < length(choices)) {
        updateCheckboxGroupInput(session, "temp_cov_present", selected = choices)
      } else if (!input$select_all_present && length(current_selected) == length(choices)) {
        updateCheckboxGroupInput(session, "temp_cov_present", selected = character(0))
      }
    },
    ignoreInit = TRUE
  )

  # FAO 37 group
  observe({
    choices <- c("Adriatic Sea", "Aegean-Levantine Sea", "Ionian Sea and the Central Mediterranean Sea", "Western Mediterranean Sea", "Black Sea")
    all_selected <- all(choices %in% input$spat_cov_fao37)
    updateCheckboxInput(session, "select_all_fao37", value = all_selected)
  })
  observeEvent(input$select_all_fao37,
    {
      choices <- c("Adriatic Sea", "Aegean-Levantine Sea", "Ionian Sea and the Central Mediterranean Sea", "Western Mediterranean Sea", "Black Sea")
      current_selected <- input$spat_cov_fao37
      if (input$select_all_fao37 && length(current_selected) < length(choices)) {
        updateCheckboxGroupInput(session, "spat_cov_fao37", selected = choices)
      } else if (!input$select_all_fao37 && length(current_selected) == length(choices)) {
        updateCheckboxGroupInput(session, "spat_cov_fao37", selected = character(0))
      }
    },
    ignoreInit = TRUE
  )

  # FAO 27 group
  observe({
    choices <- c("Arctic Ocean", "Azores", "Baltic Sea", "Barents Sea", "Bay of Biscay and the Iberian Coast", "Celtic Seas", "Faroes", "Greater North Sea", "Greenland Sea", "Iceland Sea", "Norwegian Sea", "Oceanic Northeast Atlantic")
    all_selected <- all(choices %in% input$spat_cov_fao27)
    updateCheckboxInput(session, "select_all_fao27", value = all_selected)
  })
  observeEvent(input$select_all_fao27,
    {
      choices <- c("Arctic Ocean", "Azores", "Baltic Sea", "Barents Sea", "Bay of Biscay and the Iberian Coast", "Celtic Seas", "Faroes", "Greater North Sea", "Greenland Sea", "Iceland Sea", "Norwegian Sea", "Oceanic Northeast Atlantic")
      current_selected <- input$spat_cov_fao27
      if (input$select_all_fao27 && length(current_selected) < length(choices)) {
        updateCheckboxGroupInput(session, "spat_cov_fao27", selected = choices)
      } else if (!input$select_all_fao27 && length(current_selected) == length(choices)) {
        updateCheckboxGroupInput(session, "spat_cov_fao27", selected = character(0))
      }
    },
    ignoreInit = TRUE
  )
  # DTO-BioFlow Modification: Session ended process halt.
  session$onSessionEnded(function() {
    cat("Session ended. Shutting down local R Shiny process...\n")
    stopApp()
  })

  # DTO-BioFlow Modification: Handle Exit Application button click to shut down R.
  observeEvent(input$exit_app, {
    showNotification("Shutting down local R Shiny process and exiting application...", type = "warning")
    stopApp()
  })

  # DTO-BioFlow Modification: Spatial Resolution constraint observer when biology_abundance_data is selected.
  observeEvent(input$wfs_service, {
    if (input$wfs_service == "biology_abundance_data") {
      updateSelectInput(session, "spat_res", 
                        choices = c("shape/grid" = "geom_shape"), 
                        selected = "geom_shape")
    } else {
      updateSelectInput(session, "spat_res", 
                        choices = c("geographical coordinates" = "geom_point", "shape/grid" = "geom_shape"), 
                        selected = "geom_point")
    }
  })

  # DTO-BioFlow Modification: Auto hide Records tab for shape/grid.
  observe({
    req(input$spat_res)
    if (input$spat_res == "geom_shape") {
      nav_hide("tabs_container", target = "Records")
    } else {
      nav_show("tabs_container", target = "Records")
    }
  })

  # DTO-BioFlow Modification: Taxonomic Resolution constraint dropdown mapping filter.
  observe({
    level <- input$taxa_level
    if (is.null(level) || level == "" || level == "(Defined in Macrogroup)") {
      choices <- c("species", "genus", "family", "order_class")
    } else if (level == "species") {
      choices <- c("species")
    } else if (level == "genus") {
      choices <- c("species", "genus")
    } else if (level == "family") {
      choices <- c("species", "genus", "family")
    } else {
      choices <- c("species", "genus", "family", "order_class")
    }
    
    current_res <- isolate(input$tax_res)
    selected_res <- if (current_res %in% choices) current_res else choices[length(choices)]
    updateSelectInput(session, "tax_res", choices = choices, selected = selected_res)
  })
}

shinyApp(ui, server)
