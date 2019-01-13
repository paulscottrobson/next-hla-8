# ***************************************************************************************
# ***************************************************************************************
#
#		Name : 		imagelib.py
#		Author :	Paul Robson (paul@robsons.org.uk)
#		Date : 		13th January 2019
#		Purpose :	Binary Image Library
#
# ***************************************************************************************
# ***************************************************************************************

import sys

class MemoryImage(object):
	def __init__(self,fileName = "boot.img"):
		self.fileName = fileName
		h = open(fileName,"rb")
		self.image = [x for x in h.read(-1)]
		h.close()
		self.sysInfo = self.read(0,0x8004)+self.read(0,0x8005)*256
		self.currentPage = 	self.read(0,self.sysInfo+2)
		self.currentAddress = self.read(0,self.sysInfo+0)+self.read(0,self.sysInfo+1)*256
		self.echo = True
	#
	#		Return sys.info address
	#
	def getSysInfo(self):
		return self.sysInfo 
	#
	#		Return dictionary page
	#
	def dictionaryPage(self):
		return 0x20
	#
	#		Return current page and address for next free code.
	#
	def getCodePage(self):
		return self.currentPage
	def getCodeAddress(self):
		return self.currentAddress
	def setCodeAddress(self,addr):
		self.currentAddress = addr
	#
	#		Convert a page/z80 address to an address in the image
	#
	def address(self,page,address):
		assert address >= 0x8000 and address <= 0xFFFF
		if address < 0xC000:
			return address & 0x3FFF
		else:
			return (page - 0x20) * 0x2000 + 0x4000 + (address & 0x3FFF)
	#
	#		Read byte from image
	#
	def read(self,page,address):
		self.expandImage(page,address)
		return self.image[self.address(page,address)]
	#
	#		Write byte to image
	#
	def write(self,page,address,data,dataType = 2):
		self.expandImage(page,address)
		assert data >= 0 and data < 256
		self.image[self.address(page,address)] = data
	#
	#		Write byte/word
	#
	def cByte(self,data):
		self.write(self.currentPage,self.currentAddress,data)
		if self.echo:
			print("{0:02x}:{1:04x}   {2:02x}".format(self.currentPage,self.currentAddress,data))
		self.currentAddress += 1
	#
	def cWord(self,data):
		self.write(self.currentPage,self.currentAddress,data & 0xFF)
		self.write(self.currentPage,self.currentAddress+1,data >> 8)
		if self.echo:
			print("{0:02x}:{1:04x}   {2:04x}".format(self.currentPage,self.currentAddress,data))
		self.currentAddress += 2
	#
	#		Expand physical size of image to include given address
	#
	def expandImage(self,page,address):
		required = self.address(page,address)
		while len(self.image) <= required:
			self.image.append(0x00)
	#
	#		Add a physical entry to the image dictionary
	#
	def addDictionary(self,name,page,address):
		p = self.findEndDictionary()
		#print("{0:04x} {1:20} {2:02x}:{3:04x}".format(p,name,page,address))
		name = name.strip().lower()
		assert len(name) < 64 and name != "","Bad name '"+name+"'"
		dp = self.dictionaryPage()
		self.lastDictionaryEntry = p
		self.write(dp,p+0,len(name)+5)
		self.write(dp,p+1,page)
		self.write(dp,p+2,address & 0xFF)
		self.write(dp,p+3,address >> 8)
		self.write(dp,p+4,len(name) & 0x3F)
		aname = [ord(x) for x in name]
		for i in range(0,len(aname)):
			self.write(dp,p+5+i,aname[i])
		p = p + len(name) + 5
		self.write(dp,p,0)
	#
	#		Find the end of the dictionary
	#
	def findEndDictionary(self):
		p = 0xC000
		while self.read(self.dictionaryPage(),p) != 0:
			p = p + self.read(self.dictionaryPage(),p)
		return p
	#
	#		Extract the dictionary
	#
	def getDictionary(self):
		dictionary = {}
		dp = self.dictionaryPage()
		p = 0xC000
		while self.read(dp,p) != 0:
			name = ""
			for i in range(0,self.read(dp,p+4) & 0x3F):
				name += chr(self.read(dp,p+5+i))				
			entry = { "name":name,"page":self.read(dp,p+1),	\
							"address":self.read(dp,p+2)+256*self.read(dp,p+3)}
			dictionary[name] = entry
			p = p + self.read(dp,p)
		return dictionary		
	#
	#		Set boot
	#
	def setBoot(self,page,address):
		self.write(0,self.sysInfo+4,address & 0xFF)
		self.write(0,self.sysInfo+5,address >> 8)
		self.write(0,self.sysInfo+6,page)
		self.write(0,self.sysInfo+7,0)
	#
	#		Write the image file out.
	#
	def save(self,fileName = None):
		self.write(0,self.sysInfo+0,self.currentAddress & 0xFF)
		self.write(0,self.sysInfo+1,self.currentAddress >> 8)
		self.write(0,self.sysInfo+2,self.currentPage)
		self.write(0,self.sysInfo+3,0)

		fileName = self.fileName if fileName is None else fileName
		h = open(fileName,"wb")
		h.write(bytes(self.image))		
		h.close()

if __name__ == "__main__":
	z = MemoryImage()
	print(len(z.image))
	print(z.address(z.dictionaryPage(),0xC000))
	print(z.getDictionary())
	#	z.save()
