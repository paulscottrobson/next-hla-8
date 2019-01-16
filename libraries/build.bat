@echo off
pushd ..\bootloader
call build.bat
popd
rem
rem		Build the library source file image
rem
del /Q temp\*
del /Q boot.img
python ../scripts/makelibrary.py core
rem zasm -buw boot.asm -o boot.img -l boot.lst
rem
rem		Copy to files, and the scripts directory for testing
rem
if exist boot.img copy boot.img ..\files
if exist boot.img copy boot.img ..\scripts

