import sdl2_nim/sdl
import strformat, os
import cpu8
from input8 import manageEvents
import memory8

# Convert a Chip-8 pixel to a square of size WindowScale
const WindowScale = 10

# Simplifies SDL Error Checking
proc checkSDL0(errorCode: int) =
  if errorCode != 0:
    stderr.writeLine(fmt"[FATAL] {sdl.getError()}")
    quit 1

proc draw(renderer: Renderer) =
  checkSDL0 renderer.setRenderDrawColor(176, 94, 0, 0xFF)
  checkSDL0 renderer.renderClear()
  checkSDL0 renderer.setRenderDrawColor(255, 196, 0, 0xFF)

  for idx in 0..<(ScreenSize.w*ScreenSize.h):
    if memory[idx.GFXAddress]:
      let x = (idx mod ScreenSize.w) * WindowScale
      let y = (idx div ScreenSize.w) * WindowScale
      var rect = Rect(x: x, y: y, w: WindowScale, h: WindowScale)
      checkSDL0 renderer.renderFillRect(rect.addr)
  drawFlag = false
  renderer.renderPresent()

when isMainModule:
  # Check if the rom was passed as command line argument
  if paramCount() != 1:
    stderr.writeLine fmt"Usage: {paramStr 0} /path/to/rom"
    quit 1
  init(paramStr(1)) # Init CPU
  checkSDL0 init(sdl.InitVideo)
  var window = createWindow("Nim-8", WINDOWPOS_CENTERED, WINDOWPOS_CENTERED, 
               ScreenSize.w * WindowScale, ScreenSize.h * WindowScale, 0) 
  if window == nil: raise ValueError.newException "Cannot create the Window"
  var renderer = createRenderer(window, -1, RENDERER_ACCELERATED)
  
  # GameLoop
  while true:
    # is draw flag is true draw the gfx buffer on the window
    if drawFlag: draw renderer
    manageEvents()
    cpuCycle()
    delay 1000 div 60