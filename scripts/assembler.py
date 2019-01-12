# ***************************************************************************************
# ***************************************************************************************
#
#		Name : 		assembler.py
#		Author :	Paul Robson (paul@robsons.org.uk)
#		Date : 		12th January 2019
#		Purpose :	Next High Level Assembler, assembler worker.
#
# ***************************************************************************************
# ***************************************************************************************

from democodegen import *
import re

# ***************************************************************************************
#									Exception for HLA
# ***************************************************************************************

class AssemblerException(Exception):
	def __init__(self,message):
		Exception.__init__(self)
		self.message = message
		print(message,AssemblerException.LINE)

# ***************************************************************************************
#									 Worker Object
# ***************************************************************************************

class AssemblerWorker(object):
	def __init__(self,codeGen):
		self.codeGen = codeGen 												# code generator.
		self.globals = {}													# global identifiers.
		self.rxIdentifier = "[\$a-z][a-z0-9\_\.]*"							# rx identifier.		
		self.keywords = """ if,endif,while,endwhile,defproc,					
							endproc,for,next"""								# keyword list.
		self.keywords = re.sub("\s+","",self.keywords).split(",")			# make a list
	#
	#		Assemble an array of strings.
	#
	def assemble(self,src):
		#
		AssemblerException.LINE = 0											# reset line ref.
		src = [x if x.find("//") < 0 else x[:x.find("//")] for x in src]	# comments
		src = [x.replace("\t"," ").strip() for x in src]					# tabs and spaces
		#
		src = [self.processQuotes(x) for x in src] 							# process quotes.
		#
		src = ":~:".join(src).replace(" ","").lower()						# bash together
		src = re.split("(defproc)",src)										# split round procedures.
		src = [self.processVariables(x) for x in src] 						# process variables.
		src = [x for x in ("".join(src)).split(":") if x != ""]				# rejoin, split to cmds	
		for cmd in src:														# process everything.
			if cmd == "~":
				AssemblerException.LINE += 1
			else:
				self.processCommand(cmd)			
	#
	#		Process quoted strings, replacing them with an ASCIIZ version in code
	#		and the address in the source.
	#
	def processQuotes(self,line):
		if line.find('"') >= 0:												# any strings ?
			if line.count('"') % 2 != 0:									# check even number
				raise AssemblerException("Quotes do not balance "+line)
			parts = re.split("(\".*?\")",line)								# split out
			for pn in range(0,len(parts)):									# strip out replace with addresses
				if parts[pn].startswith('"') and parts[pn].endswith('"'):
					parts[pn] = str(self.codeGen.createStringConstant(parts[pn][1:-1]))
			line = "".join(parts)											# put back together
		return line
	#
	#		Process variables, replacing them with an address, allocating as necessary.
	#
	def processVariables(self,code):
		localVars = {}														# local variables
		splitter = re.compile("("+self.rxIdentifier+"\(?)")					# splitter, tests for proc call too
		parts = splitter.split(code)										# split up
		for i in range(0,len(parts)):										# look through
			if splitter.match(parts[i]):									# identifier.
				if parts[i] not in self.keywords:							# not a keyword
					if not parts[i].endswith("("):							# not a procedure call/def
																			# identify dictionary to use.
						vdict = self.globals if parts[i].startswith("$") else localVars
						if parts[i] not in vdict:							# new ? allocate it.
							vdict[parts[i]] = self.codeGen.allocSpace(None,parts[i])									
						parts[i] = "@"+str(vdict[parts[i]])					# subsititute it.
		return "".join(parts).replace("@@","")								# @@ makes @var work
	#
	#		Process a single command.
	#
	def processCommand(self,cmd):
		print("\t==== "+cmd+" ====")
		# TODO: IF/WHILE .. ENDIF/ENDWHILE
		# TODO: FOR/NEXT
		#
		if cmd.startswith("defproc"):										# procedure call.
			m = re.match("^defproc(.*)\((.*)\)$",cmd)						# analyse it.
			if m is None:
				raise AssemblerException("Bad definition "+cmd)
			params = [x for x in m.group(2).split(",") if x != ""]			# list of parameters
			name = m.group(1)+"("+str(len(params)) 							# identifier
			if name in self.globals:
				raise AssemblerException("Duplicate procedure name "+name)
			self.globals[name] = self.codeGen.getAddress()					# define routine global
			for i in range(0,len(params)):									# work through params
				if re.match("^\@\d+$",params[i]) is None:					# must be variable.
					raise AssemblerException("Bad parameter "+params[i])
				self.codeGen.storeParamRegister(i,int(params[i][1:]))		# code to save passed param
			return
		#
		if cmd == "endproc":												# endproc returns.
			self.codeGen.returnSubroutine()
			return
		#
		m = re.match("^("+self.rxIdentifier+")\((.*)\)$",cmd)				# procedure invocation
		if m is not None:
			# TODO: Invocation code
			print(m.groups())
			return
		#
		m = re.match("^\@(\d+)=(.*)$",cmd)									# var = expr
		if m is not None:
			self.processExpression(m.group(2))								# assemble expression
			self.codeGen.storeDirect(int(m.group(1)))						# save to variable.
			return
		#
		m = re.match("^\@(\d+)([\?\!])(\@?)(\d+)\=(.*)$",cmd)				# var<!?><sterm> = expr
		if m is not None:
			self.processExpression(m.group(5))								# assemble expression
			self.codeGen.storeIndirect(int(m.group(1)),m.group(3)=="",		# save indirect
												int(m.group(4)),m.group(2) == "?")
			return
		raise AssemblerException("Syntax Error "+cmd)
	#
	#		Assemble expression
	#
	def processExpression(self,expr):
		pass
		# TODO: Invocation code.
if __name__ == "__main__":
	src = """
	defproc pr(x,y,z):x = y + @z:x?2=0:x!z=y:endproc
	defproc pr1(a):b = a + $count:endproc			// a comment
	defproc pr2():pr1("Hello world"):c="end":pr(a,b,c):endproc
	""".split("\n")
	aw = AssemblerWorker(DemoCodeGenerator())		
	aw.assemble(src)
	print(aw.globals)