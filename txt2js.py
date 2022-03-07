#! /usr/bin/env python
""" Convert raw data to JavaScript importable file

This way we can display the graph locally,
without Ajax and cross-domain restriction,
without web server.

usage: txt2js.py name < file.txt > file.js

file.txt must be formated as: "float*\n"*
"""
import sys

name = sys.argv[1]
data = [map(float, line.split()) for line in sys.stdin.readlines()]
print("%s = [\n%s,\n]"%(name, ',\n'.join('%r'%line for line in data)))
