#!/bin/python3

import sys


print("In writer.py")
with open("output", 'a') as f:
    f.write(sys.argv[1])