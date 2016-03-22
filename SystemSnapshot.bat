@echo off
SetLocal EnableExtensions EnableDelayedExpansion


echo                 SystemSnapshot v0.3
echo IT Forensics and System incident response tool. 
echo Mariusz B. / MGeeky, 2011-2014
echo.

REM This script collects information about system from different
REM locations. It gathers:
REM 0a. Full memory dump
REM 0b. Preliminary system informations gathering
REM 1.  Dump of registry Keys (Exports)
REM 2.  Tree view of SS_PATHs
REM 3.  DIR view of SS_PATHs
REM 4.  Whole list of running (and not) services
REM 5.  Whole list of running (and not) drivers
REM 6.  List of running/loaded/unloaded DLLs
REM 7.  Current PROCESS List (from 3 different collectors):
REM 	 * system tasklist
REM 	 * Sysinternals PSLIST
REM  	 * and any extra source
REM 8.  MD5 sums of each file in SS_PATHs
REM 9.  Dump of actual machine memory (win32dd)
REM 10. Dump of actual kernel memory (Crash Dump)
REM 11. Complete log from netstat
REM 12. DNS Cache list (ipconfig /flushdns )
REM 13. ARP Routing Table
REM 14. List of every spotted Alternate Data Stream in SS_PATHs
REM 15. Simple autorun values list (simple view format)
REM 16. Copy of Master Boot Record
REM 17. Whole system registered Handles list
REM x 18. Every drive NTFS info
REM 19. Open ports list (through TCPVcon.exe)
REM 20. Current logged in users list
REM 21. Simple copy of hosts file
REM 22. Possible FIREWALL filters (netsh)
REM 23. Complete SYSTEMINFO log
REM 24. XueTr/PCHunter logs gathering
REM 25. Sigcheck recursive files scanning
REM
REM Then script will move all gathered log files into one folder
REM and pack this folder (zip or something) and compare MD5 checksums



REM ===================  G L O B A L  V A R S  ===================
REM 
REM This section is modifiable.


REM SystemSnapshot paths to scan while collecting files lists
set SS_PATH1=%SystemRoot%
set SS_PATH2=%UserProfile%
set SS_PATH3=%ProgramFiles%

REM Directories where neccessery tools are placed
set TOOLSDIR=.\tools


REM ===================  S C R I P T  V A R S  ===================
REM
REM Below this line do not modify anything.

REM SystemSnapshot paths counter
set LOGDIR=Logs_%COMPUTERNAME%_%DATE%_%RANDOM%
set PERFORM_ALL=0

:: Setting processor architecture
set ARCH=86

for /f "tokens=3,* delims= " %%i in ('reg query "HKLM\System\CurrentControlSet\Control\Session Manager\Environment" /v PROCESSOR_ARCHITECTURE') do set ARCH=%%i

if "%ARCH%" == "x86" (
    set ARCH=86
    echo x86 Architecture.
) else (
    set ARCH=64
    echo x64 Architecture.
)

set xuetr=%TOOLSDIR%\xuetr\PCHunterCmd%ARCH%.exe

REM ==============================================================
REM
REM Code.

echo Directory to store log files: %LOGDIR%...
mkdir %LOGDIR%

REM Import SysInternals EULAs acceptance markers
reg import %TOOLSDIR%\eulas.reg

echo     Light System Examination Toolkit (LISET^) > %LOGDIR%\_INFO.txt
echo     Mariusz B. (mariusz.bit@gmail.com^), 2014 >> %LOGDIR%\_INFO.txt
echo     v0.1 >> %LOGDIR%\_INFO.txt
echo. >> %LOGDIR%\_INFO.txt
echo Scanning started at: %DATE%, %TIME% >> %LOGDIR%\_INFO.txt
echo Machine's uptime: >> %LOGDIR%\_INFO.txt
%TOOLSDIR%\uptime.exe >> %LOGDIR%\_INFO.txt
echo. >> %LOGDIR%\_INFO.txt
set >> %LOGDIR%\_INFO.txt

