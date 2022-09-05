# nim8

A Chip-8 Emulator written in [Nim](https://nim-lang.org)

Basic Chip-8 Emulator based on [this guide](https://multigesture.net/articles/how-to-write-an-emulator-chip-8-interpreter/) and using [DSL2](https://wiki.libsdl.org/Introduction) for the graphics

## Interesting links

[Chip-8 Wikipedia page](https://en.wikipedia.org/wiki/CHIP-8)
[Chip-8 Design Specification](http://www.cs.columbia.edu/~sedwards/classes/2016/4840-spring/designs/Chip8.pdf)

## TODO

- [ ]  Implement Sound
- [ ]  Implement better timer
- [ ]  Improve Case Statement (It's really too big)
- [ ]  Manage Carry flag
- [ ]  Implement super Chip-8 Opcodes and extended memory layout 

## Build instructions:

- ### Download [Nim](https://nim-lang.org)
  - On windows you can use scoop or any other package manager
  - On unix systems use [choosenim](https://github.com/dom96/choosenim)
- ### Download the dependencies using nimble: ```nimble install```
- ### Generate the exe using nimble: ```nimble build```
- ### Finally put the executable next to the SDL2.dll on Windows or install SDL2 on your system using your distribution package manager

## Run Instructions

```shell
./nim8 /path/to/rom
```

## Keymap

### The chip-8 keyboard was mapped to the following keys:

| Chip-8 Key | Nim-8 Key |
|:----------:|:---------:|
| 1          | 1         |
| 2          | 2         |
| 3          | 3         |
| C          | 4         |
| 4          | Q         |
| 5          | W         |
| 6          | E         |
| D          | R         |
| 7          | A         |
| 8          | S         |
| 9          | D         |
| E          | F         |
| A          | Z         |
| 0          | X         |
| B          | C         |
| F          | V         |

## ROMS
You can download roms from [here](https://johnearnest.github.io/chip8Archive/)

## License

[![License](http://img.shields.io/:license-mit-blue.svg?style=flat-square)](http://badges.mit-license.org)

- **[MIT license](http://opensource.org/licenses/mit-license.php)**