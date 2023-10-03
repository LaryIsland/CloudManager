@echo Off

:: Cloud Manager v1
:: Thanks for downloading my cloud manager!
:: Updates can be downloaded through the main menu, or found at https://github.com/repos/LaryIsland/CloudManager/releases/latest
:: If you find any bugs or want to suggest new features, please feel to submit them using either the main menu option
:: or by navigating to https://github.com/LaryIsland/CloudManager/issues

title LaryIsland's Cloud Manager

:MainMenu
	call :MainTitle
	echo What would you like to do?
	echo.
	echo 1 - Cloud Manager
	echo 2 - Check for updates
	echo 3 - Submit bug or feature request
	echo 4 - Quit
	echo.
	set /p mainMenuSelect=Please enter your selection: 
	2>nul goto :Case_Main_%mainMenuSelect%
	if errorlevel 1 goto :Case_Main_Default



:Case_Main_Default
	call :MainTitle
	echo Invalid Selection. Press any key to continue.
	pause >nul
	goto :MainMenu



:Case_Main_1
	goto :Entries



:Case_Main_2
	set currVersion=1
	call :MainTitle
	echo Checking internet connection status...
	::Get response from pinging www.google.com
	for /F %%G In ('curl -s -o NUL "www.google.com" -w "%%{http_code}\n"') do set "response=%%G"

	echo.
	if %response% == 200 (
		echo Internet connection confirmed.
		echo.
	) else (
		echo Unable to connect, please try again later.
		call :PauseReturnToMenu
		goto :MainMenu
	)
	::Gets latest release download link from github
	for /f "tokens=1,* delims=:" %%A in ('curl -ks https://api.github.com/repos/LaryIsland/CloudManager/releases/latest ^| find "browser_download_url"') do (
		set githubLatest=%%B
	)

	if ["%githubLatest%"]==[""] (
		echo Unable to fetch update status
		call :PauseReturnToMenu
		goto :MainMenu
	)
	::Gets version number of latest release
	set githubLatest=%githubLatest: =%
	setlocal EnableDelayedExpansion
	set "keep=0123456789"
	set "githubLatestVersion="
	for /F "delims=" %%a in ('cmd /U /C set /P "=!githubLatest!" ^<NUL ^| find /V ""') do (
	   if "%%a" neq "^!" if "%%a" neq "=" if "%%a" neq "*" (
		  if "!keep:%%a=!" neq "%keep%" (
			 set "githubLatestVersion=!githubLatestVersion!%%a"
		  )
	   )
	)
	endlocal & set githubLatestVersion=%githubLatestVersion%

	if %githubLatestVersion% GTR %currVersion% (
		echo Update found!
		echo.
		echo Current version: v%currVersion%	Latest verion: v%githubLatestVersion%
		echo.
		goto :AskDownload
	)
	if %githubLatestVersion%==%currVersion% (
		echo You are currently using the latest version.
		call :PauseReturnToMenu
		goto :MainMenu
	)
	if %githubLatestVersion% LSS %currVersion% (
		echo Are you living in the future?
		echo You've got a more recent version than I've got!
		echo.
		echo Current version: v%currVersion%	"Latest" verion: v%githubLatestVersion%
		echo.
		goto :AskDownload
	)
	
	:AskDownload
		set errorlevel=0
		choice /M "Would you like to download the update"
		echo.
		if errorlevel==2 (
			echo Not downloading update.
			call :PauseReturnToMenu
			goto :MainMenu
		)
		echo Downloading update...
		curl -kL %githubLatest% -o "LaryIslandCloudManager.download"
		echo.
		echo Updating please wait...
		echo @echo off>"LCMUpdater.bat"
		echo del "LaryIslandCloudManager.bat">>"LCMUpdater.bat"
		echo ren "LaryIslandCloudManager.download" "LaryIslandCloudManager.bat">>"LCMUpdater.bat"
		echo goto 2^>nul ^& del ^"%%~f0^" ^& LaryIslandCloudManager.bat>>"LCMUpdater.bat"
		LCMUpdater.bat



:Case_Main_3
	start "" https://github.com/LaryIsland/CloudManager/issues/new/choose
	goto :MainMenu



:Case_Main_4
	goto :Exit