:PHASE0a
REM **** PHASE 0a - Full memory dump
REM
echo.
echo PHASE 0a: Full memory dump
echo.
echo.
echo ===================================
echo    WARNING: When asked - Press 'y' to dump full memory contents (huge output!), or 'n' otherwise.
echo    Afterwards, hit [ENTER]
echo ===================================
echo.
echo.
%TOOLSDIR%\DumpIt.exe

move *.raw %LOGDIR%\ 2> nul


:PHASE0b
REM **** PHASE 0b - Preliminary system's info gathering
REM
echo.
echo PHASE 0b: Preliminary system info gathering.
%TOOLSDIR%\PsInfo.exe  -h -s -d > %LOGDIR%\SystemInfo0.txt
systeminfo > %LOGDIR%\SystemInfo1.txt


:PHASE1

REM **** PHASE 1 - Registry dump
REM
echo.
echo PHASE 1: Dumping registry Hives...
echo          a) HKCU export...
reg export HKCU %LOGDIR%\HKCU_export.reg 

echo          b) HKCR export...
reg export HKCR %LOGDIR%\HKCR_export.reg

echo          c) HKLM export...
reg export HKLM %LOGDIR%\HKLM_export.reg

echo          d) HKCC export
reg export HKCC %LOGDIR%\HKCC_export.reg

echo          e) HKU export
reg export HKU %LOGDIR%\HKU_export.reg

echo   Completed.

REM if "%PERFORM_ALL%" neq "1" goto MENU


:PHASE2

REM **** PHASE 2 - Tree view dump
REM
echo.
echo PHASE 2: Collecting files tree list...
echo     notice: this step will take a little while
echo.
echo          a) %SS_PATH1%...
tree "%SS_PATH1%" /F > %LOGDIR%\TREE_1.txt

echo          b) %SS_PATH2%...
tree "%SS_PATH2%" /F > %LOGDIR%\TREE_2.txt

echo          c) %SS_PATH3%...
tree "%SS_PATH3%" /F > %LOGDIR%\TREE_3.txt

echo   Completed.

REM if "%PERFORM_ALL%" neq "1" goto MENU


:PHASE3

REM **** PHASE 3 - DIR view of SS_PATHs
REM
echo.
echo PHASE 3: Collecting DIR view of the chosen paths...
echo     notice: this step will take a while. Be patient.

echo          a) %SS_PATH1%...
dir "%SS_PATH1%" /S > %LOGDIR%\DIR_1.txt

echo          b) %SS_PATH2%...
dir "%SS_PATH2%" /S > %LOGDIR%\DIR_2.txt

echo          c) %SS_PATH3%...
dir "%SS_PATH3%" /S > %LOGDIR%\DIR_3.txt

echo   Completed.

REM if "%PERFORM_ALL%" neq "1" goto MENU


:PHASE4

REM **** PHASE 4 - Whole list of Services
REM
echo.
echo PHASE 4: Gathering list of services...
sc queryex type= service > %LOGDIR%\LIST_Services1.txt
%TOOLSDIR%\PsService.exe > %LOGDIR%\LIST_Services2.txt

echo   Completed.

REM if "%PERFORM_ALL%" neq "1" goto MENU


:PHASE5
REM **** PHASE 5 - Whole list of Drivers
REM
echo.
echo PHASE 5: Gathering list of drivers...
sc queryex type= driver > %LOGDIR%\LIST_Drivers.txt

echo   Completed.

REM if "%PERFORM_ALL%" neq "1" goto MENU


:PHASE6
REM **** PHASE 6 - List of loaded DLLs
REM
echo.
echo PHASE 6: Enumerating list of loaded DLLs...
%TOOLSDIR%\listdlls.exe > %LOGDIR%\LIST_DLLs.txt

echo   Completed.

REM if "%PERFORM_ALL%" neq "1" goto MENU


