#!/usr/bin/python

imgFile="forestground06dv5.png"
outFile="forest/tile"

import sys
from PIL import Image

big=Image.open(imgFile)
bigW,bigH=big.size

tilesW=int(bigW/32)
tilesH=int(bigH/32)

for row in range(tilesH):

	for col in range(tilesW):

		outpat="%s_%03d_%03d.png" % (outFile,row,col)
		temp=big.crop((col*32,row*32,col*32+32,row*32+32))
		temp.save(outpat)

