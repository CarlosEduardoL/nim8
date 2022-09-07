import godot
import godotapi/[node, engine]
import macros

import strformat, os

import cpu8
import memory8
import timer8

gdobj Emulator of Node:

  var pause: bool
  var stop: bool
  var sound* {.gdExport.} : bool

  var memory*: Memory
  var cpu: CPU
  var timer = timer8.Timer()

  method ready*() =
    print "Emulator singleton Load"

  method process*(delta: float) =
    if self.cpu == nil or self.stop: return
    if self.timer.pulse(delta):
      self.sound = self.cpu.cycle()

  method load_rom*(rom: string) {.gdExport.} =
    self.stop = true
    self.memory = newMemory()
    self.cpu = initCPU self.memory
    if not rom.fileExists:
      printError(fmt"{rom} file doest'n exist")
      return

    let file = rom.open()
    let loaded = file.readBuffer(cast[pointer](self.memory[ProgramStartPoint].addr), file.getFileSize())
    if loaded == file.getFileSize(): print fmt"ROM {rom} successfully loaded"
    file.close()
    self.stop = false

  method onKeyChanged*(index: int, value: bool) {.gdExport.} =
    self.memory.keys[index] = value