import strutils, strformat
import os, std/random
import godot

import memory8

type
  CPU* = ref CPUObject
  CPUObject = object
    memory*: Memory
    delayTimer: uint8
    soundTimer: uint8
    drawFlag*: bool

proc initCPU*(mem: var Memory): CPU =
  result = CPU()
  randomize() # Init Random module
  result.memory = mem

# convert the 12 less significant bits on a MemoryAddress
proc getAddress(opcode: Opcode): MemoryAddress = opcode and 0x0FFF

proc getNN(opcode: Opcode): uint8 = (opcode and 0x00FF).uint8

proc invalid(opcode: Opcode) {.inline, noreturn.} =
  printError fmt"[FATAL] invalid opcode {opcode.toHex}"
  #quit 1

proc cycle*(cpu: var CPU): bool =
  var opcode: Opcode = cpu.memory.fetch()
  let vx: RegisterIndex = (opcode and 0x0F00) shr 8
  let vy: RegisterIndex = (opcode and 0x00F0) shr 4
  case (opcode shr 12).uint8 # https://en.wikipedia.org/w/index.php?title=CHIP-8
  of 0x0:
    if opcode == 0x00E0: cpu.memory.clearGfxBuffer() # 00E0 -> Clears the screen.
    elif opcode == 0x00EE: cpu.memory.pop() # 00EE -> Returns from a subroutine.
    else: opcode.invalid
  of 0x1: cpu.memory.jump opcode.getAddress # 1NNN -> Jumps to address NNN.
  of 0x2: # 2NN -> 	Calls subroutine at NNN.
    cpu.memory.push() # Saves the current program counter on the stack
    cpu.memory.jump opcode.getAddress
  of 0x3:
    # 3XNN -> Skips the next instruction if VX equals NN. (Usually the next instruction is a jump to skip a code block);
    if cpu.memory[vx] == opcode.getNN: cpu.memory.skip()
  of 0x4:
    # 4XNN ->	Skips the next instruction if VX does not equal NN. (Usually the next instruction is a jump to skip a code block);
    if cpu.memory[vx] != opcode.getNN: cpu.memory.skip()
  of 0x5:
    # 5XY0 -> Skips the next instruction if VX equals VY. (Usually the next instruction is a jump to skip a code block);
    if (opcode and 0x000F) != 0: opcode.invalid
    if cpu.memory[vx] == cpu.memory[vy]: cpu.memory.skip()
  of 0x6: cpu.memory[vx] = opcode.getNN  # 6XNN -> Sets VX to NN.
  of 0x7: cpu.memory[vx] += opcode.getNN # 7XNN -> Adds NN to VX. (Carry flag is not changed);
  of 0x8:
    case (opcode and 0x000F)
    of 0x0: cpu.memory[vx] = cpu.memory[vy] # 8XY0 -> Sets VX to the value of VY.
    of 0x1: cpu.memory[vx] = cpu.memory[vy] or  cpu.memory[vx] # 0XY1 -> Sets VX to VX or VY. (Bitwise OR operation);
    of 0x2: cpu.memory[vx] = cpu.memory[vy] and cpu.memory[vx] # 0XY2 -> Sets VX to VX and VY. (Bitwise AND operation);
    of 0x3: cpu.memory[vx] = cpu.memory[vy] xor cpu.memory[vx] # 0XY3 -> Sets VX to VX xor VY.
    of 0x4: cpu.memory[vx] += cpu.memory[vy] # 0XY4 -> Adds VY to VX. VF is set to 1 when there's a carry, and to 0 when there is not.
    of 0x5: cpu.memory[vx] -= cpu.memory[vy] # 0XY5 -> VY is subtracted from VX. VF is set to 0 when there's a borrow, and 1 when there is not.
    of 0x6: # 0XY6 -> Stores the least significant bit of VX in VF and then shifts VX to the right by 1.
      cpu.memory[VF] = cpu.memory[vx] and 0x01
      cpu.memory[vx] = cpu.memory[vx] shr 1
    of 0x7: # 0XY7 -> Sets VX to VY minus VX. VF is set to 0 when there's a borrow, and 1 when there is not.
      cpu.memory[vx] = cpu.memory[vy] - cpu.memory[vx]
    of 0xE: # 0XYE -> Stores the most significant bit of VX in VF and then shifts VX to the left by 1.
      cpu.memory[VF] = cpu.memory[vx] and 0x80
      cpu.memory[vx] = cpu.memory[vx] shl 1
    else: opcode.invalid
  of 0x9: # 9XY0 -> Skips the next instruction if VX does not equal VY. (Usually the next instruction is a jump to skip a code block);
    if (opcode and 0x000F) != 0: opcode.invalid
    if cpu.memory[vy] != cpu.memory[vx]: cpu.memory.skip()
  of 0xA: # ANNN -> Sets I to the address NNN.
    cpu.memory.I() = opcode.getAddress
  of 0xB: # BNNN -> Jumps to the address NNN plus V0.
    cpu.memory.jump cpu.memory[V0] + opcode.getAddress
  of 0xC: # CXNN -> Sets VX to the result of a bitwise and operation on a random number (Typically: 0 to 255) and NN.
    cpu.memory[vx] = rand(255).uint8 and opcode.getNN
  of 0xD:
    # DXYN -> Draws a sprite at coordinate (VX, VY) that has a width of 8 pixels and a height of N pixels.
    #         Each row of 8 pixels is read as bit-coded starting from memory location I; I value does not change after the execution of this instruction. As described above, VF is set to 1 if any screen pixels are flipped from set to unset when the sprite is drawn, and to 0 if that does not happen
    let x = cpu.memory[vx]
    let y = cpu.memory[vy]
    let height = opcode and 0x000F
    cpu.memory[VF] = 0
    for row in 0.uint16..<height:
      let line = cpu.memory[cpu.memory.I + row]
      for bias in 0..<8:
        if (line and (0x80.uint8 shr bias)) != 0:
          if cpu.memory[GFXAddress(x + bias.uint16 + ((y + row.uint16) * ScreenSize.w.uint16))]:
            cpu.memory[VF] = 1
          cpu.memory[GFXAddress(x + bias.uint16 + ((y + row.uint16) * ScreenSize.w.uint16))] = cpu.memory[GFXAddress(x + bias.uint16 + ((y + row.uint16) * ScreenSize.w.uint16))] xor true
    cpu.drawFlag = true
  of 0xE:
    case opcode.getNN
    of 0x9E: # EX9E -> Skips the next instruction if the key stored in VX is pressed. (Usually the next instruction is a jump to skip a code block);
      if cpu.memory.keys[cpu.memory[vx]]: cpu.memory.skip()
    of 0xA1: # EXA1 -> Skips the next instruction if the key stored in VX is not pressed. (Usually the next instruction is a jump to skip a code block);
      if not cpu.memory.keys[cpu.memory[vx]]: cpu.memory.skip()
    else: opcode.invalid
  of 0xF:
    case opcode.getNN
    of 0x07: cpu.memory[vx] = cpu.delayTimer
    of 0x0A:
      for idx in 0..<cpu.memory.keys.len:
        if cpu.memory.keys[idx]:
          cpu.memory[vx] = idx.uint8
          return false
      cpu.memory.keepHere()
    of 0x15: cpu.delayTimer = cpu.memory[vx]
    of 0x18: cpu.soundTimer = cpu.memory[vx]
    of 0x1E: cpu.memory.I += cpu.memory[vx]
    of 0x33:
      cpu.memory[cpu.memory.I] = cpu.memory[vx] div 100
      cpu.memory[cpu.memory.I + 1'u] = (cpu.memory[vx] div 10) mod 10
      cpu.memory[cpu.memory.I + 2'u] = (cpu.memory[vx] mod 100) mod 10
    of 0x55: cpu.memory[cpu.memory.I] = cpu.memory[V0..vx]
    of 0x65: cpu.memory[V0] = cpu.memory[cpu.memory.I..cpu.memory.I + vx.uint]
    else: discard #opcode.invalid
  else: opcode.invalid

  if cpu.delayTimer != 0:
    cpu.delayTimer.dec
  if cpu.soundTimer != 0:
    cpu.soundTimer.dec
    return true
  return false