:Entries
	if [%cloudfolder%]==[] (
		goto :EntriesFolder
	)
	if ["%currentry%"]==[""] (
		goto :ManageEntries
	)
	call :MainTitle
	echo Selected cloud folder: %cloudfolder%
	echo Selected local folder: %currEntryPath%
	echo Selected cloud managed entry: %currEntryName%
	echo.
	echo.
	echo What would you like to do?
	echo.
	echo 1 - Copy my current files to the cloud
	echo 2 - Symlink local files to cloud files
	echo 3 - Revert to using local files and copy then delete cloud files
	echo 4 - Change selected entry
	echo 5 - Change cloud folder location
	echo 6 - Main Menu
	echo 7 - Quit
	echo.
	set /p entriesSelect=Please enter your selection: 
	2>nul goto :Case_Entries_%entriesSelect%
	if errorlevel 1 goto :Case_Entries_Default



:Case_Entries_Default
	call :MainTitle
	echo Invalid Selection. Press any key to continue.
	pause >nul
	goto :Entries



:Case_Entries_1
	echo.
	echo.
	set errorlevel=0
	if exist "%cloudfolder:~1,-1%\%currentry%\" (
		echo Warning! A %currentry% folder is already on the cloud. If you continue,
		choice /M "your files will be replaced with the local ones on this system. Continue"
		echo.
		if errorlevel==2 ( goto :Entries )
	)
	@xcopy /E /I /Y %currEntryPath% "%cloudfolder:~1,-1%\%currentry%\"
	call :PauseContinue
	goto :Entries



:Case_Entries_2
	echo.
	echo.
	set errorlevel=0
	choice /M "Warning! This will delete your local files! Are you sure"
	if errorlevel==2 goto :Entries
	if not exist "%cloudfolder:~1,-1%\%currentry%\" (
		echo.
		echo Error, this entries cloud folder does not exist or has been renamed.
		echo Operation cancelled.
		call :PauseReturnToMenu
		goto :Entries
	) else (
		@rmdir /S /Q %currEntryPath% >nul
		@mklink /J %currEntryPath% "%cloudfolder:~1,-1%\%currentry%\"
		call :PauseContinue
		goto :Entries
	)



:Case_Entries_3
	echo.
	echo.
	if not exist "%cloudfolder:~1,-1%\%currentry%\" (
		echo Error, this entries cloud folder does not exist or has been renamed.
		echo Operation cancelled.
		call :PauseReturnToMenu
		goto :Entries
	)
	@rmdir /S /Q %currEntryPath%
	@xcopy /E /I "%cloudfolder:~1,-1%\%currentry%\*.*" %currEntryPath%
	@rmdir /S /Q "%cloudfolder:~1,-1%\%currentry%\"
	call :PauseContinue
	goto :Entries



:Case_Entries_4
	goto :ManageEntries



:Case_Entries_5
	goto :EntriesFolder



:Case_Entries_6
	goto :MainMenu



:Case_Entries_7
	goto :Exit





:ManageEntries
	call :MainTitle
	echo What would you like to manage?
	echo.
	echo 1 - Add Entry
	echo 2 - Remove Entry
	echo 3 - Rearrange
	call :DisplayEntries
	echo.
	set /p manageEntriesSelect=Please enter your selection: 
	if 1%manageEntriesSelect% NEQ +1%manageEntriesSelect% ( goto :ManageEntries_Invalid )
	if %manageEntriesSelect%==1 (
		set currEntryPath=
		goto :ManageEntries_AddNew )
	if %manageEntriesSelect%==2 ( goto :ManageEntries_Remove )
	if %manageEntriesSelect%==3 (
		set tempManageEntriesRearrangeSelect=""
		goto :ManageEntries_Rearrange
	)
	for /F "usebackq skip=%manageEntriesSelect% tokens=1,2 delims=," %%i in ("%lookupFile%") do (
		set currEntryName=%%i
		set currEntryPath=%%j
		call :GetEntry
		goto :Entries
	)



:ManageEntries_Invalid
	call :MainTitle
	echo Invalid Selection. Press any key to continue.
	pause >nul
	goto :ManageEntries

	

