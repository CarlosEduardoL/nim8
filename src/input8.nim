import sdl2_nim/sdl

# Input is done with a hex keyboard that has 16 keys ranging 0 to F
const KeyCount = 16

# Map the Chip-8 Keyboard to an usual keyboard
const KeyMap = 
  [K_1, K_2, K_3, K_4,
   K_q, K_w, K_e, K_r,
   K_a, K_s, K_d, K_f,
   K_z, K_x, K_c, K_v,]

var keys*: array[KeyCount, bool]

# Manage SDL Events (key pressed/released and close)
proc manageEvents*() =
  var event: Event
  while pollEvent(event.addr) != 0:
    case event.kind:
    of QUIT: quit 0
    of KEYDOWN, KEYUP:
      for idx in 0..<KeyMap.len:
        if KeyMap[idx] == event.key.keysym.sym: keys[idx] = event.kind == KEYDOWN
    else: discard