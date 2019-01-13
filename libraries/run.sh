sh build.sh
if [ -e boot.img ]
then
	wine ../bin/CSpect.exe -zxnext -cur -brk -exit -w3 ../files/bootloader.sna 
fi



