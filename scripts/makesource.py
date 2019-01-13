# ***************************************************************************************
# ***************************************************************************************
#
#		Name : 		makeource.py
#		Author :	Paul Robson (paul@robsons.org.uk)
#		Date : 		13th January 2019
#		Purpose :	Assemblable Library Source builder.
#
# ***************************************************************************************
# ***************************************************************************************

import re,os,sys
#
#		Get components
#
files = []
for parts in [x.strip() for x in sys.argv[1:] if x.strip().lower() != "core"]:
	files.append(parts.lower())
files.sort()
files.insert(0,"core")
#
#		Build assembly file, grab dictionary words as we copy.
#
dictwords = []
h = open("boot.asm","w")
for f in files:
	for l in open("sources"+os.sep+"lib."+f+".libasm").readlines():
		if l.startswith("IMPORT_"):
			dictwords.append(l.strip())
		h.write(l.rstrip()+"\n")
h.write("FreeMemory:\n")
#
#		Build dictionary.
#
h.write("\torg  $C000\n")
dictwords.sort()
for lbl in dictwords:
	xName = "".join([chr(int(x,16)) for x in lbl[7:].split("_")])
	xName = xName.lower()
	h.write("\tdb   {0}\n".format(len(xName)+5))
	h.write("\tdb   $22\n")
	h.write("\tdw   {0}\n".format(lbl))
	h.write("\tdb   {0}\n".format(len(xName)))
	h.write("\tdb   \"{0}\"\n\n".format(xName))
	#print(lbl,xName)
h.write("\tdb 	0\n")		
h.close()
