@echo off
pushd "%~dp0"

REM Ustaw nazwy plików
if "%BUILD_TYPE%"=="debug" (
    set OLD_NAME=app-debug.apk
    set NEW_NAME=HTTP_Request_Generator_DEBUG.apk
) else (
    set OLD_NAME=app-release.apk
    set NEW_NAME=HTTP_Request_Generator_RELEASE.apk
)

REM Zmień nazwę pliku
echo [4/4] Renaming APK file...
if exist "build\app\outputs\flutter-apk\%OLD_NAME%" (
    REM Usuń istniejący plik o nowej nazwie jeśli istnieje
    if exist "build\app\outputs\flutter-apk\%NEW_NAME%" (
        del "build\app\outputs\flutter-apk\%NEW_NAME%"
        echo Removed existing file: %NEW_NAME%
    )
    ren "build\app\outputs\flutter-apk\%OLD_NAME%" "%NEW_NAME%"
    echo.
    echo ========================================
    echo SUCCESS! APK built and renamed!
    echo ========================================
    echo Old name: %OLD_NAME%
    echo New name: %NEW_NAME%
    echo Location: build\app\outputs\flutter-apk\
    echo Full path: %CD%\build\app\outputs\flutter-apk\%NEW_NAME%
    echo ========================================
) else (
    echo ERROR: APK file not found at expected location!
    echo Looking for: build\app\outputs\flutter-apk\%OLD_NAME%
    goto :error
)


popd