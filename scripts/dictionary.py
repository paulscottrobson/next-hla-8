# ***************************************************************************************
# ***************************************************************************************
#
#		Name : 		dictionary.py
#		Author :	Paul Robson (paul@robsons.org.uk)
#		Date : 		10th January 2019
#		Purpose :	Next High Level Assembler, dictionary.
#
# ***************************************************************************************
# ***************************************************************************************

# ***************************************************************************************
#						Identifiers to store in the dictionary
# ***************************************************************************************

class Identifier(object):
	def __init__(self,name,value):
		self.name = name.strip().lower()
		self.value = value
	def getName(self):
		return self.name
	def getValue(self):
		return self.value
	def isGlobal(self):
		return self.name.startswith("$")
	def toString(self):
		return "{0} {1}:${2:04x}".format(self.getType(),self.getName(),self.getValue())

class VariableIdentifier(Identifier):
	def getType(self):
		return "VAR"
class ProcedureIdentifier(Identifier):
	def getType(self):
		return "PRC"
class ExternalProcedureIdentifier(ProcedureIdentifier):
	def getType(self):
		return "EXT"

# ***************************************************************************************
#									Dictionary object
# ***************************************************************************************

class Dictionary(object):
	def __init__(self):
		self.identifiers = {}
	#
	#		Add an identifier to the dictionary, testing for collision.
	#
	def add(self,ident):
		name = ident.getName()
		if name in self.identifiers:											# check doesn't already exist
			raise AssemblerException("Duplicate identifier "+name)
		self.identifiers[name] = ident											# update dictionary.
	#
	#		Find an identifier
	#
	def find(self,key):
		key = key.strip().lower()
		return None if key not in self.identifiers else self.identifiers[key]
	#
	#		Remove local variables
	#
	def endProcedure(self):
		oldDictionary = self.identifiers		
		self.identifiers = {}					
		for name in oldDictionary.keys():
			if oldDictionary[name].isGlobal() or \
						isinstance(oldDictionary[name],ProcedureIdentifier):
				self.identifiers[name] = oldDictionary[name]

	#
	#		Remove everything except global procedures.
	#
	def endModule(self):
		oldDictionary = self.identifiers 				
		self.identifiers = {}													
		for name in oldDictionary.keys():
			if oldDictionary[name].isGlobal() and \
							isinstance(oldDictionary[name],ProcedureIdentifier):
				self.identifiers[name] = oldDictionary[name]
	#
	#		Get all boot procedures.
	#
	def getBootProcedureList(self):
		bootList = []
		for k in self.identifiers.keys():
			if isinstance(self.identifiers[k],ProcedureIdentifier):
				if self.identifiers[k].getName().endswith(".boot(0"):
					bootList.append([self.identifiers[k].getName(),self.identifiers[k].getValue()])
		bootList.sort(key = lambda x:x[1])
		return bootList
	#
	#		Convert to string
	#
	def toString(self):
		return "\n".join([x.toString() for x in self.identifiers.values()])

if __name__ == "__main__":
	dc = Dictionary()
	dc.add(VariableIdentifier("v1",2048))
	dc.add(ProcedureIdentifier("$p1(2",3072))
	dc.add(ExternalProcedureIdentifier("p1(1",4096))	
	dc.add(ProcedureIdentifier("b1.boot(0",3))
	dc.add(ProcedureIdentifier("b3.boot(0",5))
	dc.add(ProcedureIdentifier("b2.boot(0",4))
	print(dc.toString())
	print(dc.getBootProcedureList())