@echo off
set PYTHON_PATH=%~dp0WPy64-310111\python-3.10.11.amd64\python.exe >> simonmesh.bat
set SCRIPT_PATH=%~dp0master.py >> simonmesh.bat
echo @echo off > simonmesh.bat
echo set PYTHON_PATH=%~dp0WPy64-310111\python-3.10.11.amd64\python.exe >> simonmesh.bat
echo set SCRIPT_PATH=%~dp0master.py >> simonmesh.bat
echo %PYTHON_PATH% %SCRIPT_PATH% >> simonmesh.bat
echo pause >> simonmesh.bat

echo %PYTHON_PATH% > .configure

set PATH=%PATH%;%~dp0WPy64-310111\python-3.10.11.amd64;%~dp0WPy64-310111\python-3.10.11.amd64\Scripts

@echo off
if exist %~dp0WPy64-310111 (
   rmdir /s /q %~dp0WPy64-310111
)
echo Folder removed or did not exist.
pause 

setlocal

:: Check if Docker is installed
echo Checking if Docker is installed...
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Docker is not installed. Redirecting to Docker installation page...
    start https://www.docker.com/products/docker-desktop/
    echo Please install Docker Desktop and re-run this script.
    pause
    exit /b
)

:: Check if Docker is running
echo Checking if Docker is running...
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo Docker is not running. Attempting to start Docker Desktop...
    start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    echo Waiting for Docker to start...
    timeout /t 30 >nul

    :: Check again if Docker started
    docker info >nul 2>&1
    if %errorlevel% neq 0 (
        echo Docker failed to start. Please start it manually and re-run this script.
        pause
        exit /b
    )
)

:: Pull the Docker image
echo Docker is installed. Pulling the image "simonmesh/meshos:2406"...
docker pull simonmesh/meshos:2406
if %errorlevel% neq 0 (
    echo Failed to pull the Docker image. Please check your internet connection or the image name.
    pause
    exit /b
)


:: Use PowerShell to create a directory selection dialog
:: for /f "usebackq delims=" %%i in (`powershell -Command "& {(New-Object -ComObject Shell.Application).BrowseForFolder(0, 'Select a folder', 0, 0).self.Path}"`) do set "selectedFolder=%%i"
for /f "usebackq delims=" %%i in (`powershell -Command "& {(New-Object -ComObject Shell.Application).BrowseForFolder(0, 'Select a folder', 0, '%%USERPROFILE%%').self.Path}"`) do set "selectedFolder=%%i"

:: Check if a folder was selected
if defined selectedFolder (
    echo You selected: %selectedFolder%
	echo %selectedFolder% >> .configure
    pause
) else (
    echo No folder was selected.
    pause
)

:: Check if a folder was selected
if "%selectedFolder%"=="" (
    echo No folder selected. Exiting.
    exit /b 1
)

:: Print the selected folder
echo Selected folder: %selectedFolder%

:: Run Docker with the selected folder
:: docker run -it --name meshos -v "%selectedFolder%:/OpenFOAM" simonmesh/meshos:2406 /bin/bash
docker run -d --name meshos -v "%selectedFolder%:/OpenFOAM" simonmesh/meshos:2406 /bin/bash -c "tail -f /dev/null"

if %errorlevel% neq 0 (
    echo Failed to run the container. Please check Docker logs for details.
    pause
)

echo The container "meshos" is now running.
pause


@echo off
:: Variables
set "url=https://github.com/winpython/winpython/releases/download/6.1.20230527/Winpython64-3.10.11.1dot.exe"
set "installer=Winpython64-3.10.11.1dot.exe"
set "download_dir=%~dp0"
set "install_dir=%~dp0\WinPython"
set "python_dir=%~dp0\WPy64-310111\python-3.10.11.amd64"
set "python_exe=%~dp0\WPy64-310111\python-3.10.11.amd64\python.exe"
echo %download_dir%
echo %python_dir%
echo %python_exe%
:: Download the installer
echo Downloading WinPython installer...
powershell -Command "(New-Object System.Net.WebClient).DownloadFile('%url%', '%download_dir%\%installer%')"
if errorlevel 1 (
    echo Failed to download the installer.
    pause
    exit /b 1
)

:: Run the installer
echo Running the installer...
start /wait "" "%download_dir%\%installer%" /VERYSILENT /DIR="%install_dir%"
if errorlevel 1 (
    echo Installation failed.
    pause
    exit /b 1
)

:: Prompt user to choose python.exe, default to the specific subdirectory
:: echo Please choose the python.exe file for the installed WinPython.
:: powershell -Command "[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null; $fileDialog = New-Object System.Windows.Forms.OpenFileDialog; $fileDialog.Filter = 'Python Executable (python.exe)|python.exe'; $fileDialog.InitialDirectory = '%python_dir%'; if($fileDialog.ShowDialog() -eq 'OK') { $fileDialog.FileName } else { exit 1 }" > .configure
::if errorlevel 1 (
::    echo Python executable selection cancelled.
::    pause
::    exit /b 1
::)
set /p python_exe=<.configure
:: echo %python_exe% > .configure

:: Verify python.exe
if not exist "%python_exe%" (
    echo Python executable not found.
    pause
    exit /b 1
)

:: Install numpy and matplotlib
echo Installing numpy and matplotlib...
:: "%python_exe%" -m pip install --upgrade pip
"%python_exe%" -m pip install numpy matplotlib pystray pygetwindow pillow websockets asyncio
if errorlevel 1 (
    echo Failed to install required Python packages.
    pause
    exit /b 1
)

:: Clean up
echo Cleaning up...
del "%download_dir%\%installer%"

echo Installation and setup completed successfully.
pause


:: Set the target batch file, shortcut path, and icon path (relative paths)
set TARGET_BAT=%~dp0simonmesh.bat
set SHORTCUT_PATH=%~dp0simonmesh.lnk
set ICON_PATH=%~dp0newLogo.ico

:: Use PowerShell to create the shortcut with an icon
powershell -NoProfile -Command ^
    "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%SHORTCUT_PATH%'); $s.TargetPath = '%TARGET_BAT%'; $s.IconLocation = '%ICON_PATH%'; $s.Save();"

echo Shortcut created at "%SHORTCUT_PATH%" with icon "%ICON_PATH%"


:: Create a desktop shortcut path
set DESKTOP_SHORTCUT=%USERPROFILE%\Desktop\simonmesh.lnk

:: Use PowerShell to create the shortcut with an icon on the desktop
powershell -NoProfile -Command ^
    "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%DESKTOP_SHORTCUT%'); $s.TargetPath = '%TARGET_BAT%'; $s.IconLocation = '%ICON_PATH%'; $s.Save();"

echo Shortcuts created at "%SHORTCUT_PATH%" and on the Desktop ("%DESKTOP_SHORTCUT%") with icon "%ICON_PATH%"
pause