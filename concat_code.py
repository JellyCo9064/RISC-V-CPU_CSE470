# -*- coding: utf-8 -*-
"""
Created on Tue Feb 14 14:34:30 2023

@author: there
"""

def concat(file):
    f0 = open("hexfiles/" + file + "0.hex", "r")
    f1 = open("hexfiles/" + file + "1.hex", "r")
    f2 = open("hexfiles/" + file + "2.hex", "r")
    f3 = open("hexfiles/" + file + "3.hex", "r")
    
    c0 = list(map(str.strip, f0.readlines()))
    c1 = list(map(str.strip, f1.readlines()))
    c2 = list(map(str.strip, f2.readlines()))
    c3 = list(map(str.strip, f3.readlines()))
    
    f = open("programs/" + file + ".mem", "w")
    
    for i in range(len(c0)):
        f.write(c3[i] + c2[i] + c1[i] + c0[i] + "\n")
        
    f0.close()
    f1.close()
    f2.close()
    f3.close()
    f.close()

if __name__ == "__main__":
    for file in ["code", "data"]:
        concat(file)