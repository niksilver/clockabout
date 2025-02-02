# Clockabout

A non-linear MIDI clock for monome norns - why should
swing be the only non-linear time pattern?

## How to use it

In the norns PARAMS menu select which MIDI device the script will send its
clock signal to.

- E1: Select pattern
- E2: Change BPM
- E3: Pattern-specific param
- K1+E3: Second pattern param (for some patterns only)
- K3: Start/stop metro

The PARAMS menu also allows you to change how many beats the pattern
lasts for.


## Misc notes

- MIDI start/stop happens.
- It's a quirk that beats come together on the 24th pulse.
- Graph is probably not what you think it is.
- It's about 3/1000 of a second out.

# Development and testing

To run the tests just execute

```
lua lib/test_clockabout.lua
```

The tests are in the lib directory so that they don't show up in norns's
SELECT menu.

The `push.sh` script is just for pushing this code directly to the norns.
