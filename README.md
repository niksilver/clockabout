# Clockabout

A non-linear MIDI clock for monome norns - why should
swing be the only non-linear time pattern?

## How to use it

In the norns PARAMS menu select which MIDI device the script will send its
clock signal to.

- E1: Select pattern.
- E2: Change BPM.
- E3: Pattern-specific param.
- K1+E3: Second pattern param (for some patterns only).
- K3: Start/stop the clock.

The PARAMS menu also allows you to change how many beats the pattern
lasts for.


## Misc notes

A MIDI start/stop message is sent when, and only when, the clock starts and stops
(K3, or via the PARAMS menu).
Just changing which MIDI device receives the clock
will route (or stop routing) the clock messages to that device,
but won't send a MIDI start/stop message.

The script will load the last saved PSET on startup.

The on-screen graph may or may not mean what you think it means. A more shallow
line means faster ticks; a steeper line means slower ticks. This is because
the x-axis is standard time and the y-axis is pattern time. For example,
to know where the middle tick occurs in the beat we look at the mid-point
of the x-axis. If the y value is below the middle of y-axis (i.e. a smaller
y value, meaning less time) then the tick occurs sooner.

Beats sync on the first clock pulse of the pattern.
For example, consider a pattern of length one beat, at 60 BPM. This will send
24 pulses per second (because MIDI clocks must send 24 pulses per beat, and
60 BPM means one beat per second).
Those pulses may be spaced irregularly, but the first of those 24 pulses
will always be 1 second apart. As a more complicated example,
consider a pattern of also at 60 BPM, but with length 4 beats. This will still
send 24 pulses per second, and there will be 96 beats across the whole pattern
(96 = 4 * 24), but the first of these 96 beats will always be 4 seconds apart.

It's about 3/1000 of a second out each beat. Internally, some processing
between ticks takes a bit of time and adds delay. This means that when we
said above that an example pattern's first pulse each was 1 second apart,
it's really 1.003 seconds on average. I hope that's not to important to
most people.

The pattern may not be entirely smooth. The on-screen graph might sometimes
look like a curve, but internally the curve is broken into six linear
segments, and ticks are sent according to that. I am assuming that the
difference will be inaudible... or at least excusable.


## Development and testing

To run the tests just execute

```
lua lib/test_clockabout.lua
```
or
```
make test
```

The tests are in the lib directory so that they don't show up in norns'
SELECT menu.


## Thank you!

Thanks to all those who have...
