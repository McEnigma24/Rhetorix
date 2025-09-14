@echo off
pushd "%~dp0"

echo ========================================
echo Building HTTP Request Generator APK...
echo ========================================

REM Sprawdź czy podano typ build (debug/release)
if "%1"=="" (
    set BUILD_TYPE=debug
) else (
    set BUILD_TYPE=release
)
flutter build apk --%BUILD_TYPE%

popd