:ManageEntries_AddNew
	echo.
	echo.
	echo Please select a local folder in the following pop-up window.
	call :PauseSelectFolder

	set "psCommand="(new-object -COM 'Shell.Application')^.BrowseForFolder(0,'Please choose a local folder:',0,0).self.path""

	for /f "usebackq delims=" %%I in (`powershell %psCommand%`) do set "currEntryPath="%%I""
	if [%currEntryPath%]==[] (
		echo.
		echo Error, you did not select a folder.
		echo Operation cancelled.
		call :PauseReturnToMenu
		goto :ManageEntries
	)
	echo.
	call :GetEntry
	
	set errorlevel=0
	findstr /c:%currEntryPath% "%lookupFile%" >nul 2>&1
	if not errorlevel 1 (
		echo Error, cloud directory: %currEntryPath%
		echo is already being used for another entry.
		echo Operation cancelled.
		call :PauseReturnToMenu
		goto :ManageEntries
	)
	
	set /p currEntryName=Please enter your entries name: 
	echo.
	
	set errorlevel=0
	findstr /r /c:"%currEntryName%," "%lookupFile%" >nul 2>&1
	if not errorlevel 1 (
		echo Error, there is already an entry named %currEntryName%.
		echo Operation cancelled.
		call :PauseReturnToMenu
		goto :ManageEntries
	)

	@copy "%lookupFile%" "%lookupFile%.tmp" >nul
	echo %currEntryName%,%currEntryPath%>> "%lookupFile%.tmp"
	findstr /v "^$" "%lookupFile%.tmp" > "%lookupFile%"
	del "%lookupFile%.tmp"
	echo.
	echo Entry successfully added.
	call :PauseReturnToMenu
	goto :ManageEntries



:ManageEntries_Remove
	call :MainTitle
	echo Which entry would you like to remove?
	echo.
	echo 1 - Finish removing
	call :DisplayEntries
	echo.
	echo.
	set /p manageEntriesRemoveSelect=Please enter your selection: 
	echo.
	echo.
	if 1%manageEntriesRemoveSelect% NEQ +1%manageEntriesRemoveSelect% ( goto :ManageEntries_Invalid )
	if %manageEntriesRemoveSelect%==1 ( goto :ManageEntries )
	if %manageEntriesRemoveSelect%==2 ( goto :ManageEntries_Invalid )
	if %manageEntriesRemoveSelect%==3 ( goto :ManageEntries_Invalid )
	
	for /F "usebackq skip=%manageEntriesRemoveSelect% tokens=1,2 delims=," %%i in ("%lookupFile%") do (
		set currEntryName=%%i
		set currEntryPath=%%j
		call :GetEntry
		goto :ManageEntries_Remove_ExistsCheck
	)
	
	goto :ManageEntries_Invalid
	
	:ManageEntries_Remove_ExistsCheck
	if exist "%cloudfolder:~1,-1%\%currentry%\" (
		echo Error, cloud folder for %currEntryName%, still exists.
		echo Please remove it in the management menu first.
		echo Operation cancelled.
		call :PauseReturnToMenu
		goto :Entries
	)
	
	set errorlevel=0
	choice /M "Are you sure you want to remove %currEntryName%"
	if errorlevel==2 ( goto :ManageEntries_Remove )

	findstr /v /r /c:"%currEntryName%," "%lookupFile%" > "%lookupFile%.tmp"
	findstr /v "^$" "%lookupFile%.tmp" > "%lookupFile%"
	@del "%lookupFile%.tmp"
	set currentry=
	goto :ManageEntries_Remove



:ManageEntries_Rearrange
	call :MainTitle
	echo Which two entries would you like to swap?
	echo.
	echo 1 - Finish rearranging

	set /a count = 4
	setlocal enabledelayedexpansion
	for /F "usebackq skip=4 tokens=1 delims=," %%i in ("%lookupFile%") do (
		if !count!==%tempManageEntriesRearrangeSelect% (
			echo !count! - ^*%%i^*
		) else (
			echo !count! - %%i
		)
		set /a count += 1
	)
	endlocal
	echo.
	echo.
	set /p manageEntriesRearrangeSelect=Please enter your selection: 
	echo.
	echo.
	if 1%manageEntriesRearrangeSelect% NEQ +1%manageEntriesRearrangeSelect% ( goto :ManageEntries_Invalid )
	if %manageEntriesRearrangeSelect%==1 ( goto :ManageEntries )
	if %manageEntriesRearrangeSelect%==2 ( goto :ManageEntries_Invalid )
	if %manageEntriesRearrangeSelect%==3 ( goto :ManageEntries_Invalid )
	
	for /F "usebackq skip=%manageEntriesRearrangeSelect% tokens=1,2 delims=," %%i in ("%lookupFile%") do (
		if %tempManageEntriesRearrangeSelect%=="" (
			set tempManageEntriesRearrangeSelect=%manageEntriesRearrangeSelect%
			set writelinenuma=%manageEntriesRearrangeSelect%
			set writelinetxta=%%i,%%j
			echo %manageEntriesRearrangeSelect% %%i %%j 
			goto :ManageEntries_Rearrange
		) else (
			set writelinenuma=%manageEntriesRearrangeSelect%
			set writelinenumb=%tempManageEntriesRearrangeSelect%
			set writelinetxtb=%%i,%%j
			echo %manageEntriesRearrangeSelect% %tempManageEntriesRearrangeSelect% %%i %%j 
			call :WriteLine
			set tempManageEntriesRearrangeSelect=""
			goto :ManageEntries_Rearrange
		)
	)




