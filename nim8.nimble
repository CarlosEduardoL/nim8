# Package

version       = "0.1.1"
author        = "Carlos Eduardo Lizalda Valencia"
description   = "A Chip-8 Emulator"
license       = "MIT"
srcDir        = "src"
bin           = @["nim8"]


# Dependencies

requires "nim >= 1.6.6"
requires "sdl2_nim"