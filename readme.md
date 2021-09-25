# Underburrow

Currently heavily in development, features the entire editor(Slingworks) and a single level.

This game is intended to be an all encompassing example for how Slingworks development works.

## About

- [Downloads](https://github.com/JonSnowbd/underburrow/releases)
- [Slingworks](https://github.com/JonSnowbd/slingworks)

For now Underburrow is exclusively windows, but will have a linux edition soon.

Underburrow is a speed running platformer game where you gather momentum with
well timed button taps 

Controls:
- A/D small hop, you can speed for each consecutive timed hop
- W converving momentum, jump very high but gain no speed
- S convert momentum into vertical height, and gain one token to redivert the speed into a direction
- R restart the level

## Building

- Install [Slingworks](https://github.com/JonSnowbd/slingworks) dependencies
- `zig build run`

## Creating levels

The main focus of Slingworks is providing a great editor for both developers and fans, and as such
this example comes with the full editor accessible in the binary, to access this simply run the binary
from your terminal with the editor argument like `./underburrow.exe editor`

### Something went wrong building?

Make sure you initialized all submodules with `git submodule update --init --recursive`

Make sure you have FMOD installed in its usual place in program files

Make sure you are using the latest 0.9 Zig release