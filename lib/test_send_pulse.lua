-- Testing the critical function within the main code.


require('clockabout')
metro = require('mock_metro')


function test_send_pulse_sends_25_pulses_when_60_bpm()
  -- Should send 25 pulses per beat at 60 bpm
  -- because it's 24 per beat, but we're also including
  -- a pulse at second 0.

  _norns.init()
  metro.init_module()

  g = init_globals({
    pulse_num = 1,
    beat_num = 1,
    bpm = 60,

    pattern = linear_pattern,
    pattern_length = 1,
  })

  local pulses = 0

  -- Override the basic connection object

  g.connection = {
    clock = function(self)
      pulses = pulses + 1
    end,

    start = function(self) end,

    stop = function(self) end,
  }

  -- Start the pulses and run the pretend clock for 1 second,
  -- with a resolution of 0.01 seconds.

  start_pulses()

  for t = 0, 1.0001, 0.01 do
    _norns.set_time(t)
  end

  lu.assertEquals(pulses, 25)
end


function test_sends_pulses_according_to_swing()
  slog('- - - - - - - - - - -')

  _norns.init()
  metro.init_module()

  g = init_globals({
    pulse_num = 1,
    beat_num = 1,
    bpm = 60,

    pattern = swing_pattern,
    pattern_length = 1,
  })

  swing_pattern.swing = 0.25
  swing_pattern.inflection = 0.50
  swing_pattern.init_pattern()

  local pulses = 0

  -- Override the basic connection object

  g.connection = {
    clock = function(self)
      pulses = pulses + 1
      slog('  Clock: %f\tpulse %d', _norns.time, pulses)
    end,

    start = function(self) end,

    stop = function(self) end,
  }

  -- When we start the pulses and move through time we should get
  -- 13 pulses in the first 0.25 seconds, and the rest
  -- in the remaining time.
  --
  -- Remember: 25 pulses in total, because there's one each at 0.0 and 1.0 seconds.

  start_pulses()

  for t = 0.01, 0.25001, 0.0001 do -- Start running time from after second 0.
    _norns.set_time(t)
  end
  u.assertEquals(pulses, 13)

  for t = 0.26, 1.0001, 0.01 do -- Continue the clock
    _norns.set_time(t)
  end
  lu.assertEquals(pulses, 25)
  slog('- - - - - - - - - - -')

end