:PHASE7
REM **** PHASE 7 - Current process list...
REM
echo.
echo PHASE 7: Enumerating currently running processes list...

echo           a) TASKLIST
tasklist /FO TABLE > %LOGDIR%\LIST_Processes_TaskList1.txt
tasklist /FO TABLE /SVC > %LOGDIR%\LIST_Processes_Tasklist2.txt

echo           b) SysInternals PSLIST
%TOOLSDIR%\pslist.exe -x > %LOGDIR%\LIST_Processes_PsList_ComplexDetails.txt
%TOOLSDIR%\pslist.exe -t > %LOGDIR%\LIST_Processes_PsList_TreeView.txt

echo           c) XueTr/PCHunter ps
%xuetr% ps > %LOGDIR%\LIST_Processes_XueTr.txt

echo   Completed.

REM if "%PERFORM_ALL%" neq "1" goto MENU


:PHASE8
REM **** PHASE 8 - MD5 sums of each file in SS_PATHs
REM
echo.
echo PHASE 8: Collecting MD5 sums of every important file...
echo     notice: this step will take a little while

copy /B /Y %TOOLSDIR%\md5sum.exe "%SS_PATH1%"\
copy /B /Y %TOOLSDIR%\md5sum.exe "%SS_PATH2%"\
copy /B /Y %TOOLSDIR%\md5sum.exe "%SS_PATH3%"\

echo           a) %SS_PATH1%

pushd %SS_PATH1%
md5sum.exe -b * >> .\MD5_Sums1.txt 2> nul
md5sum.exe -b System32\* >> .\MD5_Sums1.txt 2> nul
md5sum.exe -b System32\drivers\* >> .\MD5_Sums1.txt 2> nul
md5sum.exe -b System32\drivers\etc\* >> .\MD5_Sums1.txt 2> nul
md5sum.exe -b System32\* >> .\MD5_Sums1.txt 2> nul
popd

echo           b) %SS_PATH2%

pushd %SS_PATH2%
md5sum.exe -b * >> .\MD5_Sums2.txt 2> nul
md5sum.exe -b AppData\Local\Temp\* >> .\MD5_Sums2.txt 2> nul
popd

pushd %SS_PATH3%
md5sum.exe -b * >> .\MD5_Sums3.txt 2> nul
popd

del "%SS_PATH1%\md5sum.exe"
del "%SS_PATH2%\md5sum.exe"
del "%SS_PATH3%\md5sum.exe"

move "%SS_PATH1%\MD5_Sums1.txt" %LOGDIR%\MD5_Sums1.txt
move "%SS_PATH2%\MD5_Sums2.txt" %LOGDIR%\MD5_Sums2.txt

echo   Completed.

REM if "%PERFORM_ALL%" neq "1" goto MENU

echo.
echo PHASE 9 and 10 (Memory Manager and kernel memory pool dumping) 
echo are getting skipped due to different purpose of this script.

goto :PHASE11


:PHASE9
REM **** PHASE 9 - Dump of Actual machine memory
echo.
echo PHASE 9: Dump entire Physical Memory pool
echo     Note: Press ENTER after about 180 seconds !
echo     notice: this step will take a little while

set /P t1=Do you want to perform this step (memory dump)? [y/N]:
if "%t1%"=="y" goto YES1
if "%t1%"=="Y" goto YES1

goto NO1

:YES1
pushd %TOOLSDIR%
win32dd.exe /d /a /f memory_dump.dmp > ..\%LOGDIR%\LOG_MemoryDump.txt
move memory_dump.dmp ..\%LOGDIR%\memory_dump.dmp
popd

echo   Completed.

:NO1

REM if "%PERFORM_ALL%" neq "1" goto MENU


:PHASE10
REM **** PHASE 10 - Kernel (BSOD) Memory Dump
REM
echo.
echo PHASE 10: Dump of actual Kernel Memory (BSOD)
echo     Note: Press ENTER after about 180 seconds !
echo     notice: this step will take a little while

