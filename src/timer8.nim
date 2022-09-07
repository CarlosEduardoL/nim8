import times, math

# CPU Cycle takes 1/60 of second
const MustTake*: float64 = 1'f64/60'f64

type Timer* = object
  acc: float64
  paused: bool

proc pulse*(t: var Timer, delta: float64): bool =
  if t.paused : return false
  t.acc += delta
  if t.acc >= MustTake:
    t.acc -= MustTake
    return true
  return false

proc pause*(t: var Timer) =
  t.paused = true

proc unpause*(t: var Timer) =
  t.paused = false