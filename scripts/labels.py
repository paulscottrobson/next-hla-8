# *********************************************************************************
# *********************************************************************************
#
#		File:		labels.py
#		Purpose:	Extract labels from assembler result
#		Date : 		13th January 2019
#		Author:		paul@robsons.org.uk
#
# *********************************************************************************
# *********************************************************************************

import re,sys

class ZasmLabelExtractor(object):
	def __init__(self,listFile):
		src = [x.rstrip().replace("\t"," ") for x in open(listFile,"r").readlines()]
		p = None
		for i in range(0,len(src)):
			if src[i].find("+++ global symbols +++") >= 0:
				p = i
		src = src[p+1:]
		src = [x.strip().lower() for x in src if x.strip() != ""]
		self.labels = {}
		for s in src:
			m = re.match("^(.*)\s+\=\s+\$([0-9a-f]+)",s)
			if m is not None:
				self.labels[m.group(1).strip()] = int(m.group(2),16)

	def getLabels(self):
		return self.labels

class SnasmLabelExtractor(object):
	def __init__(self,listFile):
		src = [x.rstrip().lower().replace("\t"," ") for x in open(listFile,"r").readlines() if x.strip() != ""]
		self.labels = {}
		for s in src:
			m = re.match("^al\s+c\:([0-9a-f]+)\s+\_(.*)\s*$",s)
			assert m is not None,s
			self.labels[m.group(2).strip()] = int(m.group(1),16)
			
	def getLabels(self):
		return self.labels

class LabelExtractor(ZasmLabelExtractor):
	pass