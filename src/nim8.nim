import strformat, os
import cpu8
from input8 import manageEvents, running
from video8 import video
import memory8
import timer8

when isMainModule:
  # Check if the rom was passed as command line argument
  if paramCount() != 1:
    stderr.writeLine fmt"Usage: {paramStr 0} /path/to/rom"
    quit 1
  init(paramStr(1)) # Init CPU
  
  var videoThread: Thread[ptr Memory]
  createThread(videoThread, video, memory.addr)
  
  var timer = initTimer()
  # GameLoop
  while input8.running:  
    manageEvents()
    cpuCycle()
    sleep timer.getDelay()

  videoThread.joinThread() # Wait for video gracefully shutdown to end main thread