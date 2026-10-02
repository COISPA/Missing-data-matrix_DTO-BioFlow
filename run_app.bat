@echo off
title DTO-BioFlow Skills-Matrix Launcher
echo =======================================================
echo   Launching DTO-BioFlow Skills-Matrix Shiny Application  
echo =======================================================
echo.
echo Checking for R environment...

set "RSCRIPT=Rscript"
where Rscript >nul 2>nul
if %errorlevel% neq 0 (
    echo Rscript not found on system PATH. Searching C:\Program Files\R...
    set "FOUND_R="
    for /d %%d in ("C:\Program Files\R\R-*") do (
        if exist "%%d\bin\Rscript.exe" (
            set "RSCRIPT=%%d\bin\Rscript.exe"
            set "FOUND_R=1"
        )
    )
    if not defined FOUND_R (
        echo [ERROR] Rscript was not found on PATH or in C:\Program Files\R.
        echo.
        echo Please make sure R is installed:
        echo 1. Download and install R from: https://cran.r-project.org/
        echo 2. If R is installed, add its 'bin' directory to your Windows System PATH.
        echo.
        pause
        exit /b 1
    )
)

echo Found R at: "%RSCRIPT%"
echo Starting Shiny app in local browser...
"%RSCRIPT%" -e "shiny::runApp('.', launch.browser = TRUE)"
if %errorlevel% equ 0 exit /b 0

echo.
echo [ERROR] Failed to launch the application.
echo Ensure the required R packages are installed by running:
echo install.packages(c('shiny', 'bslib', 'emodnet.wfs', 'tidyverse', 'sf', 'terra', 'openxlsx2', 'DT', 'plotly', 'lubridate', 'base64enc'))
echo.
pause