set /P t1=Do you want to perform this step (kernel dump)? [y/N]:
if "%t1%"=="y" goto YES2
if "%t1%"=="Y" goto YES2

goto NO2

:YES2
pushd %TOOLSDIR%
win32dd.exe /k /a /f kernel_memory_dump.dmp > ..\%LOGDIR%\LOG_KernelMemDump.txt
move kernel_memory_dump.dmp ..\%LOGDIR%\kernel_memory_dump.dmp
popd

echo   Completed.

:NO2

REM if "%PERFORM_ALL%" neq "1" goto MENU


:PHASE11
REM **** PHASE 11 - Complete log from netstat
REM
echo.
echo PHASE 11: Gathering complete list of open connections from netstat
netstat -e > %LOGDIR%\LOG_NETSTAT.txt
echo ------------------------ >> %LOGDIR%\LOG_NETSTAT.txt
netstat -r >> %LOGDIR%\LOG_NETSTAT.txt
echo ------------------------ >> %LOGDIR%\LOG_NETSTAT.txt
netstat -abno >> %LOGDIR%\LOG_NETSTAT.txt


echo   Completed.

REM if "%PERFORM_ALL%" neq "1" goto MENU


:PHASE12
REM **** PHASE 12 - DNS Cache list
REM
echo.
echo PHASE 12: DNS Cache list dump
ipconfig /displaydns > %LOGDIR%\LIST_DNSCache.txt

echo   Completed.

REM if "%PERFORM_ALL%" neq "1" goto MENU


:PHASE13
REM **** PHASE 13 - ARP Routing table
REM
echo.
echo PHASE 13: ARP Routing table dump
arp -a > %LOGDIR%\LIST_ARP_RoutingTable.txt

echo   Completed.

REM if "%PERFORM_ALL%" neq "1" goto MENU


:PHASE14
REM **** PHASE 14 - Alternate Data Streams REM
echo.
echo PHASE 14: Alternate Data Streams scan...
echo     notice: this step will take a while. Please, be patient.
echo.
echo           a) %SS_PATH1%...
%TOOLSDIR%\streams.exe -s "%SS_PATH1%" > %LOGDIR%\LIST_ADS_1.txt

echo           b) %SS_PATH2%...
%TOOLSDIR%\streams.exe -s "%SS_PATH2%" > %LOGDIR%\LIST_ADS_2.txt

echo           c) %SS_PATH3%...
%TOOLSDIR%\streams.exe -s "%SS_PATH3%" > %LOGDIR%\LIST_ADS_3.txt


echo   Completed.

REM if "%PERFORM_ALL%" neq "1" goto MENU


:PHASE15
REM **** PHASE 15 - Autoruns
REM
echo.
echo PHASE 15: Collecting and briefly analysing AUTORUN values...
%TOOLSDIR%\autorunsc.exe -a dehiklt -h -m -s -u > %LOGDIR%\LIST_Autoruns0.txt
%TOOLSDIR%\autorunsc.exe -a * -h -m -s -u -v -vt > %LOGDIR%\LIST_Autoruns1.txt
echo   Completed.

REM if "%PERFORM_ALL%" neq "1" goto MENU


:PHASE16
REM **** PHASE 16 - Copy of MBR
REM
echo.
echo PHASE 16: Copying Master+Volume Boot Record (MBR/VBR) binary...

:: Get $Boot file's node number

echo           Examining file's system meta-structure...
%TOOLSDIR%\fls.exe \\.\%SYSTEMDRIVE% > %LOGDIR%\fls_SystemDrive.txt

set bootnum=0
for /f "tokens=2,3* delims= " %%i in ('more %LOGDIR%\fls_SystemDrive.txt') do (
    if "%%j" == "$Boot" for /f "tokens=1 delims=:" %%n in ('echo %%i') do (
        set bootnum=%%n
    )
)

