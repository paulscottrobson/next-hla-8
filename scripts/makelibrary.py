# ***************************************************************************************
# ***************************************************************************************
#
#		Name : 		makelibrary.py
#		Author :	Paul Robson (paul@robsons.org.uk)
#		Date : 		13th January 2019
#		Purpose :	List Dictionary contents
#
# ***************************************************************************************
# ***************************************************************************************

import re,sys,os

class LibBuilder(object):
	def __init__(self):
		self.hOut = open("temp"+os.sep+"boot.asm","w")
		self.externals = {}
	#
	def append(self,subdir):
		fileList = []
		for root,dirs,files in os.walk("sources"+os.sep+subdir):
			for f in files:
				if f.endswith(".asm"):
					fileList.append(root+os.sep+f)
		fileList.sort()
		for f in fileList:
			for l in open(f).readlines():
				l = l.rstrip().replace("\t"," ")
				l = "\t"+l.strip() if l.startswith(" ") else l.strip()
				if l.startswith("EXTERN_"):
					m = re.match("^EXTERN\_(.*)\((.*?)\)$",l)
					name = m.group(1)+"("+str(len([x for x in m.group(2).replace(" ","").split(",") if x != ""]))
					name = name.lower()
					scrambled = "_".join(["{0:02x}".format(ord(x)) for x in name])
					self.hOut.write("external_{0}:\n".format(scrambled))
					self.externals[name] = "external_"+scrambled
				else:
					self.hOut.write(l+"\n")
	#
	def complete(self):
		self.hOut.write("FreeMemory:\n")
		self.hOut.write("\torg $C000\n")
		keys = [x for x in self.externals.keys()]
		keys.sort()
		for k in keys:
			self.hOut.write("\tdb {0}+5\n".format(len(k)))
			self.hOut.write("\tdb $22\n")
			self.hOut.write("\tdw {0}\n".format(self.externals[k]))
			self.hOut.write("\tdb {0},\"{1}\"\n\n".format(len(k),k))
builder = LibBuilder()
builder.append("core")
for part in sys.argv[1:]:
	if part != "core":
		builder.append(part)
builder.complete()
	