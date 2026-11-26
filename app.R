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
    tags$div(
      style = "display: flex; align-items: center; gap: 12px;",
      tags$img(src = "assets/utilities/MIDEX_logo.svg", alt = "MIDEX Logo", style = "height: 45px; width: auto;"),
      tags$strong("DTO-BioFlow: MIDEX")
    ),
    tags$img(src = "assets/utilities/Logo_DTO_Bio-Flow.svg", style = "height: 40px; width: auto; margin-right: 15px;")
  ),
  theme = light_theme,
  tags$head(
    # Font Awesome 6 Icons & SheetJS CDN for client-side Excel ingestion in Impact Assessment tab
    tags$link(rel = "stylesheet", href = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css"),
    tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/xlsx/0.18.5/xlsx.full.min.js"),
    tags$style(HTML("
      /* =====================================================================
         DTO-BIOFLOW DESIGN SYSTEM & BRAND TOKENS
         ===================================================================== */
      :root {
        --dto-navy: #003E7A;
        --dto-navy-dark: #071c33;
        --dto-navy-deep: #0b223d;
        --dto-blue: #0077C8;
        --dto-blue-light: #e8f4fc;
        --dto-cyan: #00a8cc;
        --dto-teal: #00c49f;
        --dto-amber: #f59e0b;
        --dto-amber-light: #fffbeb;
        --dto-amber-border: #fde68a;
        --dto-coral: #ff5a5f;
        --dto-green: #10b981;
        --dto-green-light: #ecfdf5;
        --dto-green-border: #a7f3d0;
        --dto-red: #ef4444;
        --dto-red-light: #fef2f2;
        --dto-red-border: #fecaca;

        --bg-page: #f4f8fc;
        --bg-surface: #ffffff;
        --bg-surface-glass: rgba(255, 255, 255, 0.92);

        --text-main: #1e293b;
        --text-muted: #64748b;
        --text-light: #94a3b8;
        --border-subtle: #e2e8f0;
        --border-accent: rgba(0, 62, 122, 0.12);

        --shadow-sm: 0 2px 4px rgba(0, 62, 122, 0.04);
        --shadow-md: 0 6px 18px rgba(0, 62, 122, 0.08);
        --shadow-lg: 0 14px 34px rgba(0, 62, 122, 0.12);
        --shadow-xl: 0 20px 45px rgba(0, 62, 122, 0.16);

        --radius-sm: 8px;
        --radius-md: 12px;
        --radius-lg: 18px;
        --radius-xl: 24px;
        --radius-full: 9999px;

        --font-heading: 'Outfit', sans-serif;
        --font-body: 'Inter', sans-serif;
      }

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

      /* Snug spacing for unzip reminder note right beneath absolute local path input */
      #work_dir {
        margin-bottom: 0 !important;
      }
      .shiny-input-container:has(#work_dir) {
        margin-bottom: 14px !important;
      }
      .unzip-note {
        display: block !important;
        font-size: 0.70rem !important;
        font-style: italic !important;
        color: #6c757d !important;
        margin-top: 2px !important;
        margin-bottom: 0 !important;
        line-height: 1.1 !important;
      }

      /* Distinct fill color and styling for Information Extraction section (Warm Amber / Gold) */
      .section-info-extraction {
        background-color: #fef7ed !important; /* Soft warm amber / golden ochre */
        border: 1px solid #fed7aa !important;
        border-left: 4px solid #d97706 !important;
        border-radius: 8px !important;
        padding: 12px 14px 10px 14px !important;
        margin-bottom: 16px !important;
        box-shadow: 0 1px 4px rgba(217, 119, 6, 0.08) !important;
      }
      .section-info-extraction .form-group {
        margin-bottom: 10px;
      }

      /* Distinct fill color and styling for Selection Process section (Ocean Blue) */
      .section-selection-process {
        background-color: #edf3fa !important; /* Soft ocean blue */
        border: 1px solid #b2cfea !important;
        border-left: 4px solid #167fc9 !important;
        border-radius: 8px !important;
        padding: 12px 14px 10px 14px !important;
        margin-bottom: 16px !important;
        box-shadow: 0 1px 4px rgba(22, 127, 201, 0.08) !important;
      }
      .section-selection-process .form-group {
        margin-bottom: 10px;
      }

      /* Tab Header Styling */
      .nav-tabs {
        border-bottom: 2px solid #dee2e6;
      }

      /* Records Tab Header - Same color as Information Extraction (Warm Amber / Gold) */
      .nav-tabs .nav-link[data-value='Records'],
      .nav-tabs li a[data-value='Records'] {
        background-color: #fef7ed !important;
        color: #92400e !important;
        border: 1px solid #fed7aa !important;
        border-bottom: 2px solid #d97706 !important;
        border-radius: 6px 6px 0 0 !important;
        margin-right: 4px;
        font-weight: 500;
        transition: all 0.2s ease;
      }
      .nav-tabs .nav-link[data-value='Records']:hover,
      .nav-tabs li a[data-value='Records']:hover {
        background-color: #fde68a !important;
        color: #78350f !important;
      }
      .nav-tabs .nav-link[data-value='Records'].active,
      .nav-tabs li.active a[data-value='Records'] {
        background-color: #d97706 !important;
        color: #ffffff !important;
        border-color: #d97706 #d97706 transparent !important;
        border-bottom: 2px solid #d97706 !important;
        font-weight: 600;
        box-shadow: 0 2px 6px rgba(217, 119, 6, 0.25);
      }
      .nav-tabs .nav-link[data-value='Records'].active i,
      .nav-tabs li.active a[data-value='Records'] i {
        color: #ffffff !important;
      }

      /* by TempCov, ALL, Comparison Tab Headers - Same color as Selection Process (Ocean Blue) */
      .nav-tabs .nav-link[data-value='by TempCov'],
      .nav-tabs li a[data-value='by TempCov'],
      .nav-tabs .nav-link[data-value='ALL'],
      .nav-tabs li a[data-value='ALL'],
      .nav-tabs .nav-link[data-value='Comparison'],
      .nav-tabs li a[data-value='Comparison'] {
        background-color: #edf3fa !important;
        color: #0b4f8c !important;
        border: 1px solid #b2cfea !important;
        border-bottom: 2px solid #167fc9 !important;
        border-radius: 6px 6px 0 0 !important;
        margin-right: 4px;
        font-weight: 500;
        transition: all 0.2s ease;
      }
      .nav-tabs .nav-link[data-value='by TempCov']:hover,
      .nav-tabs li a[data-value='by TempCov']:hover,
      .nav-tabs .nav-link[data-value='ALL']:hover,
      .nav-tabs li a[data-value='ALL']:hover,
      .nav-tabs .nav-link[data-value='Comparison']:hover,
      .nav-tabs li a[data-value='Comparison']:hover {
        background-color: #dbeaf7 !important;
        color: #073560 !important;
      }
      .nav-tabs .nav-link[data-value='by TempCov'].active,
      .nav-tabs li.active a[data-value='by TempCov'],
      .nav-tabs .nav-link[data-value='ALL'].active,
      .nav-tabs li.active a[data-value='ALL'],
      .nav-tabs .nav-link[data-value='Comparison'].active,
      .nav-tabs li.active a[data-value='Comparison'] {
        background-color: #167fc9 !important;
        color: #ffffff !important;
        border-color: #167fc9 #167fc9 transparent !important;
        border-bottom: 2px solid #167fc9 !important;
        font-weight: 600;
        box-shadow: 0 2px 6px rgba(22, 127, 201, 0.25);
      }
      .nav-tabs .nav-link[data-value='by TempCov'].active i,
      .nav-tabs li.active a[data-value='by TempCov'] i,
      .nav-tabs .nav-link[data-value='ALL'].active i,
      .nav-tabs li.active a[data-value='ALL'] i,
      .nav-tabs .nav-link[data-value='Comparison'].active i,
      .nav-tabs li.active a[data-value='Comparison'] i {
        color: #ffffff !important;
      }

      /* Execution Log Tab Header - Standard (No Color) */
      .nav-tabs .nav-link[data-value='Execution Log'],
      .nav-tabs li a[data-value='Execution Log'] {
        border-radius: 6px 6px 0 0 !important;
        margin-right: 4px;
      }

      /* Impact Assessment Tab Header - DTO-BioFlow Teal / Navy Accent */
      .nav-tabs .nav-link[data-value='Impact Assessment'],
      .nav-tabs li a[data-value='Impact Assessment'] {
        background-color: #ecfdf5 !important;
        color: #065f46 !important;
        border: 1px solid #a7f3d0 !important;
        border-bottom: 2px solid #00a896 !important;
        border-radius: 6px 6px 0 0 !important;
        margin-right: 4px;
        font-weight: 500;
        transition: all 0.2s ease;
      }
      .nav-tabs .nav-link[data-value='Impact Assessment']:hover,
      .nav-tabs li a[data-value='Impact Assessment']:hover {
        background-color: #d1fae5 !important;
        color: #064e3b !important;
      }
      .nav-tabs .nav-link[data-value='Impact Assessment'].active,
      .nav-tabs li.active a[data-value='Impact Assessment'] {
        background-color: #00a896 !important;
        color: #ffffff !important;
        border-color: #00a896 #00a896 transparent !important;
        border-bottom: 2px solid #00a896 !important;
        font-weight: 600;
        box-shadow: 0 2px 6px rgba(0, 168, 150, 0.25);
      }
      .nav-tabs .nav-link[data-value='Impact Assessment'].active i,
      .nav-tabs li.active a[data-value='Impact Assessment'] i {
        color: #ffffff !important;
      }

      /* =====================================================================
         IMPACT ASSESSMENT TAB & INTERACTIVE TABLE STYLES (FROM MISSING DATA EXPLORER)
         ===================================================================== */
      .section-header-wrap {
        margin-bottom: 1.75rem;
      }

      .impact-intro-split {
        display: grid;
        grid-template-columns: 1.3fr 0.7fr;
        gap: 2rem;
        align-items: center;
        margin-bottom: 1.75rem;
      }

      @media (max-width: 992px) {
        .impact-intro-split {
          grid-template-columns: 1fr;
        }
      }

      .impact-figure-side {
        text-align: center;
      }

      .impact-figure-side img {
        max-width: 380px;
        width: 100%;
        height: auto;
        display: inline-block;
      }

      .section-eyebrow {
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        font-size: 0.85rem;
        font-weight: 700;
        text-transform: uppercase;
        letter-spacing: 0.08em;
        color: var(--dto-blue);
        margin-bottom: 0.5rem;
      }

      .section-title {
        font-family: var(--font-heading);
        font-size: 2rem;
        font-weight: 700;
        color: var(--dto-navy);
        letter-spacing: -0.01em;
        line-height: 1.25;
        margin-bottom: 0.75rem;
      }

      .section-subtitle {
        font-size: 1.02rem;
        color: var(--text-muted);
        max-width: 100%;
        width: 100%;
        line-height: 1.65;
        margin-bottom: 0;
      }

      .table-app-wrapper {
        background: #ffffff;
        border-radius: var(--radius-xl);
        border: 1px solid var(--border-subtle);
        box-shadow: var(--shadow-xl);
        padding: 2rem;
        margin-top: 1.25rem;
      }

      .table-intro-guide {
        display: flex;
        align-items: flex-start;
        gap: 0.85rem;
        background: #f0f7ff;
        border: 1px solid #bfdbfe;
        border-left: 4px solid var(--dto-blue);
        border-radius: var(--radius-sm);
        padding: 0.95rem 1.25rem;
        margin-bottom: 1.75rem;
        font-size: 0.92rem;
        color: #1e3a8a;
        line-height: 1.55;
      }

      .table-intro-guide i {
        font-size: 1.15rem;
        color: var(--dto-blue);
        margin-top: 0.15rem;
        flex-shrink: 0;
      }

      .table-toolbar {
        display: flex;
        flex-wrap: wrap;
        align-items: center;
        justify-content: space-between;
        gap: 1.25rem;
        margin-bottom: 2rem;
        padding-bottom: 1.75rem;
        border-bottom: 1px solid var(--border-subtle);
      }

      .preset-selector-group {
        display: flex;
        align-items: center;
        gap: 0.75rem;
        flex-wrap: wrap;
      }

      .preset-selector-group label {
        font-weight: 600;
        font-size: 0.9rem;
        color: var(--dto-navy);
        display: flex;
        align-items: center;
        gap: 0.4rem;
        margin-bottom: 0;
      }

      .select-preset {
        padding: 0.55rem 1.1rem;
        border-radius: var(--radius-sm);
        border: 1px solid var(--border-subtle);
        background-color: #f8fafc;
        font-family: var(--font-body);
        font-size: 0.9rem;
        color: var(--text-main);
        cursor: pointer;
        font-weight: 500;
        transition: all 0.2s;
      }

      .select-preset:focus {
        outline: none;
        border-color: var(--dto-blue);
        box-shadow: 0 0 0 3px rgba(0, 119, 200, 0.15);
        background-color: #ffffff;
      }

      .table-actions-group {
        display: flex;
        align-items: center;
        gap: 0.75rem;
        flex-wrap: wrap;
      }

      .btn-tbl {
        display: inline-flex;
        align-items: center;
        gap: 0.45rem;
        padding: 0.55rem 1rem;
        font-size: 0.88rem;
        font-weight: 600;
        border-radius: var(--radius-sm);
        cursor: pointer;
        border: 1px solid transparent;
        transition: all 0.2s;
      }

      .btn-tbl-primary {
        background: var(--dto-navy);
        color: #ffffff;
      }

      .btn-tbl-primary:hover {
        background: var(--dto-navy-deep);
        transform: translateY(-1px);
      }

      .btn-tbl-secondary {
        background: #f1f5f9;
        color: var(--text-main);
        border-color: var(--border-subtle);
      }

      .btn-tbl-secondary:hover {
        background: #e2e8f0;
        color: var(--dto-navy);
      }

      .btn-tbl-success {
        background: var(--dto-green);
        color: #ffffff;
      }

      .btn-tbl-success:hover {
        background: #059669;
      }

      /* Live Summary Dashboard KPI Cards */
      .kpi-summary-row {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(190px, 1fr));
        gap: 1.25rem;
        margin-bottom: 2rem;
      }

      .kpi-card {
        border-radius: var(--radius-md);
        padding: 1.25rem 1.5rem;
        border: 1px solid var(--border-subtle);
        display: flex;
        flex-direction: column;
        align-items: flex-start;
        justify-content: center;
        transition: all 0.25s ease;
        box-shadow: var(--shadow-sm);
      }

      .kpi-card:hover {
        transform: translateY(-2px);
        box-shadow: var(--shadow-md);
      }

      .kpi-card .kpi-info h5 {
        font-size: 0.85rem;
        text-transform: uppercase;
        letter-spacing: 0.05em;
        margin-bottom: 0.35rem;
        font-weight: 700;
      }

      .kpi-card .kpi-info .kpi-num {
        font-family: var(--font-heading);
        font-size: 2.1rem;
        font-weight: 800;
        line-height: 1;
      }

      .kpi-card.kpi-total {
        background: #ffffff;
        border-color: #cbd5e1;
      }
      .kpi-total .kpi-info h5 {
        color: var(--text-muted);
      }
      .kpi-total .kpi-info .kpi-num {
        color: var(--dto-navy);
      }

      .kpi-card.kpi-low {
        background: #65f7c6;
        border-color: #2fd19c;
      }
      .kpi-low .kpi-info h5 {
        color: #043e2f;
      }
      .kpi-low .kpi-info .kpi-num {
        color: #043e2f;
      }

      .kpi-card.kpi-medium {
        background: #ffa80b;
        border-color: #d97706;
      }
      .kpi-medium .kpi-info h5 {
        color: #ffffff;
      }
      .kpi-medium .kpi-info .kpi-num {
        color: #ffffff;
      }

      .kpi-card.kpi-high {
        background: #ff5b37;
        border-color: #dc2626;
      }
      .kpi-high .kpi-info h5 {
        color: #ffffff;
      }
      .kpi-high .kpi-info .kpi-num {
        color: #ffffff;
      }

      /* Row Delete Button */
      .btn-row-delete {
        background: transparent;
        border: none;
        color: #94a3b8;
        cursor: pointer;
        padding: 0.35rem 0.5rem;
        border-radius: 4px;
        font-size: 0.95rem;
        transition: all 0.2s;
        display: inline-flex;
        align-items: center;
        justify-content: center;
      }

      .btn-row-delete:hover:not(:disabled) {
        color: #ef4444;
        background: #fee2e2;
      }

      .btn-row-delete:disabled {
        opacity: 0.25;
        cursor: not-allowed;
      }

      .table-input-readonly {
        background: #f8fafc !important;
        color: #334155 !important;
        border-color: transparent !important;
        cursor: default !important;
      }

      .select-readonly {
        cursor: default !important;
        pointer-events: none !important;
        opacity: 0.95 !important;
      }

      /* NA tier styles */
      .select-impact[data-tier='NA'] {
        background-color: #f1f5f9;
        color: #0f172a;
        border-color: #94a3b8;
      }

      .risk-badge.badge-na {
        background: #e2e8f0;
        color: #000000;
        border: 1px solid #94a3b8;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        gap: 0.35rem;
      }

      /* Compressed Responsive Table Layout */
      .table-responsive-container {
        width: 100%;
        overflow-x: hidden;
        border-radius: var(--radius-md);
        border: 1px solid var(--border-subtle);
        box-shadow: var(--shadow-sm);
      }

      .risk-calc-table {
        width: 100%;
        min-width: 100%;
        border-collapse: collapse;
        table-layout: fixed;
        text-align: left;
        font-size: 0.84rem;
      }

      .risk-calc-table thead th {
        background: var(--dto-navy);
        color: #ffffff;
        padding: 0.75rem 0.6rem;
        font-family: var(--font-heading);
        font-weight: 700;
        font-size: 0.82rem;
        letter-spacing: 0.04em;
        border-right: 1px solid rgba(255, 255, 255, 0.12);
      }

      .risk-calc-table tbody tr {
        border-bottom: 1px solid var(--border-subtle);
        transition: background-color 0.15s ease;
      }

      .risk-calc-table tbody tr:nth-child(even) {
        background-color: #fbfdff;
      }

      .risk-calc-table tbody tr:hover {
        background-color: #f0f7ff;
      }

      .risk-calc-table td {
        padding: 0.45rem 0.5rem;
        vertical-align: middle;
        border-right: 1px solid #f1f5f9;
      }

      /* Inputs in table */
      .table-input-text {
        width: 100%;
        border: 1px solid #e2e8f0;
        background: #ffffff;
        padding: 0.4rem 0.5rem;
        font-family: var(--font-body);
        font-size: 0.82rem;
        color: var(--text-main);
        border-radius: 4px;
        transition: all 0.2s;
      }

      .table-input-text:focus {
        outline: none;
        border-color: var(--dto-blue);
        box-shadow: 0 0 0 2px rgba(0, 119, 200, 0.2);
      }

      .resolution-cell-display {
        font-size: 0.82rem;
        color: var(--text-main);
        padding: 0.35rem 0.5rem;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
        background: #f8fafc;
        border: 1px solid #e2e8f0;
        border-radius: 4px;
      }

      .resolution-cell-display em {
        font-style: italic;
        color: var(--dto-navy);
        font-weight: 600;
      }

      /* Select Dropdowns for Impact & Likelihood */
      .table-select {
        width: 100%;
        min-width: 0;
        padding: 0.4rem 0.35rem;
        font-family: var(--font-body);
        font-size: 0.8rem;
        font-weight: 700;
        border-radius: 4px;
        border: 1px solid var(--border-subtle);
        cursor: pointer;
        transition: all 0.2s;
      }

      /* Colors of Impact in Table: Minor (white), Moderate (light gray), Major (dark gray) */
      .select-impact[data-tier='MINOR'] {
        background-color: #ffffff;
        color: #1e293b;
        border-color: #cbd5e1;
      }
      .select-impact[data-tier='MODERATE'] {
        background-color: #eaeef3;
        color: #1e293b;
        border-color: #cbd5e1;
      }
      .select-impact[data-tier='MAJOR'] {
        background-color: #595959;
        color: #ffffff;
        border-color: #404040;
      }

      /* Colors of Likelihood in Table: Unlikely (white), Likely (light orange), Very Likely (red) */
      .select-likelihood[data-tier='UNLIKELY'] {
        background-color: #ffffff;
        color: #1e293b;
        border-color: #cbd5e1;
      }
      .select-likelihood[data-tier='LIKELY'] {
        background-color: #ffe699;
        color: #78350f;
        border-color: #f59e0b;
      }
      .select-likelihood[data-tier='VERY LIKELY'] {
        background-color: #ff5b37;
        color: #ffffff;
        border-color: #dc2626;
      }

      /* Calculated Risk Badges: Low (verde acqua #65f7c6), Medium (#ffa80b), High (#ff5b37) */
      .risk-badge {
        display: block;
        text-align: center;
        width: 100%;
        padding: 0.45rem 0.25rem;
        border-radius: 4px;
        font-weight: 800;
        font-size: 0.82rem;
        letter-spacing: 0.04em;
        text-transform: uppercase;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
        cursor: default;
      }

      .risk-badge.badge-low {
        background: #65f7c6;
        color: #043e2f;
        border: 1px solid #2fd19c;
      }

      .risk-badge.badge-medium {
        background: #ffa80b;
        color: #ffffff;
        border: 1px solid #d97706;
      }

      .risk-badge.badge-high {
        background: #ff5b37;
        color: #ffffff;
        border: 1px solid #dc2626;
      }

      .risk-badge.badge-pending {
        background: #f1f5f9;
        color: #64748b;
        border: 1px solid #cbd5e1;
      }

      /* Imported Data Configuration Toolbar Panel */
      .import-panel {
        background: linear-gradient(135deg, #f8fafc 0%, #f0f7ff 100%);
        border: 1px solid #bae6fd;
        border-radius: var(--radius-md);
        padding: 1.25rem 1.5rem;
        margin-bottom: 1.75rem;
        box-shadow: var(--shadow-sm);
      }

      .import-panel-header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        margin-bottom: 1rem;
      }

      .import-title {
        display: flex;
        align-items: center;
        gap: 0.6rem;
        font-size: 0.95rem;
        color: var(--dto-navy);
      }

      .import-source-badge {
        background: #e0f2fe;
        color: var(--dto-blue);
        font-size: 0.75rem;
        font-weight: 700;
        padding: 0.15rem 0.5rem;
        border-radius: var(--radius-full);
      }

      .import-close-btn {
        cursor: pointer;
        font-size: 1.3rem;
        color: var(--text-muted);
        line-height: 1;
      }

      .import-close-btn:hover {
        color: var(--dto-red);
      }

      .import-controls-grid {
        display: grid;
        grid-template-columns: 1.15fr 1fr 1fr 0.95fr 0.9fr;
        gap: 0.85rem;
        align-items: end;
      }

      @media (max-width: 1200px) {
        .import-controls-grid {
          grid-template-columns: repeat(3, 1fr);
        }
      }

      @media (max-width: 768px) {
        .import-controls-grid {
          grid-template-columns: 1fr 1fr;
        }
      }

      @media (max-width: 576px) {
        .import-controls-grid {
          grid-template-columns: 1fr;
        }
      }

      .import-control-item label {
        display: block;
        font-size: 0.78rem;
        font-weight: 700;
        color: var(--dto-navy);
        margin-bottom: 0.35rem;
        text-transform: uppercase;
        letter-spacing: 0.03em;
      }

      .import-select {
        width: 100%;
        padding: 0.5rem 0.65rem;
        border-radius: var(--radius-sm);
        border: 1px solid #cbd5e1;
        background: #ffffff;
        font-family: var(--font-body);
        font-size: 0.85rem;
        color: var(--text-main);
        cursor: pointer;
      }

      .fixed-res-display {
        padding: 0.48rem 0.65rem;
        background: #ffffff;
        border: 1px solid #cbd5e1;
        border-radius: var(--radius-sm);
        font-size: 0.82rem;
        color: var(--text-main);
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
      }

      .fixed-res-display em {
        font-style: italic;
        color: var(--dto-navy);
        font-weight: 600;
      }

      .calc-q1-display {
        padding: 0.45rem 0.65rem;
        background: #ffffff;
        border: 1px solid #cbd5e1;
        border-radius: var(--radius-sm);
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 0.5rem;
      }

      .q1-val {
        font-size: 0.85rem;
        font-weight: 700;
        color: var(--dto-navy);
      }

      .q1-tier-badge {
        padding: 0.15rem 0.5rem;
        border-radius: 4px;
        font-size: 0.75rem;
        font-weight: 800;
      }

      .q1-tier-badge.tier-unlikely {
        background: #ffffff;
        color: #1e293b;
        border: 1px solid #cbd5e1;
      }

      .q1-tier-badge.tier-likely {
        background: #ffe699;
        color: #78350f;
        border: 1px solid #f59e0b;
      }

      .q1-tier-badge.tier-very-likely {
        background: #ff5b37;
        color: #ffffff;
        border: 1px solid #dc2626;
      }

      .import-panel-footer {
        margin-top: 1rem;
        display: flex;
        align-items: center;
        gap: 1rem;
        flex-wrap: wrap;
        padding-top: 0.75rem;
        border-top: 1px solid rgba(0, 119, 200, 0.15);
      }

      .btn-import-apply {
        background: var(--dto-navy);
        color: #ffffff;
        border: none;
        border-radius: var(--radius-sm);
        padding: 0.45rem 1rem;
        font-size: 0.82rem;
        font-weight: 700;
        cursor: pointer;
        display: inline-flex;
        align-items: center;
        gap: 0.4rem;
      }

      .btn-import-apply:hover {
        background: var(--dto-navy-deep);
      }

      .btn-import-apply-all {
        background: #0284c7;
        color: #ffffff;
        border: none;
        border-radius: var(--radius-sm);
        padding: 0.45rem 1rem;
        font-size: 0.82rem;
        font-weight: 700;
        cursor: pointer;
        display: inline-flex;
        align-items: center;
        gap: 0.4rem;
      }

      .btn-import-apply-all:hover {
        background: #0369a1;
      }

      .import-note-tip {
        font-size: 0.8rem;
        color: var(--text-muted);
      }

      .link-inline {
        color: var(--dto-blue);
        text-decoration: underline;
        text-underline-offset: 3px;
        font-weight: 600;
      }

      .link-inline:hover {
        color: var(--dto-navy);
      }

      .badge-pulse {
        animation: badgePulse 0.4s ease-out;
      }

      @keyframes badgePulse {
        0% { transform: scale(0.9); }
        50% { transform: scale(1.1); }
        100% { transform: scale(1); }
      }

      /* Row actions */
      .row-actions-cell {
        text-align: center;
        white-space: nowrap;
      }

      .btn-row-action {
        background: transparent;
        border: none;
        color: var(--text-light);
        cursor: pointer;
        font-size: 0.95rem;
        padding: 0.35rem 0.5rem;
        border-radius: 4px;
        transition: all 0.2s;
      }

      .btn-row-action:hover {
        color: var(--dto-red);
        background: #fee2e2;
      }

      .btn-row-action.btn-duplicate:hover {
        color: var(--dto-blue);
        background: #e0f2fe;
      }

      /* Empty state */
      .empty-table-state {
        text-align: center;
        padding: 3rem 1rem;
        color: var(--text-muted);
      }

      .empty-table-state i {
        font-size: 2.5rem;
        color: var(--text-light);
        margin-bottom: 0.75rem;
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
    tags$h5("Working Directory", style = "font-weight: bold; margin-top: 10px; margin-bottom: 8px; color: #2b303a;"),
    tagAppendChild(
      textInput(inputId = "work_dir", label = "Absolute local path", value = getwd()),
      tags$div(
        tags$em("remember to unzip the folder!"),
        class = "unzip-note"
      )
    ),

    # Section 1: Information extraction (Filled with soft Warm Amber / Gold)
    tags$div(
      class = "section-info-extraction",
      tags$h5("Information extraction", style = "font-weight: bold; margin-top: 0; margin-bottom: 12px; color: #92400e;"),
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
      checkboxInput(inputId = "use_cache", label = "Use local cache (if available)", value = TRUE)
    ),

    # Section 2: Selection process (Filled with soft Ocean Blue)
    tags$div(
      class = "section-selection-process",
      tags$h5("Selection process", style = "font-weight: bold; margin-top: 0; margin-bottom: 12px; color: #0b4f8c;"),

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
      selectInput(inputId = "spat_res", label = "Spatial Resolution", choices = c("geographical coordinates" = "geom_point", "shape/grid" = "geom_shape"), selected = "geom_point")
    ),
    actionButton("run_query", "Run Pipeline Execution", class = "btn-success w-100"),
    actionButton("exit_app", "Exit Application", class = "btn-danger w-100 mt-2", icon = icon("power-off"))
  ),
  # DTO-BioFlow Modification: Added container ID and value for Records panel, plus Impact Assessment panel.
  navset_card_tab(
    id = "tabs_container",
    title = "Analysis & Visualizations",
    nav_panel(
      title = "Execution Log",
      value = "Execution Log",
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
      value = "by TempCov",
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
      value = "ALL",
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
      value = "Comparison",
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
    ),
    nav_panel(
      title = "Impact Assessment",
      value = "Impact Assessment",
      icon = icon("table-cells"),
      card_body(
        fillable = FALSE,
        HTML(r"---(
        <div id="impact-assessment-app">
          <div class="impact-intro-split">
            <div class="section-header-wrap" style="margin-bottom: 0;">
              <div class="section-eyebrow"><i class="fa-solid fa-calculator"></i> Interactive Impact Assessment</div>
              <p class="section-subtitle">
                Interactive table evaluating product feasibility according to the risk rating key. Manually select different levels of impact and import the outcomes from the missing data matrix (likelihood tiers) to calculate risk ratings dynamically. Predefined case studies are included to illustrate how such a interactive table works. Within the table, outputs are standardized as follows: the <strong>RESPONSE VAR</strong> column displays the data type followed by the taxon in uppercase (e.g., <em>occurence-FISH</em>); the <strong>COVERAGE</strong> column displays the spatial domain followed by the temporal range in uppercase (e.g., <em>Adriatic Sea-2010_2019, 2020_2025</em>); and the <strong>RESOLUTION</strong> column displays the taxonomic resolution in italics, followed by the spatial resolution, and finally the temporal resolution in uppercase (e.g., <em>species</em>-geo coordinates-ANNUAL).
              </p>
            </div>
            <div class="impact-figure-side">
              <img src="assets/utilities/Figure 1.png" alt="Figure 1. Risk rating key" id="fig1Image">
            </div>
          </div>

          <div class="table-app-wrapper">

            <!-- How To Start Guide -->
            <div class="table-intro-guide">
              <i class="fa-solid fa-circle-info"></i>
              <div>
                <strong>How to get started:</strong> You can set up a risk assessment from scratch by uploading the output file directly from the <strong>Missing data matrix Tool</strong> (<em>Missing data by TempCov.xlsx</em>) to display the calculated likelihood across different marine biodiversity components, or load a predefined <strong>Case Study Preset</strong> to see how an operational assessment works.
              </div>
            </div>

            <!-- Table Toolbar -->
            <div class="table-toolbar">
              <div class="preset-selector-group">
                <label for="casePresetSelect"><i class="fa-solid fa-folder-open"></i> Case Study Preset:</label>
                <select id="casePresetSelect" class="select-preset">
                  <option value="empty" selected>Blank Assessment Template</option>
                  <option value="case1">Case Study: Sustainable management of sea resources in Northeast Atlantic waters (without drivers)</option>
                </select>
              </div>

              <div class="table-actions-group">
                <button type="button" class="btn-tbl btn-tbl-primary" id="btnAddRowBtn" style="display: none;">
                  <i class="fa-solid fa-plus"></i> Add Product
                </button>
                <button type="button" class="btn-tbl btn-tbl-primary" id="btnImportXlsx">
                  <i class="fa-solid fa-file-excel"></i> Import Missing data by TempCov.xlsx
                </button>
                <button type="button" class="btn-tbl btn-tbl-secondary" id="btnExportCsv">
                  <i class="fa-solid fa-file-csv"></i> Export CSV
                </button>
                <input type="file" id="xlsxFileInput" accept=".xlsx, application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" style="display: none;">
              </div>
            </div>

            <!-- Imported Missing Data Configuration Panel -->
            <div class="import-panel" id="importConfigPanel" style="display: none;">
              <div class="import-panel-header">
                <div class="import-title">
                  <i class="fa-solid fa-file-excel text-success"></i>
                  <span><strong id="importFileNameText">Missing data by TempCov.xlsx</strong></span>
                </div>
                <div class="import-close-btn" id="btnCloseImportPanel" title="Close Configuration">&times;</div>
              </div>
              <div class="import-controls-grid">
                <div class="import-control-item">
                  <label for="importTaxonSelect"><i class="fa-solid fa-dna"></i> RESPONSE VAR / TAXON:</label>
                  <select id="importTaxonSelect" class="import-select">
                    <option value="occurence-ALL">occurence-ALL (Macrogroup)</option>
                    <option value="occurence-NEPHROPS NORVEGICUS">occurence-NEPHROPS NORVEGICUS</option>
                    <option value="occurence-MERLUCCIUS MERLUCCIUS">occurence-MERLUCCIUS MERLUCCIUS</option>
                  </select>
                </div>
                <div class="import-control-item">
                  <label for="importSpatialSelect"><i class="fa-solid fa-earth-europe"></i> Spatial COVERAGE:</label>
                  <select id="importSpatialSelect" class="import-select">
                    <option value="FAO 37">FAO 37 (Full Domain)</option>
                    <option value="Adriatic Sea">Adriatic Sea</option>
                    <option value="Aegean-Levantine Sea">Aegean-Levantine Sea</option>
                    <option value="Ionian Sea and the Central Mediterranean Sea">Ionian Sea and the Central Mediterranean Sea</option>
                    <option value="Western Mediterranean Sea">Western Mediterranean Sea</option>
                  </select>
                </div>
                <div class="import-control-item">
                  <label for="importTemporalSelect"><i class="fa-solid fa-clock"></i> Temporal COVERAGE:</label>
                  <select id="importTemporalSelect" class="import-select">
                    <option value="2000_2009">2000_2009</option>
                    <option value="2010_2019">2010_2019</option>
                    <option value="2020_2026">2020_2026</option>
                  </select>
                </div>
                <div class="import-control-item">
                  <label><i class="fa-solid fa-sliders"></i> RESOLUTION (Fixed):</label>
                  <div class="fixed-res-display" id="importFixedResText"><em>species</em>-geo coordinates-ANNUAL</div>
                </div>
                <div class="import-control-item">
                  <label><i class="fa-solid fa-chart-pie"></i> Likelihood:</label>
                  <div class="calc-q1-display" id="importQ1Display" title="Calculated missing data Q1 quartile">
                    <span class="q1-val" id="importQ1Text">Q1: 19.6%</span>
                    <span class="q1-tier-badge tier-unlikely" id="importLikelihoodBadge">UNLIKELY</span>
                  </div>
                </div>
              </div>
              <div class="import-panel-footer" style="padding-top: 0.5rem; border-top: 1px solid rgba(0, 119, 200, 0.15);">
                <span class="import-note-tip" style="font-size: 0.82rem; color: #475569;">
                  <i class="fa-solid fa-circle-info text-primary"></i> Select a taxon, spatial coverage, and temporal coverage, then click <strong>+ Add Product</strong> to add a row based on the calculated likelihood. In imported rows, the columns RESPONSE VAR, COVERAGE, and RESOLUTION are locked to data matrix outcomes, while PRODUCT and impact can be customized.
                </span>
              </div>
            </div>

            <!-- KPI Summary Cards -->
            <div class="kpi-summary-row">
              <div class="kpi-card kpi-total">
                <div class="kpi-info">
                  <h5>Total Products</h5>
                  <div class="kpi-num" id="kpiTotal">0</div>
                </div>
              </div>

              <div class="kpi-card kpi-low">
                <div class="kpi-info">
                  <h5>Low Risk</h5>
                  <div class="kpi-num" id="kpiLow">0</div>
                </div>
              </div>

              <div class="kpi-card kpi-medium">
                <div class="kpi-info">
                  <h5>Medium Risk</h5>
                  <div class="kpi-num" id="kpiMedium">0</div>
                </div>
              </div>

              <div class="kpi-card kpi-high">
                <div class="kpi-info">
                  <h5>High Risk</h5>
                  <div class="kpi-num" id="kpiHigh">0</div>
                </div>
              </div>
            </div>

            <!-- THE INTERACTIVE RISK ASSESSMENT TABLE -->
            <div class="table-responsive-container">
              <table class="risk-calc-table" id="riskTable">
                <colgroup>
                  <col style="width: 17%;">
                  <col style="width: 17%;">
                  <col style="width: 18%;">
                  <col style="width: 19%;">
                  <col style="width: 9%;">
                  <col style="width: 9%;">
                  <col style="width: 7%;">
                  <col style="width: 4%;">
                </colgroup>
                <thead>
                  <tr>
                    <th>PRODUCT</th>
                    <th>RESPONSE VAR</th>
                    <th>COVERAGE</th>
                    <th>RESOLUTION</th>
                    <th>impact</th>
                    <th>likelihood</th>
                    <th>risk</th>
                    <th style="text-align: center;"></th>
                  </tr>
                </thead>
                <tbody id="riskTableBody">
                  <!-- Dynamically populated rows -->
                </tbody>
              </table>
            </div>

          </div>
        </div>

        <script>
        (function() {
          // Ensure Shiny does not bind to custom client-side controls inside #impact-assessment-app
          $(document).on('shiny:connected', function() {
            var rootEl = document.getElementById('impact-assessment-app');
            if (rootEl && window.Shiny && Shiny.unbindAll) {
              Shiny.unbindAll(rootEl);
            }
          });

          // =======================================================================
          // 1. RISK CALCULATION ENGINE (3x3 Matrix matching Figure 1 + NA handling)
          // =======================================================================
          function computeRisk(impact, likelihood) {
            const imp = (impact || '').trim().toUpperCase();
            const lik = (likelihood || '').trim().toUpperCase();

            if (!imp || imp === 'NA' || !lik) {
              return {
                rating: 'NA',
                badgeClass: 'badge-na',
                isNA: true,
                desc: 'Impact NA: risk calculation prevented. Specify impact level.'
              };
            }

            if (lik === 'UNLIKELY') {
              return {
                rating: 'LOW',
                badgeClass: 'badge-low',
                isNA: false,
                desc: 'acceptable, it’s possible to proceed'
              };
            } else if (lik === 'LIKELY') {
              if (imp === 'MAJOR') {
                return {
                  rating: 'MEDIUM',
                  badgeClass: 'badge-medium',
                  isNA: false,
                  desc: 'it is possible to proceed but the uncertainty can be high'
                };
              } else {
                return {
                  rating: 'LOW',
                  badgeClass: 'badge-low',
                  isNA: false,
                  desc: 'acceptable, it’s possible to proceed'
                };
              }
            } else if (lik === 'VERY LIKELY') {
              if (imp === 'MAJOR') {
                return {
                  rating: 'HIGH',
                  badgeClass: 'badge-high',
                  isNA: false,
                  desc: 'robustness of the analysis is compromised, not possible to proceed'
                };
              } else {
                return {
                  rating: 'MEDIUM',
                  badgeClass: 'badge-medium',
                  isNA: false,
                  desc: 'it is possible to proceed but the uncertainty can be high'
                };
              }
            }

            return {
              rating: 'NA',
              badgeClass: 'badge-na',
              isNA: true,
              desc: ''
            };
          }

          // =======================================================================
          // 2. EMBEDDED DATASET FROM 'Missing data by TempCov.xlsx'
          // =======================================================================
          const TEMPCOV_EXCEL_DATABASE = {
            macrogroupName: "ALL",
            taxa: [
              { id: "occurence-ALL", label: "occurence-ALL (Macrogroup)", key: "ALL" },
              { id: "occurence-NEPHROPS NORVEGICUS", label: "occurence-NEPHROPS NORVEGICUS", key: "Nephrops norvegicus" },
              { id: "occurence-MERLUCCIUS MERLUCCIUS", label: "occurence-MERLUCCIUS MERLUCCIUS", key: "Merluccius merluccius" }
            ],
            spatialRegions: [
              "Adriatic Sea",
              "Aegean-Levantine Sea",
              "Ionian Sea and the Central Mediterranean Sea",
              "Western Mediterranean Sea"
            ],
            spatialAggregations: {
              "FAO 37": ["Adriatic Sea", "Aegean-Levantine Sea", "Ionian Sea and the Central Mediterranean Sea", "Western Mediterranean Sea"]
            },
            temporalPeriods: ["2000_2009", "2010_2019", "2020_2026"],
            temporalAggregations: {
              "PRESENT": ["2000_2009", "2010_2019", "2020_2026"]
            },
            fixedResolution: "species-geo coordinates-ANNUAL",
            allSheetData: {
              "Adriatic Sea": { "2000_2009": 0.196, "2010_2019": 0.336, "2020_2026": 1.0 },
              "Aegean-Levantine Sea": { "2000_2009": 0.501907, "2010_2019": 0.501907, "2020_2026": 1.0 },
              "Ionian Sea and the Central Mediterranean Sea": { "2000_2009": 0.265027, "2010_2019": 1.0, "2020_2026": 1.0 },
              "Western Mediterranean Sea": { "2000_2009": 0.160987, "2010_2019": 0.289462, "2020_2026": 0.248174 }
            },
            data: {
              "2000_2009": {
                "Adriatic Sea": { "ALL": 0.196, "Nephrops norvegicus": 0.196, "Merluccius merluccius": 0.196 },
                "Aegean-Levantine Sea": { "ALL": 0.501907, "Nephrops norvegicus": 1.0, "Merluccius merluccius": 0.335876 },
                "Ionian Sea and the Central Mediterranean Sea": { "ALL": 0.265027, "Nephrops norvegicus": 0.274652, "Merluccius merluccius": 0.261818 },
                "Western Mediterranean Sea": { "ALL": 0.160987, "Nephrops norvegicus": 0.162332, "Merluccius merluccius": 0.160538 },
                "FAO 37": { "ALL": 0.187359, "Nephrops norvegicus": 0.187583, "Merluccius merluccius": 0.187135 }
              },
              "2010_2019": {
                "Adriatic Sea": { "ALL": 0.336, "Nephrops norvegicus": 0.336, "Merluccius merluccius": 0.336 },
                "Aegean-Levantine Sea": { "ALL": 0.501907, "Nephrops norvegicus": 1.0, "Merluccius merluccius": 0.335876 },
                "Ionian Sea and the Central Mediterranean Sea": { "ALL": 1.0, "Nephrops norvegicus": 1.0, "Merluccius merluccius": 1.0 },
                "Western Mediterranean Sea": { "ALL": 0.289462, "Nephrops norvegicus": 0.270135, "Merluccius merluccius": 0.347444 },
                "FAO 37": { "ALL": 0.327751, "Nephrops norvegicus": 0.319534, "Merluccius merluccius": 0.335969 }
              },
              "2020_2026": {
                "Adriatic Sea": { "ALL": 1.0, "Nephrops norvegicus": 1.0, "Merluccius merluccius": 1.0 },
                "Aegean-Levantine Sea": { "ALL": 1.0, "Nephrops norvegicus": 1.0, "Merluccius merluccius": 1.0 },
                "Ionian Sea and the Central Mediterranean Sea": { "ALL": 1.0, "Nephrops norvegicus": 1.0, "Merluccius merluccius": 1.0 },
                "Western Mediterranean Sea": { "ALL": 0.248174, "Nephrops norvegicus": 0.248174, "Merluccius merluccius": 0.248174 },
                "FAO 37": { "ALL": 0.812044, "Nephrops norvegicus": 0.812044, "Merluccius merluccius": 0.812044 }
              },
              "PRESENT": {
                "Adriatic Sea": { "ALL": 0.336, "Nephrops norvegicus": 0.336, "Merluccius merluccius": 0.336 },
                "Aegean-Levantine Sea": { "ALL": 0.501907, "Nephrops norvegicus": 1.0, "Merluccius merluccius": 0.501907 },
                "Ionian Sea and the Central Mediterranean Sea": { "ALL": 1.0, "Nephrops norvegicus": 1.0, "Merluccius merluccius": 1.0 },
                "Western Mediterranean Sea": { "ALL": 0.248174, "Nephrops norvegicus": 0.248174, "Merluccius merluccius": 0.289462 },
                "FAO 37": { "ALL": 0.289462, "Nephrops norvegicus": 0.319534, "Merluccius merluccius": 0.335969 }
              }
            }
          };

          let activeExcelDatabase = JSON.parse(JSON.stringify(TEMPCOV_EXCEL_DATABASE));

          function calculateQuantile(arr, q = 0.25) {
            if (!arr || arr.length === 0) return 0;
            if (arr.length === 1) return arr[0];
            const sorted = arr.slice().sort((a, b) => a - b);
            const index = (sorted.length - 1) * q;
            const i = Math.floor(index);
            const frac = index - i;
            if (sorted[i + 1] !== undefined) {
              return sorted[i] + frac * (sorted[i + 1] - sorted[i]);
            }
            return sorted[i];
          }

          function getExcelMissingData(taxonId, spatial, temporal) {
            if (typeof spatial === 'string' && (!temporal || temporal === '') && spatial.includes('-')) {
              const parts = spatial.split('-');
              spatial = parts[0].trim();
              temporal = parts.slice(1).join('-').trim();
            }

            spatial = spatial || (activeExcelDatabase.spatialAggregations && Object.keys(activeExcelDatabase.spatialAggregations)[0]) || (activeExcelDatabase.spatialRegions && activeExcelDatabase.spatialRegions[0]) || "FAO 37";
            temporal = temporal || (activeExcelDatabase.temporalPeriods && activeExcelDatabase.temporalPeriods[0]) || "2000_2009";

            let taxonKey = "ALL";
            const taxonObj = (activeExcelDatabase.taxa || []).find(t => t.id === taxonId);
            if (taxonObj) {
              taxonKey = taxonObj.key;
            } else if (taxonId) {
              const match = taxonId.match(/^(?:occurence|occurrence|biomass|abundance)[-_](.+)$/i);
              taxonKey = match ? match[1] : taxonId;
            }

            let periods = [];
            if (activeExcelDatabase.temporalAggregations && activeExcelDatabase.temporalAggregations[temporal]) {
              periods = activeExcelDatabase.temporalAggregations[temporal];
            } else if (temporal.includes('+')) {
              periods = temporal.split('+').map(s => s.trim()).filter(Boolean);
            } else {
              periods = [temporal];
            }

            let regions = [];
            if (activeExcelDatabase.spatialAggregations && activeExcelDatabase.spatialAggregations[spatial]) {
              regions = activeExcelDatabase.spatialAggregations[spatial];
            } else {
              regions = [spatial];
            }

            const values = [];

            periods.forEach(p => {
              regions.forEach(reg => {
                let val = undefined;
                if (taxonKey === 'ALL') {
                  let allSheetRegData = activeExcelDatabase.allSheetData ? activeExcelDatabase.allSheetData[reg] : undefined;
                  if (!allSheetRegData && activeExcelDatabase.allSheetData) {
                    const mReg = Object.keys(activeExcelDatabase.allSheetData).find(k => k.toLowerCase() === reg.toLowerCase());
                    if (mReg) allSheetRegData = activeExcelDatabase.allSheetData[mReg];
                  }
                  if (allSheetRegData) {
                    if (allSheetRegData[p] !== undefined) {
                      val = allSheetRegData[p];
                    } else {
                      const mP = Object.keys(allSheetRegData).find(k => k.toLowerCase() === p.toLowerCase());
                      if (mP) val = allSheetRegData[mP];
                    }
                  }

                  if (val === undefined && activeExcelDatabase.data) {
                    let pData = activeExcelDatabase.data[p];
                    if (!pData) {
                      const mP = Object.keys(activeExcelDatabase.data).find(k => k.toLowerCase() === p.toLowerCase());
                      if (mP) pData = activeExcelDatabase.data[mP];
                    }
                    if (pData) {
                      let regData = pData[reg];
                      if (!regData) {
                        const mReg = Object.keys(pData).find(k => k.toLowerCase() === reg.toLowerCase());
                        if (mReg) regData = pData[mReg];
                      }
                      if (regData) {
                        val = regData['ALL'] !== undefined ? regData['ALL'] : regData['1st_Quartile'];
                      }
                    }
                  }
                } else {
                  if (activeExcelDatabase.data) {
                    let pData = activeExcelDatabase.data[p];
                    if (!pData) {
                      const mP = Object.keys(activeExcelDatabase.data).find(k => k.toLowerCase() === p.toLowerCase());
                      if (mP) pData = activeExcelDatabase.data[mP];
                    }
                    if (pData) {
                      let regData = pData[reg];
                      if (!regData) {
                        const mReg = Object.keys(pData).find(k => k.toLowerCase() === reg.toLowerCase());
                        if (mReg) regData = pData[mReg];
                      }
                      if (regData) {
                        val = regData[taxonKey];
                        if (val === undefined) {
                          const mTax = Object.keys(regData).find(k => k.toLowerCase() === taxonKey.toLowerCase());
                          if (mTax) val = regData[mTax];
                        }
                      }
                    }
                  }
                }

                if (typeof val === 'number' && !isNaN(val)) {
                  values.push(val);
                }
              });
            });

            let q1 = 0.25;
            if (values.length > 0) {
              q1 = calculateQuantile(values, 0.25);
            }

            let likelihood = "UNLIKELY";
            if (q1 <= 0.33) {
              likelihood = "UNLIKELY";
            } else if (q1 <= 0.66) {
              likelihood = "LIKELY";
            } else {
              likelihood = "VERY LIKELY";
            }

            return {
              q1: q1,
              percentage: (q1 * 100).toFixed(1) + '%',
              likelihood: likelihood
            };
          }

          // =======================================================================
          // 3. CASE STUDY DATA PRESETS (Filtered: only occurrence and biomass rows, without drivers)
          // =======================================================================
          const CASE_PRESETS = {
            case1: [
              // Linear model (2 rows)
              { product: "Linear model", resp_driver: "occurence-FISH", coverage: "FAO 27-2010_2019, 2020_2025", resolution: "species-geo coordinates-DAILY/WEEKLY", impact: "MINOR", likelihood: "UNLIKELY", risk: "LOW", locked: true },
              { product: "Linear model", resp_driver: "biomass-FISH", coverage: "FAO 27-2010_2019, 2020_2025", resolution: "species-geo shapes-ANNUAL/MULTI-ANNUAL", impact: "MINOR", likelihood: "LIKELY", risk: "LOW", locked: true },
              // Multispecies distribution model (3 rows)
              { product: "Multispecies distribution model", resp_driver: "occurence-FISH", coverage: "FAO 27-2010_2019, 2020_2025", resolution: "species-geo coordinates-DAILY/WEEKLY", impact: "MODERATE", likelihood: "UNLIKELY", risk: "LOW", locked: true },
              { product: "Multispecies distribution model", resp_driver: "biomass-FISH", coverage: "FAO 27-2010_2019, 2020_2025", resolution: "species-geo shapes-ANNUAL/MULTI-ANNUAL", impact: "MODERATE", likelihood: "LIKELY", risk: "LOW", locked: true },
              { product: "Multispecies distribution model", resp_driver: "biomass-CRUSTACEAN", coverage: "FAO 27-2010_2019, 2020_2025", resolution: "species-geo shapes-ANNUAL/MULTI-ANNUAL", impact: "MODERATE", likelihood: "LIKELY", risk: "LOW", locked: true },
              // ecosystem modeling (5 rows)
              { product: "ecosystem modeling", resp_driver: "occurence-FISH", coverage: "FAO 27-2010_2019, 2020_2025", resolution: "species-geo coordinates-DAILY/WEEKLY", impact: "MAJOR", likelihood: "UNLIKELY", risk: "LOW", locked: true },
              { product: "ecosystem modeling", resp_driver: "occurence-MACROALGAE", coverage: "FAO 27-2010_2019, 2020_2025", resolution: "species-geo coordinates-DAILY/WEEKLY", impact: "MAJOR", likelihood: "LIKELY", risk: "MEDIUM", locked: true },
              { product: "ecosystem modeling", resp_driver: "occurence-BENTHIC INVERTEBRATES", coverage: "FAO 27-2010_2019, 2020_2025", resolution: "species-geo coordinates-DAILY/WEEKLY", impact: "MAJOR", likelihood: "LIKELY", risk: "MEDIUM", locked: true },
              { product: "ecosystem modeling", resp_driver: "biomass-FISH", coverage: "FAO 27-2010_2019, 2020_2025", resolution: "species-geo shapes-ANNUAL/MULTI-ANNUAL", impact: "MAJOR", likelihood: "LIKELY", risk: "MEDIUM", locked: true },
              { product: "ecosystem modeling", resp_driver: "biomass-CRUSTACEAN", coverage: "FAO 27-2010_2019, 2020_2025", resolution: "species-geo shapes-ANNUAL/MULTI-ANNUAL", impact: "MAJOR", likelihood: "LIKELY", risk: "MEDIUM", locked: true }
            ],
            empty: []
          };

          // =======================================================================
          // 4. TABLE RENDERING AND ROW MANAGEMENT
          // =======================================================================
          const tableBody = document.getElementById('riskTableBody');
          const kpiTotal = document.getElementById('kpiTotal');
          const kpiLow = document.getElementById('kpiLow');
          const kpiMedium = document.getElementById('kpiMedium');
          const kpiHigh = document.getElementById('kpiHigh');
          const presetSelect = document.getElementById('casePresetSelect');

          let tableRowsData = [];
          let currentPresetKey = 'empty';

          function createRowElement(data, index) {
            const tr = document.createElement('tr');
            tr.dataset.index = index;

            const isLocked = !!data.locked;
            const isParamsLocked = isLocked || !!data.lockedParams;
            const riskObj = computeRisk(data.impact, data.likelihood);

            const productStyle = (data.product === 'to be specified' || data.isItalicProduct)
              ? 'font-style: italic; color: #475569;'
              : '';

            const disabledAttr = isLocked ? 'readonly disabled' : '';
            const paramsDisabledAttr = isParamsLocked ? 'readonly disabled' : '';
            const inputReadonlyClass = isLocked ? 'table-input-readonly' : '';
            const paramsReadonlyClass = isParamsLocked ? 'table-input-readonly' : '';
            const selectDisabledAttr = isLocked ? 'disabled' : '';
            const selectReadonlyClass = isLocked ? 'select-readonly' : '';

            const impactOptions = `
              <option value="NA" ${(!data.impact || data.impact === 'NA') ? 'selected' : ''}>NA</option>
              <option value="MINOR" ${data.impact === 'MINOR' ? 'selected' : ''}>MINOR</option>
              <option value="MODERATE" ${data.impact === 'MODERATE' ? 'selected' : ''}>MODERATE</option>
              <option value="MAJOR" ${data.impact === 'MAJOR' ? 'selected' : ''}>MAJOR</option>
            `;

            const likelihoodOptions = `
              <option value="" disabled ${!data.likelihood ? 'selected' : ''}>Select likelihood</option>
              <option value="UNLIKELY" ${data.likelihood === 'UNLIKELY' ? 'selected' : ''}>UNLIKELY</option>
              <option value="LIKELY" ${data.likelihood === 'LIKELY' ? 'selected' : ''}>LIKELY</option>
              <option value="VERY LIKELY" ${data.likelihood === 'VERY LIKELY' ? 'selected' : ''}>VERY LIKELY</option>
            `;

            let riskHtml = '';
            if (riskObj.isNA) {
              riskHtml = `<span class="risk-badge badge-na" title="${riskObj.desc}"><i class="fa-solid fa-triangle-exclamation" style="color: #000000;"></i> NA</span>`;
            } else {
              riskHtml = `<span class="risk-badge ${riskObj.badgeClass}" title="${riskObj.rating}: ${riskObj.desc}">${riskObj.rating}</span>`;
            }

            tr.innerHTML = `
              <td>
                <input type="text" ${disabledAttr} class="table-input-text col-product ${inputReadonlyClass}" style="${productStyle}" value="${escapeHtml(data.product || '')}" placeholder="e.g. Linear model">
              </td>
              <td>
                <input type="text" ${paramsDisabledAttr} class="table-input-text col-resp ${paramsReadonlyClass}" value="${escapeHtml(data.resp_driver || '')}" placeholder="e.g. occurence-FISH">
              </td>
              <td>
                <input type="text" ${paramsDisabledAttr} class="table-input-text col-coverage ${paramsReadonlyClass}" value="${escapeHtml(data.coverage || '')}" placeholder="e.g. FAO 27-2010_2019, 2020_2025">
              </td>
              <td>
                <input type="text" ${paramsDisabledAttr} class="table-input-text col-resolution ${paramsReadonlyClass}" value="${escapeHtml(data.resolution || '')}" placeholder="species-geo coordinates-ANNUAL">
              </td>
              <td>
                <select ${selectDisabledAttr} class="table-select select-impact col-impact ${selectReadonlyClass}" data-tier="${data.impact || 'NA'}" title="Select Impact Severity Level">
                  ${impactOptions}
                </select>
              </td>
              <td>
                <select ${selectDisabledAttr} class="table-select select-likelihood col-likelihood ${selectReadonlyClass}" data-tier="${data.likelihood || 'LIKELY'}" title="Select Likelihood Level">
                  ${likelihoodOptions}
                </select>
              </td>
              <td class="col-risk-cell">
                ${riskHtml}
              </td>
              <td style="text-align: center;">
                <button type="button" class="btn-row-delete" ${isLocked ? 'disabled title="Preset values are locked"' : 'title="Remove this product"'} data-row-idx="${index}">
                  <i class="fa-regular fa-trash-can"></i>
                </button>
              </td>
            `;

            if (!isLocked) {
              const impactSelect = tr.querySelector('.col-impact');
              const likelihoodSelect = tr.querySelector('.col-likelihood');
              const riskCell = tr.querySelector('.col-risk-cell');

              function updateRowRisk() {
                const impVal = impactSelect ? impactSelect.value : 'NA';
                const likVal = likelihoodSelect ? likelihoodSelect.value : '';

                if (impactSelect) impactSelect.setAttribute('data-tier', impVal);
                if (likelihoodSelect) likelihoodSelect.setAttribute('data-tier', likVal);

                const newRisk = computeRisk(impVal, likVal);

                data.impact = impVal;
                data.likelihood = likVal;
                data.risk = newRisk.rating;

                if (riskCell) {
                  if (newRisk.isNA) {
                    riskCell.innerHTML = `<span class="risk-badge badge-na" title="${newRisk.desc}"><i class="fa-solid fa-triangle-exclamation" style="color: #000000;"></i> NA</span>`;
                  } else {
                    riskCell.innerHTML = `<span class="risk-badge ${newRisk.badgeClass}" title="${newRisk.rating}: ${newRisk.desc}">${newRisk.rating}</span>`;
                  }
                }

                updateKpiMetrics();
              }

              if (impactSelect) impactSelect.addEventListener('change', updateRowRisk);
              if (likelihoodSelect) likelihoodSelect.addEventListener('change', updateRowRisk);

              const prodInput = tr.querySelector('.col-product');
              if (prodInput) {
                prodInput.addEventListener('input', (e) => {
                  data.product = e.target.value;
                  data.isItalicProduct = false;
                  e.target.style.fontStyle = 'normal';
                });
              }

              if (!isParamsLocked) {
                const respInput = tr.querySelector('.col-resp');
                if (respInput) respInput.addEventListener('input', (e) => { data.resp_driver = e.target.value; });

                const covInput = tr.querySelector('.col-coverage');
                if (covInput) covInput.addEventListener('input', (e) => { data.coverage = e.target.value; });

                const resInput = tr.querySelector('.col-resolution');
                if (resInput) resInput.addEventListener('input', (e) => { data.resolution = e.target.value; });
              }

              const delBtn = tr.querySelector('.btn-row-delete');
              if (delBtn) {
                delBtn.addEventListener('click', () => {
                  tableRowsData.splice(index, 1);
                  renderTable();
                });
              }
            }

            return tr;
          }

          function renderTable() {
            tableBody.innerHTML = '';
            if (tableRowsData.length === 0) {
              tableBody.innerHTML = `
                <tr>
                  <td colspan="8" class="empty-table-state" style="text-align: center; padding: 3rem 1rem; color: #64748b;">
                    <i class="fa-solid fa-table-list" style="font-size: 2.2rem; color: #94a3b8; margin-bottom: 0.75rem; display: block;"></i>
                    <p style="margin: 0;">Blank Assessment Template. Click <strong>Import Missing data by TempCov.xlsx</strong> to start or select a <strong>Case Study Preset</strong>.</p>
                  </td>
                </tr>
              `;
              updateKpiMetrics();
              return;
            }

            tableRowsData.forEach((row, i) => {
              const tr = createRowElement(row, i);
              tableBody.appendChild(tr);
            });

            updateKpiMetrics();
          }

          function updateKpiMetrics() {
            const total = tableRowsData.length;
            let lowCount = 0;
            let medCount = 0;
            let highCount = 0;

            tableRowsData.forEach(row => {
              const r = computeRisk(row.impact, row.likelihood);
              if (!r.isNA) {
                if (r.rating === 'LOW') lowCount++;
                else if (r.rating === 'MEDIUM') medCount++;
                else if (r.rating === 'HIGH') highCount++;
              }
            });

            kpiTotal.textContent = total;
            kpiLow.textContent = lowCount;
            kpiMedium.textContent = medCount;
            kpiHigh.textContent = highCount;
          }

          function escapeHtml(str) {
            if (!str) return '';
            return String(str)
              .replace(/&/g, '&amp;')
              .replace(/</g, '&lt;')
              .replace(/>/g, '&gt;')
              .replace(/"/g, '&quot;');
          }

          function loadPreset(key) {
            currentPresetKey = key;
            const source = CASE_PRESETS[key] || [];
            tableRowsData = JSON.parse(JSON.stringify(source));
            renderTable();
          }

          // =======================================================================
          // 5. IMPORT MISSING DATA BY TEMPCOV.XLSX / CSV FUNCTIONALITY
          // =======================================================================
          const btnImportXlsx = document.getElementById('btnImportXlsx');
          const xlsxFileInput = document.getElementById('xlsxFileInput');
          const importConfigPanel = document.getElementById('importConfigPanel');
          const btnCloseImportPanel = document.getElementById('btnCloseImportPanel');
          const importFileNameText = document.getElementById('importFileNameText');
          const importTaxonSelect = document.getElementById('importTaxonSelect');
          const importSpatialSelect = document.getElementById('importSpatialSelect');
          const importTemporalSelect = document.getElementById('importTemporalSelect');
          const importQ1Text = document.getElementById('importQ1Text');
          const importLikelihoodBadge = document.getElementById('importLikelihoodBadge');

          btnImportXlsx.addEventListener('click', () => {
            xlsxFileInput.value = '';
            xlsxFileInput.click();
          });

          xlsxFileInput.addEventListener('change', (e) => {
            e.stopPropagation();
            const file = e.target.files[0];
            if (!file) return;

            const reader = new FileReader();

            reader.onload = function(evt) {
              try {
                if (typeof XLSX !== 'undefined') {
                  const data = new Uint8Array(evt.target.result);
                  const workbook = XLSX.read(data, { type: 'array' });
                  processWorkbook(workbook, file.name);
                } else {
                  openImportPanel(file.name);
                }
              } catch(err) {
                console.error("File parse error:", err);
                openImportPanel(file.name);
              }
            };
            reader.readAsArrayBuffer(file);
          });

          function processWorkbook(wb, fileName) {
            const firstSheetName = wb.SheetNames[0];
            const firstSheet = wb.Sheets[firstSheetName];
            const sheetData = XLSX.utils.sheet_to_json(firstSheet, { header: 1 });

            if (sheetData && sheetData.length > 1) {
              const headerRow = (sheetData[0] || []).map(h => String(h || '').trim().toUpperCase());
              if (headerRow.includes('PRODUCT') && (headerRow.includes('RESPONSE VAR') || headerRow.includes('COVERAGE'))) {
                const prodIdx = headerRow.indexOf('PRODUCT');
                const respIdx = headerRow.indexOf('RESPONSE VAR');
                const covIdx = headerRow.indexOf('COVERAGE');
                const resIdx = headerRow.indexOf('RESOLUTION');
                const impIdx = headerRow.indexOf('IMPACT');
                const likIdx = headerRow.indexOf('LIKELIHOOD');

                tableRowsData = [];
                for (let r = 1; r < sheetData.length; r++) {
                  const row = sheetData[r];
                  if (!row || row.length === 0) continue;
                  const prod = prodIdx >= 0 ? String(row[prodIdx] || '').trim() : '';
                  const resp = respIdx >= 0 ? String(row[respIdx] || '').trim() : '';
                  const cov = covIdx >= 0 ? String(row[covIdx] || '').trim() : '';
                  const res = resIdx >= 0 ? String(row[resIdx] || '').trim() : '';
                  const imp = impIdx >= 0 ? String(row[impIdx] || '').trim() : 'NA';
                  const lik = likIdx >= 0 ? String(row[likIdx] || '').trim() : '';

                  tableRowsData.push({
                    product: prod,
                    isItalicProduct: prod.toLowerCase() === 'to be specified',
                    resp_driver: resp,
                    coverage: cov,
                    resolution: res,
                    impact: imp || 'NA',
                    likelihood: lik,
                    risk: computeRisk(imp, lik).rating,
                    locked: false,
                    lockedParams: false
                  });
                }

                currentPresetKey = 'empty';
                presetSelect.value = 'empty';
                renderTable();
                return;
              }
            }

            let macrogroupName = "ALL";
            const spatialGroups = {};
            const spatialRegionsFromCol6 = [];
            const temporalFromCol2 = [];
            let fixedRes = "species-geo coordinates-ANNUAL";

            if (wb.Sheets['Execution_log']) {
              const execSheet = wb.Sheets['Execution_log'];
              const execJson = XLSX.utils.sheet_to_json(execSheet, { header: 1 });

              for (let r = 0; r < execJson.length; r++) {
                const row = execJson[r] || [];
                for (let c = 0; c < row.length; c++) {
                  const cellVal = String(row[c] || '').trim();
                  if (cellVal.toLowerCase() === 'macrogroup') {
                    if (execJson[r + 1] && execJson[r + 1][c] !== undefined) {
                      const mgVal = String(execJson[r + 1][c] || '').trim();
                      if (mgVal !== '') {
                        macrogroupName = mgVal;
                      }
                    }
                    break;
                  }
                }
                if (macrogroupName !== "ALL") break;
              }

              let spatStartRow = -1;
              let spatColGroup = 4;
              let spatColEco = 5;
              for (let r = 3; r < execJson.length; r++) {
                const row = execJson[r] || [];
                for (let c = 0; c < row.length; c++) {
                  const val = String(row[c] || '').trim().toLowerCase();
                  if (val.startsWith('spatial coverage')) {
                    spatStartRow = r + 1;
                    spatColGroup = c;
                    spatColEco = c + 1;
                    break;
                  }
                }
                if (spatStartRow >= 0) break;
              }
              if (spatStartRow < 0) spatStartRow = 5;

              let currentGroup = '';
              for (let r = spatStartRow; r < execJson.length; r++) {
                const row = execJson[r] || [];
                const grpCell = String(row[spatColGroup] || '').trim();
                const ecoCell = String(row[spatColEco] || '').trim();
                const firstCol = String(row[0] || '').trim();

                if (firstCol.toLowerCase().includes('execution alert') || ecoCell.toLowerCase().includes('execution alert')) {
                  break;
                }
                if (grpCell) {
                  currentGroup = grpCell;
                  if (!spatialGroups[currentGroup]) spatialGroups[currentGroup] = [];
                }
                if (ecoCell) {
                  if (!spatialRegionsFromCol6.includes(ecoCell)) {
                    spatialRegionsFromCol6.push(ecoCell);
                  }
                  if (currentGroup) {
                    if (!spatialGroups[currentGroup].includes(ecoCell)) {
                      spatialGroups[currentGroup].push(ecoCell);
                    }
                  }
                }
                if (!grpCell && !ecoCell && r > spatStartRow + 2) {
                  const nextEco = String((execJson[r + 1] && execJson[r + 1][spatColEco]) || '').trim();
                  if (!nextEco) break;
                }
              }

              let tempStartRow = -1;
              let tempColGroup = 0;
              let tempColPeriod = 1;
              for (let r = 3; r < execJson.length; r++) {
                const row = execJson[r] || [];
                for (let c = 0; c < row.length; c++) {
                  const val = String(row[c] || '').trim().toLowerCase();
                  if (val.startsWith('temporal coverage')) {
                    tempStartRow = r + 1;
                    tempColGroup = c;
                    tempColPeriod = c + 1;
                    break;
                  }
                }
                if (tempStartRow >= 0) break;
              }
              if (tempStartRow < 0) tempStartRow = 5;

              for (let r = tempStartRow; r < execJson.length; r++) {
                const row = execJson[r] || [];
                const periodCell = String(row[tempColPeriod] || '').trim();
                const firstCol = String(row[0] || '').trim();

                if (firstCol.toLowerCase().includes('execution alert') || periodCell.toLowerCase().includes('execution alert')) {
                  break;
                }
                if (periodCell) {
                  if (!temporalFromCol2.includes(periodCell)) {
                    temporalFromCol2.push(periodCell);
                  }
                }
                if (!periodCell && !firstCol && r > tempStartRow + 2) {
                  const nextP = String((execJson[r + 1] && execJson[r + 1][tempColPeriod]) || '').trim();
                  if (!nextP) break;
                }
              }

              let taxRes = 'species', spatRes = 'geo coordinates', tempRes = 'ANNUAL';
              for (let r = 3; r < execJson.length; r++) {
                const row = execJson[r] || [];
                for (let c = 0; c < row.length; c++) {
                  const txt = String(row[c] || '').toLowerCase();
                  if (txt.includes('taxonomic') && row[c + 1]) taxRes = String(row[c + 1]).trim();
                  if (txt.includes('spatial') && row[c + 1]) spatRes = String(row[c + 1]).trim();
                  if (txt.includes('temporal') && row[c + 1]) tempRes = String(row[c + 1]).trim().toUpperCase();
                }
              }
              fixedRes = `${taxRes}-${spatRes}-${tempRes}`;
            }

            const allSheetData = {};
            const allSheetPeriods = [];
            const allSheetRegions = [];
            if (wb.Sheets['ALL']) {
              const allSheet = wb.Sheets['ALL'];
              const allJson = XLSX.utils.sheet_to_json(allSheet, { header: 1 });
              if (allJson && allJson.length > 0) {
                const headerRow = allJson[0] || [];
                for (let c = 1; c < headerRow.length; c++) {
                  const p = String(headerRow[c] || '').trim();
                  if (p && !p.toLowerCase().includes('legend')) {
                    allSheetPeriods.push(p);
                  }
                }
                for (let r = 1; r < allJson.length; r++) {
                  const row = allJson[r] || [];
                  const reg = String(row[0] || '').trim();
                  const lowerReg = reg.toLowerCase();
                  if (!reg || lowerReg.includes('colour legend') || lowerReg.includes('quartile') || lowerReg.includes('<=') || lowerReg.includes('>') || lowerReg.startsWith('x ')) continue;
                  allSheetRegions.push(reg);
                  allSheetData[reg] = {};
                  for (let c = 1; c < headerRow.length; c++) {
                    const p = String(headerRow[c] || '').trim();
                    const val = parseFloat(row[c]);
                    if (!isNaN(val)) {
                      allSheetData[reg][p] = val;
                    }
                  }
                }
              }
            }

            const temporalSheets = wb.SheetNames.filter(s => s !== 'Execution_log' && s !== 'ALL');
            const matrixData = {};
            const taxaList = [];

            let respPrefix = 'occurence-';
            const lowerFileName = (fileName || '').toLowerCase();
            if (lowerFileName.includes('biomass_')) {
              respPrefix = 'biomass_';
            } else if (lowerFileName.includes('biomass')) {
              respPrefix = 'biomass-';
            } else if (lowerFileName.includes('abundance')) {
              respPrefix = 'abundance-';
            }

            const macroDisplay = (macrogroupName && macrogroupName.toUpperCase() !== 'ALL') ? macrogroupName.toUpperCase() : 'ALL';
            taxaList.push({
              id: `${respPrefix}${macroDisplay}`,
              label: `${respPrefix}${macroDisplay} (Macrogroup)`,
              key: 'ALL'
            });

            if (temporalSheets.length > 0) {
              const firstSheet = wb.Sheets[temporalSheets[0]];
              const firstJson = XLSX.utils.sheet_to_json(firstSheet, { header: 1 });
              if (firstJson && firstJson.length > 0) {
                const headers = firstJson[0] || [];
                for (let col = 1; col < headers.length; col++) {
                  const h = String(headers[col] || '').trim();
                  if (h && h !== '1st_Quartile' && !taxaList.some(t => t.key.toLowerCase() === h.toLowerCase())) {
                    const upperH = h.toUpperCase();
                    taxaList.push({
                      id: `${respPrefix}${upperH}`,
                      label: `${respPrefix}${upperH}`,
                      key: h
                    });
                  }
                }
              }

              temporalSheets.forEach(sheetName => {
                const curSheet = wb.Sheets[sheetName];
                const curJson = XLSX.utils.sheet_to_json(curSheet, { header: 1 });
                if (curJson && curJson.length > 1) {
                  if (!matrixData[sheetName]) matrixData[sheetName] = {};
                  const headerRow = curJson[0] || [];
                  for (let r = 1; r < curJson.length; r++) {
                    const row = curJson[r] || [];
                    const rowLabel = String(row[0] || '').trim();
                    const lowerRow = rowLabel.toLowerCase();
                    if (!rowLabel || lowerRow.includes('colour legend') || lowerRow.includes('quartile') || lowerRow.includes('<=') || lowerRow.includes('>')) continue;
                    if (!matrixData[sheetName][rowLabel]) {
                      matrixData[sheetName][rowLabel] = {};
                    }
                    for (let c = 1; c < headerRow.length; c++) {
                      const taxonHeader = String(headerRow[c] || '').trim();
                      const taxonKey = (taxonHeader === '1st_Quartile') ? 'ALL' : taxonHeader;
                      const val = parseFloat(row[c]);
                      if (!isNaN(val)) {
                        matrixData[sheetName][rowLabel][taxonKey] = val;
                      }
                    }
                  }
                }
              });
            }

            const finalSpatialRegions = spatialRegionsFromCol6.length > 0 ? spatialRegionsFromCol6 : (allSheetRegions.length > 0 ? allSheetRegions : []);

            const finalSpatialAggregations = { ...spatialGroups };
            if (Object.keys(finalSpatialAggregations).length === 0 && finalSpatialRegions.length > 0) {
              finalSpatialAggregations["FAO 37"] = finalSpatialRegions;
            } else if (Object.keys(finalSpatialAggregations).length > 1) {
              finalSpatialAggregations["Full Domain"] = finalSpatialRegions;
            }

            const finalTemporalPeriods = temporalFromCol2.length > 0 ? temporalFromCol2 : (temporalSheets.length > 0 ? temporalSheets : allSheetPeriods);

            activeExcelDatabase = {
              macrogroupName: macroDisplay,
              taxa: taxaList,
              spatialRegions: finalSpatialRegions,
              spatialAggregations: finalSpatialAggregations,
              temporalPeriods: finalTemporalPeriods,
              temporalAggregations: {},
              allSheetData: allSheetData,
              data: matrixData,
              fixedResolution: fixedRes
            };

            openImportPanel(fileName);
          }

          function openImportPanel(fileName) {
            importConfigPanel.style.display = 'block';
            const addBtn = document.getElementById('btnAddRowBtn');
            if (addBtn) addBtn.style.display = 'inline-flex';
            if (importFileNameText) importFileNameText.textContent = fileName || 'Missing data by TempCov.xlsx';

            importTaxonSelect.innerHTML = '';
            (activeExcelDatabase.taxa || []).forEach(t => {
              const opt = document.createElement('option');
              opt.value = t.id;
              opt.textContent = t.label;
              importTaxonSelect.appendChild(opt);
            });

            importSpatialSelect.innerHTML = '';
            if (activeExcelDatabase.spatialAggregations) {
              Object.keys(activeExcelDatabase.spatialAggregations).forEach(aggKey => {
                const opt = document.createElement('option');
                opt.value = aggKey;
                opt.textContent = aggKey === "Full Domain" ? "Full Domain (All Ecoregions)" : `${aggKey} (Full Domain)`;
                importSpatialSelect.appendChild(opt);
              });
            }
            if (activeExcelDatabase.spatialRegions) {
              activeExcelDatabase.spatialRegions.forEach(reg => {
                if (!activeExcelDatabase.spatialAggregations || !activeExcelDatabase.spatialAggregations[reg]) {
                  const opt = document.createElement('option');
                  opt.value = reg;
                  opt.textContent = reg;
                  importSpatialSelect.appendChild(opt);
                }
              });
            }

            importTemporalSelect.innerHTML = '';
            (activeExcelDatabase.temporalPeriods || []).forEach(p => {
              const opt = document.createElement('option');
              opt.value = p;
              opt.textContent = p;
              importTemporalSelect.appendChild(opt);
            });

            const fixedResEl = document.getElementById('importFixedResText');
            if (fixedResEl) {
              fixedResEl.textContent = activeExcelDatabase.fixedResolution || 'species-geo coordinates-ANNUAL';
            }

            updateImportPreview();
            importConfigPanel.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
          }

          function updateImportPreview() {
            const taxonId = importTaxonSelect.value;
            const spatialVal = importSpatialSelect.value;
            const temporalVal = importTemporalSelect.value;
            const outcome = getExcelMissingData(taxonId, spatialVal, temporalVal);

            importQ1Text.textContent = `Q1: ${outcome.percentage}`;
            importLikelihoodBadge.textContent = outcome.likelihood;
            importLikelihoodBadge.className = 'q1-tier-badge';
            if (outcome.likelihood === 'UNLIKELY') {
              importLikelihoodBadge.classList.add('tier-unlikely');
            } else if (outcome.likelihood === 'LIKELY') {
              importLikelihoodBadge.classList.add('tier-likely');
            } else {
              importLikelihoodBadge.classList.add('tier-very-likely');
            }
          }

          importTaxonSelect.addEventListener('change', () => {
            updateImportPreview();
          });

          importSpatialSelect.addEventListener('change', () => {
            updateImportPreview();
          });

          importTemporalSelect.addEventListener('change', () => {
            updateImportPreview();
          });

          btnCloseImportPanel.addEventListener('click', () => {
            importConfigPanel.style.display = 'none';
            const addBtn = document.getElementById('btnAddRowBtn');
            if (addBtn) addBtn.style.display = 'none';
          });

          // =======================================================================
          // 6. TOOLBAR EVENT LISTENERS (Add Product from Imported File, Presets, Export)
          // =======================================================================
          presetSelect.addEventListener('change', (e) => {
            loadPreset(e.target.value);
          });

          document.getElementById('btnAddRowBtn').addEventListener('click', () => {
            const isImportOpen = importConfigPanel && importConfigPanel.style.display !== 'none';
            if (!isImportOpen) {
              return;
            }

            if (currentPresetKey === 'case1') {
              presetSelect.value = 'empty';
              currentPresetKey = 'empty';
            }

            const taxonId = importTaxonSelect.value || (activeExcelDatabase.taxa && activeExcelDatabase.taxa[0] ? activeExcelDatabase.taxa[0].id : "occurence-ALL");
            const spatialVal = importSpatialSelect.value || (activeExcelDatabase.spatialRegions && activeExcelDatabase.spatialRegions[0]) || "FAO 37";
            const temporalVal = importTemporalSelect.value || (activeExcelDatabase.temporalPeriods && activeExcelDatabase.temporalPeriods[0]) || "2000_2009";
            const coverageCode = `${spatialVal}-${temporalVal}`;
            const outcome = getExcelMissingData(taxonId, spatialVal, temporalVal);

            const newRow = {
              product: "to be specified",
              isItalicProduct: true,
              resp_driver: taxonId,
              coverage: coverageCode,
              resolution: activeExcelDatabase.fixedResolution || "species-geo coordinates-ANNUAL",
              impact: "NA",
              likelihood: outcome.likelihood,
              risk: "NA",
              locked: false,
              lockedParams: true
            };

            tableRowsData.push(newRow);
            renderTable();

            setTimeout(() => {
              const rows = tableBody.querySelectorAll('tr');
              if (rows.length > 0) {
                rows[rows.length - 1].scrollIntoView({ behavior: 'smooth', block: 'nearest' });
              }
            }, 50);
          });

          // CSV Export
          document.getElementById('btnExportCsv').addEventListener('click', () => {
            if (tableRowsData.length === 0) {
              alert('Table is empty. Add or load data before exporting.');
              return;
            }
            const headers = ['PRODUCT', 'RESPONSE VAR', 'COVERAGE', 'RESOLUTION', 'impact', 'likelihood', 'risk'];
            const csvLines = [headers.join(',')];

            tableRowsData.forEach(r => {
              const risk = computeRisk(r.impact, r.likelihood).rating;
              const row = [
                `"${(r.product || '').replace(/"/g, '""')}"`,
                `"${(r.resp_driver || '').replace(/"/g, '""')}"`,
                `"${(r.coverage || '').replace(/"/g, '""')}"`,
                `"${(r.resolution || '').replace(/"/g, '""')}"`,
                `"${r.impact || 'NA'}"`,
                `"${r.likelihood || ''}"`,
                `"${risk}"`
              ];
              csvLines.push(row.join(','));
            });

            const csvBlob = new Blob([csvLines.join('\r\n')], { type: 'text/csv;charset=utf-8;' });
            const url = URL.createObjectURL(csvBlob);
            const a = document.createElement('a');
            a.href = url;
            a.download = `DTO_BioFlow_Impact_Assessment_${new Date().toISOString().slice(0, 10)}.csv`;
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            URL.revokeObjectURL(url);
          });

          // Initial load: Blank Assessment Template
          loadPreset('empty');
        })();
        </script>
        )---")
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
      tryCatch(
        {
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
        },
        error = function(e) {
          cat("Error parsing macrogroups.csv:", conditionMessage(e), "\n")
          NULL
        }
      )
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
      res_list <- tryCatch(
        {
          run_missing_data_pipeline(current_inputs, incProgress, log_callback, session)
        },
        error = function(e) {
          err_msg <- conditionMessage(e)
          log_callback(paste("Pipeline execution interrupted:", err_msg))
          stopApp()
          return(NULL)
        }
      )

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
      macro <- isolate(active_macrogroup())
      taxa_folder_name <- if (!is.null(macro) && macro != "") {
        macro
      } else {
        species_vec <- trimws(strsplit(input$species, ",")[[1]])
        paste(species_vec, collapse = "_")
      }
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
        backgroundColor = styleInterval(
          c(-0.60, -0.30, -1e-9, 1e-9, 0.30, 0.60),
          c("#c3e6cb", "#d4edda", "#e6f4ea", "#ffffff", "#fff3cd", "#ffd8be", "#fcd5d9")
        ),
        color = styleInterval(
          c(-0.60, -0.30, -1e-9, 1e-9, 0.30, 0.60),
          c("black", "black", "black", "transparent", "black", "black", "black")
        )
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
        selected = "geom_shape"
      )
    } else {
      updateSelectInput(session, "spat_res",
        choices = c("geographical coordinates" = "geom_point", "shape/grid" = "geom_shape"),
        selected = "geom_point"
      )
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
