# ***************************************************************************************
# ***************************************************************************************
#
#		Name : 		makelibsource.py
#		Author :	Paul Robson (paul@robsons.org.uk)
#		Date : 		13th January 2019
#		Purpose :	Build library sources
#
# ***************************************************************************************
# ***************************************************************************************

import re,sys,os

libList = [x for x in os.listdir(".") if x.startswith("lib.")]		# list to assemble.
for libRoot in libList:
	print("Building library source for "+libRoot)
	fileList = []
	for root,dirs,files in os.walk(libRoot):
		for f in files:
			if f.endswith(".asm"):
				fileList.append(root+os.sep+f)
	fileList.sort()
	h = open("sources"+os.sep+libRoot+".libasm","w")
	for f in fileList:
		for s in [x.rstrip().replace("\t"," ") for x in open(f).readlines()]:
			if s.startswith("EXTERN_"):
				h.write("; **** {0} ****\n".format(s))
				m = re.match("^EXTERN\_(.*?)\((.*)\)$",s)
				if m is None:
					raise Exception("Syntax "+s)
				params = [x for x in m.group(2).split(",") if x != ""]
				stub = m.group(1)+"("+str(len(params))
				label = "IMPORT_"+"_".join(["{0:02x}".format(ord(x)) for x in stub])
				h.write(label+"\n")
			else:
				s = "\t"+s.strip() if s.startswith(" ") else s.strip()
				h.write(s+"\n")
	h.close()
	print("\tBuilt.")

