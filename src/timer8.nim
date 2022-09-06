import times, math

# CPU Cycle takes 1/60 of second
const MustTake*: float64 = 1'f64/60'f64

type Timer* = object
  startTime: float64
  debt: float64

proc initTimer*(): Timer =
  result.startTime = cpuTime()

proc getDelay*(t: var Timer): int =
  let elapsed = cpuTime() - t.startTime
  t.startTime = cpuTime()
  if elapsed > MustTake:
    t.debt = elapsed - MustTake
    return 0
  let delay = MustTake - elapsed
  if delay >= t.debt:
    t.debt = 0
    return ((delay - t.debt) * 1000).round().int
  else:
    t.debt -= delay
    return 0