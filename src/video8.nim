import sdl2_nim/sdl
import strformat

import memory8
import cpu8
import input8

# Convert a Chip-8 pixel to a square of size WindowScale
const WindowScale = 10

# Simplifies SDL Error Checking
proc checkSDL0(errorCode: int) {.inline.} =
  if errorCode != 0:
    stderr.writeLine(fmt"[FATAL] {sdl.getError()}")
    quit 1

proc draw(renderer: Renderer, mem: ptr Memory) =
  checkSDL0 renderer.setRenderDrawColor(176, 94, 0, 0xFF)
  checkSDL0 renderer.renderClear()
  checkSDL0 renderer.setRenderDrawColor(255, 196, 0, 0xFF)

  for idx in 0..<GFXMemorySize:
    if mem[][idx.GFXAddress]:
      let x = (idx mod ScreenSize.w) * WindowScale
      let y = (idx div ScreenSize.w) * WindowScale
      var rect = Rect(x: x, y: y, w: WindowScale, h: WindowScale)
      checkSDL0 renderer.renderFillRect(rect.addr)
  drawFlag = false
  renderer.renderPresent()

proc video*(mem: ptr Memory) {.thread.} =
  checkSDL0 init(INIT_VIDEO)
  var window = createWindow("Nim-8", WINDOWPOS_CENTERED, WINDOWPOS_CENTERED, 
               ScreenSize.w * WindowScale, ScreenSize.h * WindowScale, 0) 
  if window == nil: raise ValueError.newException "Cannot create the Window"
  var renderer = createRenderer(window, -1, RENDERER_ACCELERATED)

  while input8.running : # is draw flag is true draw the gfx buffer on the window
    if drawFlag: draw renderer, mem
    delay 20

  renderer.destroyRenderer()
  window.destroyWindow()