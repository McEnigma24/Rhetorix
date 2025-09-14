@echo off
pushd "%~dp0"

@REM REM Sprawdzenie, czy przekazano przynajmniej jeden argument
if "%~1"=="" (
    set "MSG=quick"
) else (
    set "MSG=%*"
)

echo Commit message: "%MSG%"
git add .
git commit -m "%MSG%"
git push
@REM git push origin --force

popd
