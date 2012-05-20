#!/usr/bin/python2

import subprocess
import os

pipe = subprocess.Popen(["synclient","-m","100"],stdout=subprocess.PIPE,stderr=subprocess.PIPE)

output = pipe.stdout
buf = 0
flag = 0
delta = 0
time  = []

def action():
  print buf
  if buf > 150:
    os.system("qdbus org.kde.kwin /KWin org.kde.KWin.nextDesktop")
  elif buf < -150:
    os.system("qdbus org.kde.kwin /KWin org.kde.KWin.previousDesktop")

while(True):
  one = output.readline().split()
  two = output.readline().split()
  if one[0] != 'time' and two[0] != 'time':
    t1 = float(one[0])
    x1 = int(one[1])
    z1 = int(one[3])
    w1 = int(one[5])
    t2 = float(two[0])
    x2 = int(two[1])
    z2 = int(two[3])
    w2 = int(two[5])
    if z1 > 40 and w1 >= 8 and z2 > 40 and w2 >= 8:
      delta = x2 - x1
      if flag:
	dt = t2 - time[0]
	if dt >0.4:
	  time = []
	  action()
	  buf = 0
	  flag = 0
	else:
	  buf += delta
      else:
	flag = 1
	buf += delta
      time.append(t1)
      time.append(t2)
    elif abs(delta)> 1000 or z1 <= 40 or z2 <=40 or buf > 1500 or w1 < 8 or w2 < 8:
	time = []
	if flag:
	  action()
	buf = 0
	flag = 0
    else:
	buf = 0
	flag = 0
