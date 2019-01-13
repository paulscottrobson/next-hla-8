pushd ../bootloader
sh build.sh
popd
#
#		Build the individual source files for each library
#
rm sources/* files/boot.img
python ../scripts/makelibsource.py
#
#		Compact them together and create dictionary.
#
python ../scripts/makesource.py core 
#
#		Assemble it.
#
zasm -buw boot.asm -o boot.img -l boot.lst
if [ -e boot.img ]
then
	cp boot.img ../files
fi
