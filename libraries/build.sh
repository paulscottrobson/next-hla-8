#
#		Build the individual source files for each library
#
rm sources/*
python ../scripts/makelibsource.py
#
#		Compact them together.
#

echo "FreeMemory:" >>sources/lib.core.libasm
echo "  org 0xC000" >>sources/lib.core.libasm
echo "  db  0" >>sources/lib.core.libasm

zasm -buw sources/lib.core.libasm -o boot.img -l boot.lst
