import godot

# Chip-8 has 4KB memory frame
const MemorySize = 0x1000
# Stack Size is >= 48B
const StackSize = 0x100
# CHIP-8 has 16 8-bit data registers named V0 to VF.
const RegistersCount = 16
# Original CHIP-8 Display resolution is 64×32 pixels, and color is monochrome
const ScreenSize* = (w: 64, h: 32)
const GFXMemorySize* = ScreenSize.w * ScreenSize.h
# FontSet
const FontSet: array[0..79, uint8] = [
  0xF0'u8, 0x90, 0x90, 0x90, 0xF0, # 0
  0x20'u8, 0x60, 0x20, 0x20, 0x70, # 1
  0xF0'u8, 0x10, 0xF0, 0x80, 0xF0, # 2
  0xF0'u8, 0x10, 0xF0, 0x10, 0xF0, # 3
  0x90'u8, 0x90, 0xF0, 0x10, 0x10, # 4
  0xF0'u8, 0x80, 0xF0, 0x10, 0xF0, # 5
  0xF0'u8, 0x80, 0xF0, 0x90, 0xF0, # 6
  0xF0'u8, 0x10, 0x20, 0x40, 0x40, # 7
  0xF0'u8, 0x90, 0xF0, 0x90, 0xF0, # 8
  0xF0'u8, 0x90, 0xF0, 0x10, 0xF0, # 9
  0xF0'u8, 0x90, 0xF0, 0x90, 0x90, # A
  0xE0'u8, 0x90, 0xE0, 0x90, 0xE0, # B
  0xF0'u8, 0x80, 0x80, 0x80, 0xF0, # C
  0xE0'u8, 0x90, 0x90, 0x90, 0xE0, # D
  0xF0'u8, 0x80, 0xF0, 0x80, 0xF0, # E
  0xF0'u8, 0x80, 0xF0, 0x80, 0x80] # F

type
  MemoryAddress* = range[0..MemorySize-1]
  RegisterIndex* = range[0..RegistersCount-1]
  GFXAddress* = range[0..GFXMemorySize]
  Opcode* = uint16

# All of the supported programs will start at memory location 0x200
const ProgramStartPoint*: MemoryAddress = 0x200

const V0*: RegisterIndex = RegisterIndex(0x0)
const VF*: RegisterIndex = RegisterIndex(0xF)

proc `+`*[I: MemoryAddress|RegisterIndex|GFXAddress, V: SomeInteger](i: I, v: V): I = I(uint(i) + uint(v))
proc `+`*[I: MemoryAddress|RegisterIndex|GFXAddress, V: SomeInteger](v: V, i: I): I = i + v

# Encapsulate memory access to avoid wrong access.
type
  Memory* = ref MemoryObj
  MemoryObj = object
    ram: array[MemorySize, uint8]
    keys*: array[16, bool]
    stack: array[StackSize, MemoryAddress]
    registers: array[RegistersCount, uint8]
    gfxMemory: array[GFXMemorySize, bool]

    addressRegister: MemoryAddress # It's really 12 bits but there is not a 12 bits type. <- I
    pc: MemoryAddress # Program Counter
    stackPointer: int16

# Fill Graphic buffer with false
proc clearGfxBuffer*(m: var Memory) =
  for idx in 0..<m.gfxMemory.len: m.gfxMemory[idx] = false

proc newMemory*(): Memory =
  result = Memory(addressRegister: MemoryAddress.low, pc: ProgramStartPoint)
  result.ram[0..<FontSet.len] = FontSet

proc `[]`*(m: var Memory, idx: MemoryAddress): var uint8 = m.ram[idx]
proc `[]`*(m: var Memory, idx: RegisterIndex): var uint8 = m.registers[idx]
proc `[]`*(m: var Memory, idx: GFXAddress): var bool = m.gfxMemory[idx]

proc `[]`*(m: Memory, idx: HSlice[MemoryAddress, MemoryAddress]): seq[uint8] = m.ram[idx]
proc `[]`*(m: Memory, idx: HSlice[RegisterIndex,RegisterIndex]): seq[uint8] = m.registers[idx]
proc `[]`*(m: Memory, idx: HSlice[GFXAddress,GFXAddress]): seq[bool] = m.gfxMemory[idx]

proc `[]=`*(m: var Memory, idx: MemoryAddress, data: openArray[uint8]) =
  m.ram[idx.int..<idx+data.len] = data
proc `[]=`*(m: var Memory, idx: RegisterIndex, data: openArray[uint8]) =
  m.registers[idx.int..<idx+data.len] = data
proc `[]=`*(m: var Memory, idx: GFXAddress, data: openArray[bool]) =
  m.gfxMemory[idx.int..<idx+data.len] = data

proc `[]=`*(m: var Memory, idx: MemoryAddress, data: uint8) =
  m.ram[idx] = data
proc `[]=`*(m: var Memory, idx: RegisterIndex, data: uint8) =
  m.registers[idx] = data
proc `[]=`*(m: var Memory, idx: GFXAddress, data: bool) =
  m.gfxMemory[idx] = data

# Get Opcode
proc fetch*(m: var Memory): Opcode =
  result = (Opcode(m[m.pc]) shl 8) or (m[m.pc + 1'u])
  inc(m.pc, 2)

# Change Program counter to a new Memory Address
proc jump*(m: var Memory, add: MemoryAddress) =
  m.pc = add

# Dec Program counter to repeat the same instruction in the nex cpu cycle
proc keepHere*(m: var Memory) = dec(m.pc, 2)

# Inc Program counter to skip the next instruction
proc skip*(m: var Memory) = inc(m.pc, 2)

# Pop Stack
proc pop*(m: var Memory) =
  if m.stackPointer == 0:
    printError "[FATAL] Cannot return on an empty stack"
    quit 1
  m.pc = m.stack[m.stackPointer - 1]
  dec(m.stackPointer)

# Push current program counter to stack
proc push*(m: var Memory) =
  m.stack[m.stackPointer] = m.pc
  inc(m.stackPointer)

proc I*(m: var Memory): var MemoryAddress = m.addressRegister