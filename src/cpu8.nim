import strutils, strformat
import os, std/random

import memory8
import input8

var memory*: Memory
var delayTimer: uint8
var soundTimer: uint8
var drawFlag*: bool = true

proc init*(rom: string) =
  randomize() # Init Random module
  memory = newMemory()

  if not rom.fileExists: raise IOError.newException(fmt"{rom} file doest'n exist")

  let file = rom.open()
  let loaded = file.readBuffer(cast[pointer](memory[ProgramStartPoint].addr),
      file.getFileSize())
  if loaded == file.getFileSize(): echo fmt"ROM {rom} successfully loaded"
  file.close()

# convert the 12 less significant bits on a MemoryAddress
proc getAddress(opcode: Opcode): MemoryAddress = opcode and 0x0FFF

proc getNN(opcode: Opcode): uint8 = (opcode and 0x00FF).uint8

proc invalid(opcode: Opcode) {.inline, noreturn.} =
  stderr.writeLine fmt"[FATAL] invalid opcode {opcode.toHex}"
  quit 1

proc cpuCycle*() =
  var opcode: Opcode = memory.fetch()
  let vx: RegisterIndex = (opcode and 0x0F00) shr 8
  let vy: RegisterIndex = (opcode and 0x00F0) shr 4
  case (opcode shr 12).uint8 # https://en.wikipedia.org/w/index.php?title=CHIP-8
  of 0x0:
    if opcode == 0x00E0: memory.clearGfxBuffer() # 00E0 -> Clears the screen.
    elif opcode == 0x00EE: memory.pop() # 00EE -> Returns from a subroutine.
    else: opcode.invalid
  of 0x1: memory.jump opcode.getAddress # 1NNN -> Jumps to address NNN.
  of 0x2: # 2NN -> 	Calls subroutine at NNN.
    memory.push() # Saves the current program counter on the stack
    memory.jump opcode.getAddress
  of 0x3:
    # 3XNN -> Skips the next instruction if VX equals NN. (Usually the next instruction is a jump to skip a code block);
    if memory[vx] == opcode.getNN: memory.skip()
  of 0x4:
    # 4XNN ->	Skips the next instruction if VX does not equal NN. (Usually the next instruction is a jump to skip a code block);
    if memory[vx] != opcode.getNN: memory.skip()
  of 0x5:
    # 5XY0 -> Skips the next instruction if VX equals VY. (Usually the next instruction is a jump to skip a code block);
    if (opcode and 0x000F) != 0: opcode.invalid
    if memory[vx] == memory[vy]: memory.skip()
  of 0x6: memory[vx] = opcode.getNN  # 6XNN -> Sets VX to NN.
  of 0x7: memory[vx] += opcode.getNN # 7XNN -> Adds NN to VX. (Carry flag is not changed);
  of 0x8:
    case (opcode and 0x000F)
    of 0x0: memory[vx] = memory[vy] # 8XY0 -> Sets VX to the value of VY.
    of 0x1: memory[vx] = memory[vy] or  memory[vx] # 0XY1 -> Sets VX to VX or VY. (Bitwise OR operation);
    of 0x2: memory[vx] = memory[vy] and memory[vx] # 0XY2 -> Sets VX to VX and VY. (Bitwise AND operation);
    of 0x3: memory[vx] = memory[vy] xor memory[vx] # 0XY3 -> Sets VX to VX xor VY.
    of 0x4: memory[vx] += memory[vy] # 0XY4 -> Adds VY to VX. VF is set to 1 when there's a carry, and to 0 when there is not.
    of 0x5: memory[vx] -= memory[vy] # 0XY5 -> VY is subtracted from VX. VF is set to 0 when there's a borrow, and 1 when there is not.
    of 0x6: # 0XY6 -> Stores the least significant bit of VX in VF and then shifts VX to the right by 1.
      memory[VF] = memory[vx] and 0x01
      memory[vx] = memory[vx] shr 1
    of 0x7: # 0XY7 -> Sets VX to VY minus VX. VF is set to 0 when there's a borrow, and 1 when there is not.
      memory[vx] = memory[vy] - memory[vx] 
    of 0xE: # 0XYE -> Stores the most significant bit of VX in VF and then shifts VX to the left by 1.
      memory[VF] = memory[vx] and 0x80
      memory[vx] = memory[vx] shl 1
    else: opcode.invalid
  of 0x9: # 9XY0 -> Skips the next instruction if VX does not equal VY. (Usually the next instruction is a jump to skip a code block);
    if (opcode and 0x000F) != 0: opcode.invalid
    if memory[vy] != memory[vx]: memory.skip()
  of 0xA: # ANNN -> Sets I to the address NNN.
    memory.I() = opcode.getAddress
  of 0xB: # BNNN -> Jumps to the address NNN plus V0.
    memory.jump memory[V0] + opcode.getAddress
  of 0xC: # CXNN -> Sets VX to the result of a bitwise and operation on a random number (Typically: 0 to 255) and NN.
    memory[vx] = rand(255).uint8 and opcode.getNN
  of 0xD: 
    # DXYN -> Draws a sprite at coordinate (VX, VY) that has a width of 8 pixels and a height of N pixels. 
    #         Each row of 8 pixels is read as bit-coded starting from memory location I; I value does not change after the execution of this instruction. As described above, VF is set to 1 if any screen pixels are flipped from set to unset when the sprite is drawn, and to 0 if that does not happen
    let x = memory[vx]
    let y = memory[vy]
    let height = opcode and 0x000F
    memory[VF] = 0
    for row in 0.uint16..<height:
      let line = memory[memory.I + row]
      for bias in 0..<8:
        if (line and (0x80.uint8 shr bias)) != 0:
          if memory[GFXAddress(x + bias.uint16 + ((y + row.uint16) * ScreenSize.w.uint16))]:
            memory[VF] = 1
          memory[GFXAddress(x + bias.uint16 + ((y + row.uint16) * ScreenSize.w.uint16))] = memory[GFXAddress(x + bias.uint16 + ((y + row.uint16) * ScreenSize.w.uint16))] xor true
    drawFlag = true
  of 0xE:
    case opcode.getNN
    of 0x9E: # EX9E -> Skips the next instruction if the key stored in VX is pressed. (Usually the next instruction is a jump to skip a code block);
      if keys[memory[vx]]: memory.skip()
    of 0xA1: # EXA1 -> Skips the next instruction if the key stored in VX is not pressed. (Usually the next instruction is a jump to skip a code block);
      if not keys[memory[vx]]: memory.skip()
    else: opcode.invalid
  of 0xF:
    case opcode.getNN
    of 0x07: memory[vx] = delayTimer
    of 0x0A:
      for idx in 0..<keys.len:
        if keys[idx]:
          memory[vx] = idx.uint8
          return
      memory.keepHere()
    of 0x15: delayTimer = memory[vx]
    of 0x18: soundTimer = memory[vx]
    of 0x1E: memory.I += memory[vx]
    of 0x33:
      memory[memory.I] = memory[vx] div 100
      memory[memory.I + 1'u] = (memory[vx] div 10) mod 10
      memory[memory.I + 2'u] = (memory[vx] mod 100) mod 10
    of 0x55: memory[memory.I] = memory[V0..vx]
    of 0x65: memory[V0] = memory[memory.I..memory.I + vx.uint]
    else: discard #opcode.invalid
  else: opcode.invalid

  if delayTimer != 0:
    delayTimer.dec
  if soundTimer != 0:
    soundTimer.dec
