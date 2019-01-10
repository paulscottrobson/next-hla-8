# ***************************************************************************************
# ***************************************************************************************
#
#		Name : 		assembler.py
#		Author :	Paul Robson (paul@robsons.org.uk)
#		Date : 		10th January 2019
#		Purpose :	Next High Level Assembler, assembler worker.
#
# ***************************************************************************************
# ***************************************************************************************

from errors import *
from dictionary import *
from democodegen import *
import re

class AssemblerWorker(object):
	def __init__(self,codeGen):
		self.codeGen = codeGen 												# code generator.
		self.dictionary = Dictionary()										# dictionary.
		self.rxIdentifier = "[\$a-z][a-z0-9\_\.]*"							# rx identifier.
		self.keywords = ["if","while","proc","for","endproc"]				# keywords
	#
	#		Assemble an array of strings.
	#
	def assemble(self,src):
		src = self.preProcess(src)											# tidying, strings.
		#
		src = AssemblerWorker.NEWLINE.join(src).lower().replace(" ",":")	# bang together as one.
		while src.find("::") >= 0:											# replace double seps.
			src = src.replace("::",":")
		#
		src = self.processIdentifiers(src,True)								# handle globals.
		#
		src = re.split("(proc\:*"+self.rxIdentifier+"\(.*?\))",src)			# split into procedures
		AssemblerException.LINE = 0
		if not src[0].startswith("proc"):									# stuff before first ?
			if re.match("^[\\"+AssemblerWorker.NEWLINE+"\:]*$",src[0]) is None:
				AssemblerException.LINE = 0
				raise AssemblerException("Code before first procedure")
			AssemblerException.LINE = src[0].count(AssemblerWorker.NEWLINE)	# adjust current line
			del src[0]														# remove it.
		assert len(src) % 2 == 0											# should be even ...
		#
		for pn in range(0,len(src),2):										# in pairs.
			src[pn] = self.processIdentifiers(src[pn],False)				# parameters
			src[pn+1] = self.processIdentifiers(src[pn+1],False)			# body locals.
			self.processProcHeader(src[pn])									# parameter stuff.
			self.processProcBody(src[pn+1])									# actual code block
			#print(self.dictionary.toString())
			self.dictionary.endProcedure()									# dict : end of procedure
		#
		self.dictionary.endModule()											# dict : end of module
	#
	#		Process lines for comments, tabs and quoted strings, strings are replaced
	#		by addresses pointing to ASCIIZ constants
	#
	def preProcess(self,src):
		src = [x if x.find("//") < 0 else x[:x.find("//")] for x in src]	# remove comments
		src = [x.strip().replace("\t"," ") for x in src]					# strip and tabs
		for l in range(0,len(src)):											# quoted string
			if src[l].find('"') >= 0:										# speed up checking
				if src[l].count('"') % 2 == 1:								# check even number quotes
					AssemblerException.LINE = l + 1
					raise AssemblerException("Missing or extra quote mark")
				parts = re.split("(\".*?\")",src[l])						# split up
				for pn in range(0,len(parts)):								# check all parts.
					if parts[pn].startswith('"') and parts[pn].endswith('"') and len(parts[pn]) >= 2:
																			# replace string with address
						parts[pn] = str(self.codeGen.createStringConstant(parts[pn][1:-1]))
				src[l] = "".join(parts)										# rebuild.
		return(src)
	#
	#		Process out identifiers at a local or global level. Find them , allocate
	#		memory if required, and replace their identifiers with ~<address>
	#
	def processIdentifiers(self,src,globalLevel):
		rx = "("+("\$" if globalLevel else "")+self.rxIdentifier+("\(?)")	# actual rx
		rxc = re.compile(rx)												# compile it
		parts = rxc.split(src)												# split them out.
		for pn in range(0,len(parts)):										# look at all variables
			if rxc.match(parts[pn]) and (not parts[pn].endswith("(")) and parts[pn] not in self.keywords:
				if self.dictionary.find(parts[pn]) is None:					# new variable ?
					self.dictionary.add(VariableIdentifier(parts[pn],self.codeGen.allocSpace(None,parts[pn])))	
																			# replace with address+marker
				parts[pn] = AssemblerWorker.ADDRESS+str(self.dictionary.find(parts[pn]).getValue())	
		src = "".join(parts)												# back together
		src = src.replace("."+AssemblerWorker.ADDRESS,"")					# .variable => address
		return src
	#
	#		Process procedure header
	#
	def processProcHeader(self,header):
		m = re.match("^proc\:*("+self.rxIdentifier+")\((.*?)\)$",header)	# chop into bits.
		assert m is not None												# should be okay !
		params = [x for x in m.group(2).split(",") if x != ""]				# array of params
		name = m.group(1)+"("+str(params)									# name of procedure
																			# create procedure.
		self.dictionary.add(ProcedureIdentifier(name,self.codeGen.getAddress()))
		print(params)
		for pn in range(0,len(params)):										# check each parameter
			if re.match("^\\"+AssemblerWorker.ADDRESS+"\d+$",params[pn]) is None:
				raise AssemblerException("Bad parameter")					# must be ~addr
			self.codeGen.storeParamRegister(pn,int(params[pn][1:]))			# save param to target
	#
	#		Process procedure body.
	#
	def processProcBody(self,body):
		splitElements = ":{}+-*/%&|^!@"+AssemblerWorker.NEWLINE				# split points
		rx = "(["+"".join(["\\"+x for x in splitElements])+"])"				# make an rx
		body = re.split(rx,body)											# make into bits.
		body = [x for x in body if x != ":" and x != ""]					# remove colon seps
		print(body,rx)

AssemblerWorker.NEWLINE = ";"
AssemblerWorker.ADDRESS = "~"

if __name__ == "__main__":
	src = """

	proc pr1() "count" !.$x1		// Hello world
	proc pr2(a) pr1(a+"temp"+5+demo)
	proc $global(a,x,w) 
		a+b-c!$count:$call(42,x,w):pr2(.$count)
	""".split("\n")
	aw = AssemblerWorker(DemoCodeGenerator())		
	aw.assemble(src)
