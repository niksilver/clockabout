# Clockabout

An irregular MIDI clock for monome norns - why should
shuffle be the only irregular time pattern?

## Misc notes

- MIDI start/stop. Is it any use?

# Development and testing

To run the test just execute

```
lua lib/test_clockabout.lua
```

They're in the lib directory so that they don't show up in norns's
SELECT menu.

The `push.sh` script is just for pushing this code directly to the norns.
