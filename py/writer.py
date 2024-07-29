#!/bin/python3

import sys

print("In writer.py")
with open("script/premint/output.csv", 'a') as f:
    f.write(sys.argv[1])