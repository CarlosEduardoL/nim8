# Copyright 2017 Xored Software, Inc.
when not defined(release):
  import segfaults # converts segfaults into NilAccessError

import chip8
import video8