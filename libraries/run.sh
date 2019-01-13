sh build.sh
if [ -e boot.img ]
then
	python ../scripts/assembler.py
	wine ../bin/CSpect.exe -zxnext -cur -brk -exit -w3 ../files/bootloader.sna 
fi



