#!/opt/local/bin/python

import sys

for line in sys.stdin:
  y = int(line[0:2])
  x = int(line[2:5])
  y = y + 10
  x = x + 12 + y // 2
  print("SlantPoint(x: %d, y:%d)," % (x,y))