echo           Dumping NTFS $Boot file...
%TOOLSDIR%\icat.exe \\.\%SYSTEMDRIVE% %bootnum% > %LOGDIR%\boot_file.bin

echo   Completed.

REM if "%PERFORM_ALL%" neq "1" goto MENU


:PHASE17
REM **** PHASE 17 - Whole system registered handles list
REM
echo.
echo PHASE 17: Whole system registered handles list dumping...
%TOOLSDIR%\handle -s > %LOGDIR%\LIST_Handles.txt
echo . >> %LOGDIR%\LIST_Handles.txt
%TOOLSDIR%\handle -a >> %LOGDIR%\LIST_Handles.txt

echo   Completed.

REM if "%PERFORM_ALL%" neq "1" goto MENU


:PHASE18
REM **** PHASE 18 - Every drive NTFS info
REM
echo.
echo PHASE 18: Every drive's NTFS info
echo    [!] Currently Not Available.

REM echo PHASE 18: Collecting every drive NTFS info

:PHASE19

REM **** PHASE 19: Open ports list
REM
echo.
echo PHASE 19: Open ports list

%TOOLSDIR%\Tcpvcon.exe -a > %LOGDIR%\PORTS_List.txt

echo   Completed.

REM if "%PERFORM_ALL%" neq "1" goto MENU

:PHASE20

REM **** PHASE 20: Current logged on users list
REM
echo.
echo PHASE 20: Currently Logged on users list
%TOOLSDIR%\PsLoggedon.exe > %LOGDIR%\LoggedOn_List.txt

echo   Completed.

REM if "%PERFORM_ALL%" neq "1" goto MENU


:PHASE21

REM **** PHASE 21: Simple copy of hosts file
REM
echo.
echo PHASE 21: HOSTS file.
copy %SYSTEMROOT%\System32\drivers\etc\hosts %LOGDIR%\hosts.txt

echo   Completed.

REM if "%PERFORM_ALL%" neq "1" goto MENU


:PHASE22

REM **** PHASE 22: Possible FIREWALL filters (netsh)
REM 
echo.
echo PHASE 22: Possible FIREWALL filters (netsh^)

netsh firewall show config > %LOGDIR%\netsh_firewall0.txt
netsh advfirewall firewall show rule name=all > %LOGDIR%\netsh_firewall_all.txt

REM if "%PERFORM_ALL%" neq "1" goto MENU


:PHASE23

REM **** PHASE 23: Complete SYSTEMINFO log
REM
echo.
echo PHASE 23: Complete SYSTEMINFO log
systeminfo /FO list > %LOGDIR%\SystemInfo.txt

echo   Completed.

REM if "%PERFORM_ALL%" neq "1" goto MENU


:PHASE24

echo.
echo PHASE 24: XueTr/PCHunter logs gathering