:EntriesFolder
	echo.
	echo.
	echo Please select your cloud folder in the following pop-up window.
	call :PauseSelectFolder

	set "psCommand="(new-object -COM 'Shell.Application')^.BrowseForFolder(0,'Please choose your cloud folder:',0,0).self.path""

	for /f "usebackq delims=" %%I in (`powershell %psCommand%`) do set "cloudfolder="%%I""
	if [%cloudfolder%]==[] (
		echo.
		echo Error, you did not select a folder.
		goto :EntriesFolder
	)

	echo.
	call echo You chose %cloudfolder%
	set errorlevel=0
	choice /M "Is this correct"

	if errorlevel==2 ( goto :EntriesFolder )
	
	set lookupFile=%cloudfolder:~1,-1%\LCMLookup.txt
	
	if exist "%lookupFile%" (
		goto :Entries
	)
	echo version=^1	DO NOT REMOVE THE FIRST FOUR LINES> "%lookupFile%"
	echo This file contains a lookup table for the entries used by LaryIsland's Cloud Save Manager, if you want to manually edit the table>> "%lookupFile%"
	echo please note it is in the format of: [ENTRY NAME],[ABSOLUTE PATH TO ENTRY] there must *NOT* be any spaces directly after or before the comma>> "%lookupFile%"
	echo ----------------------------------------------------------CLOUD ENTRY DATA BELOW---------------------------------------------------------->> "%lookupFile%"
	goto :Entries


::Writes to specific file lines denoted by variables:
::writelinenum[a/b] - the line number
::writelinetxt[a/b] - the text to write
:WriteLine
	if %writelinenuma%==%writelinenumb% ( goto :EOF )

	setlocal enableextensions enabledelayedexpansion

	@copy /y nul "%lookupFile%.writing.tmp" >nul

	set /a line=0

	for /f "usebackq delims=" %%l in ("%lookupFile%") do (
		if !line!==%writelinenuma% (
			echo %writelinetxta%>>"%lookupFile%.writing.tmp"
		) else (
			if !line!==%writelinenumb% (
				echo %writelinetxtb%>>"%lookupFile%.writing.tmp"
			) else (
				echo %%l>>"%lookupFile%.writing.tmp"
			)
		)
		set /a line+=1
	)

	del "%lookupFile%"
	ren "%lookupFile%.writing.tmp" "LCMLookup.txt"

	endlocal
	goto :EOF



:Exit
	exit 0



:GetEntry
	set /A loopCounter=0
	set loopVar=%currEntryPath:~1,-1%
:TokensCounter
	for /F "tokens=1* delims=\" %%A in ( "%loopVar%" ) do (
		set /A loopCounter+=1
		set loopVar=%%B
		goto :TokensCounter
	)
	for /f "tokens=%loopCounter% delims=\" %%i in ( "%currEntryPath:~1,-1%" ) do set currentry=%%i
	exit /b 0
	goto :EOF



:MainTitle
	cls
	echo.
	echo ------------------------------------
	echo    Cloud Manager v1 by LaryIsland
	echo ------------------------------------
	echo.
	echo.
	goto :EOF



:PauseReturnToMenu
	echo.
	echo Press any key to return to the menu.
	pause >nul
	goto :EOF



:PauseContinue
	echo.
	echo Done. Press any key to continue.
	pause >nul
	goto :EOF



:PauseSelectFolder
	echo.
	echo Press any key to open the selection window.
	pause >nul
	echo.
	echo Please wait...
	goto :EOF



:DisplayEntries
	set /a count = 4
	setlocal enabledelayedexpansion
	for /F "usebackq skip=4 tokens=1 delims=," %%i in ("%lookupFile%") do (
		echo !count! - %%i
		set /a count += 1
	)
	endlocal
	goto :EOF