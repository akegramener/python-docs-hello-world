@if "%SCM_TRACE_LEVEL%" NEQ "4" @echo off

:: This shell script heavily inspired by Ilia Karmanov's example:
:: https://github.com/ilkarman/Azure-WebApp-w-CNTK
::
:: Feel free to use newer wheels of your own if you like.

SET NUMPY_WHEEL=https://pypi.python.org/packages/3b/98/e5594863d96cf79bb89bb4f49191403136c08b8353c3e3ebcb17cc6554e3/numpy-1.14.1-cp27-none-win_amd64.whl
SET SCIPY_WHEEL=https://pypi.python.org/packages/c4/c3/6e9269467fb1e69f094b3a404caf3e672cc31d7f557c8214342ed17d9b5b/scipy-1.0.0-cp27-none-win_amd64.whl#md5=495f131550a2845945e5228ff0eb4cf2
SET CNTK_WHEEL=https://cntk.ai/PythonWheel/CPU-Only/cntk-2.3.1-cp34-cp34m-win_amd64.whl

:: ----------------------
:: KUDU Deployment Script
:: Version: 1.0.14
:: ----------------------

:: Prerequisites
:: -------------

:: Verify node.js installed
where node 2>nul >nul
IF %ERRORLEVEL% NEQ 0 (
  echo Missing node.js executable, please install node.js, if already installed make sure it can be reached from current environment.
  goto error
)

:: Setup
:: -----

setlocal enabledelayedexpansion

SET ARTIFACTS=%~dp0%..\artifacts

IF NOT DEFINED DEPLOYMENT_SOURCE (
  SET DEPLOYMENT_SOURCE=%~dp0%.
)

IF NOT DEFINED DEPLOYMENT_TARGET (
  SET DEPLOYMENT_TARGET=%ARTIFACTS%\wwwroot
)

IF NOT DEFINED NEXT_MANIFEST_PATH (
  SET NEXT_MANIFEST_PATH=%ARTIFACTS%\manifest

  IF NOT DEFINED PREVIOUS_MANIFEST_PATH (
    SET PREVIOUS_MANIFEST_PATH=%ARTIFACTS%\manifest
  )
)

IF NOT DEFINED KUDU_SYNC_CMD (
  :: Install kudu sync
  echo Installing Kudu Sync
  call npm install kudusync -g --silent
  IF !ERRORLEVEL! NEQ 0 goto error

  :: Locally just running "kuduSync" would also work
  SET KUDU_SYNC_CMD=%appdata%\npm\kuduSync.cmd
)

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Deployment
:: ----------

echo Handling Basic Web Site deployment.

:: 1. KuduSync
IF /I "%IN_PLACE_DEPLOYMENT%" NEQ "1" (
  call :ExecuteCmd "%KUDU_SYNC_CMD%" -v 50 -f "%DEPLOYMENT_SOURCE%" -t "%DEPLOYMENT_TARGET%" -n "%NEXT_MANIFEST_PATH%" -p "%PREVIOUS_MANIFEST_PATH%" -i ".git;.hg;.deployment;deploy.cmd"
  IF !ERRORLEVEL! NEQ 0 goto error
)

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
goto end

:: Execute command routine that will echo out when error
:ExecuteCmd
setlocal
set _CMD_=%*
call %_CMD_%
if "%ERRORLEVEL%" NEQ "0" echo Failed exitCode=%ERRORLEVEL%, command=%_CMD_%
exit /b %ERRORLEVEL%

:error
endlocal
echo An error has occurred during web site deployment.
call :exitSetErrorLevel
call :exitFromFunction 2>nul

:exitSetErrorLevel
exit /b 1

:exitFromFunction
()

:end
endlocal

echo Installing Python 3.5 wheels (hope you installed the Python 3.5.4 extension!)
D:\home\python354x64\python.exe -m pip install --upgrade %NUMPY_WHEEL%
D:\home\python354x64\python.exe -m pip install --upgrade %SCIPY_WHEEL%
D:\home\python354x64\python.exe -m pip install --upgrade %CNTK_WHEEL%
D:\home\python354x64\python.exe -m pip install --upgrade pillow
D:\home\python354x64\python.exe -m pip install --upgrade flask

echo Finished running custom deploy command successfully.
