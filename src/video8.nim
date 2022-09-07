import godot
import godotapi/[tile_map, engine]

import chip8
import memory8

gdobj Video of TileMap:
  var emu: Emulator

  method ready*() =
    self.emu = self.getNode("/root/Emulator".newNodePath) as Emulator

  method process*(delta: float) =
    if self.emu.memory == nil: return
    for idx in 0..<GFXMemorySize:
      let tile = if self.emu.memory[idx.GFXAddress]: 1 else: 0
      let x = idx mod ScreenSize.w
      let y = idx div ScreenSize.w
      self.setCell(x, y, tile)