FOR /F "delims=" %%i IN (%xuetr%) DO set out=%%i
Echo."Load Driver Error" | findstr /C:"%out%">nul && (
    echo Skipping XueTr as the driver failed at loading.
) || (
    %xuetr% lkm > %LOGDIR%\xuetr_lkm.txt
    %xuetr% ssdt > %LOGDIR%\xuetr_ssdt.txt
    %xuetr% shadowssdt > %LOGDIR%\xuetr_shadowssdt.txt
    %xuetr% fsd > %LOGDIR%\xuetr_fsd.txt
    %xuetr% tcpip > %LOGDIR%\xuetr_tcpip.txt
    %xuetr% kbd > %LOGDIR%\xuetr_kbd.txt
    %xuetr% idt > %LOGDIR%\xuetr_idt.txt
    %xuetr% objecttype > %LOGDIR%\xuetr_objecttype.txt
    %xuetr% objecttype_callback > %LOGDIR%\xuetr_objecttype_callback.txt
    %xuetr% hhive > %LOGDIR%\xuetr_hhive.txt
    %xuetr% callback > %LOGDIR%\xuetr_callback.txt
    %xuetr% nr > %LOGDIR%\xuetr_nr.txt
    %xuetr% port > %LOGDIR%\xuetr_port.txt
    %xuetr% mbr > %LOGDIR%\xuetr_mbr.txt
    %xuetr% classpnp > %LOGDIR%\xuetr_classpnp.txt
    %xuetr% atapi > %LOGDIR%\xuetr_atapi.txt
    %xuetr% acpi > %LOGDIR%\xuetr_acpi.txt
    %xuetr% dpctimer > %LOGDIR%\xuetr_dpctimer.txt
    %xuetr% filter > %LOGDIR%\xuetr_filter.txt
    %xuetr% kernelhook > %LOGDIR%\xuetr_kernelhook.txt
    %xuetr% scsi > %LOGDIR%\xuetr_scsi.txt
    %xuetr% mouse > %LOGDIR%\xuetr_mouse.txt
    %xuetr% npfs > %LOGDIR%\xuetr_npfs.txt
    %xuetr% msfs > %LOGDIR%\xuetr_msfs.txt
    %xuetr% usbport > %LOGDIR%\xuetr_usbport.txt
    %xuetr% i8042prt > %LOGDIR%\xuetr_i8042prt.txt
    %xuetr% hdt > %LOGDIR%\xuetr_hdt.txt
    %xuetr% hpdt > %LOGDIR%\xuetr_hpdt.txt
    %xuetr% hadt > %LOGDIR%\xuetr_hadt.txt
    %xuetr% wdf01000 > %LOGDIR%\xuetr_wdf01000.txt
    %xuetr% wdff > %LOGDIR%\xuetr_wdff.txt
    %xuetr% fmf > %LOGDIR%\xuetr_fmf.txt
    %xuetr% fs > %LOGDIR%\xuetr_fs.txt
    %xuetr% fst > %LOGDIR%\xuetr_fst.txt
    %xuetr% cid > %LOGDIR%\xuetr_cid.txt
    %xuetr% ckdr > %LOGDIR%\xuetr_ckdr.txt
    %xuetr% cdrx > %LOGDIR%\xuetr_cdrx.txt
    %xuetr% objhij > %LOGDIR%\xuetr_objhij.txt
    %xuetr% nsiproxy > %LOGDIR%\xuetr_nsiproxy.txt
    %xuetr% tdx > %LOGDIR%\xuetr_tdx.txt
    %xuetr% ndis > %LOGDIR%\xuetr_ndis.txt
)

echo   Completed.

REM if "%PERFORM_ALL%" neq "1" goto MENU


:PHASE25

echo.
echo PHASE 25: Signature recursive files scanning and verifying...
echo     notice: this step will take a much LONGER while. Please, be patient!
echo.
echo           a) %SS_PATH1%...
%TOOLSDIR%\sigcheck.exe -a -e -h -q -s -u -vt -v "%SS_PATH1%" > %LOGDIR%\sigcheck_1.txt
echo           b) %SS_PATH2%...
%TOOLSDIR%\sigcheck.exe -a -e -h -q -s -u -vt -v "%SS_PATH2%" > %LOGDIR%\sigcheck_2.txt
echo           c) %SS_PATH3%...
%TOOLSDIR%\sigcheck.exe -a -e -h -q -s -u -vt -v "%SS_PATH3%" > %LOGDIR%\sigcheck_3.txt

echo   Completed.

REM if "%PERFORM_ALL%" neq "1" goto MENU


:FINISH

REM **** LAST PHASE - 7z compressing
REM

echo.
echo.
echo LAST PHASE: Compressing the logs directory
echo     notice: this step may take a little while
%TOOLSDIR%\7z.exe a %LOGDIR% %LOGDIR%
move %LOGDIR%.7z LISET_LOGS.7z
del /S /F /Q %LOGDIR% 2> nul > nul
rmdir %LOGDIR% 2> nul > nul

echo.
echo   [+] Script has finished it's execution.
echo.
