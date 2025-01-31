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
  -- in the remaining time. We'll allow some time overrun to cater
  -- for imperfections in the small steps and precision errors.
  --
  -- Remember: 25 pulses in total, because there's one each at 0.0 and 1.0 seconds.

  start_pulses()

  for t = 0.0001, 0.2501, 0.0001 do -- Start running time from after second 0.
    _norns.set_time(t)
  end
  lu.assertEquals(pulses, 13)

  for t = 0.2502, 1.0005, 0.0001 do -- Continue the clock
    _norns.set_time(t)
  end
  lu.assertEquals(pulses, 25)

end


function test_sends_pulses_according_to_swing_over_3_beats()
  _norns.init()
  metro.init_module()

  g = init_globals({
    pulse_num = 1,
    beat_num = 1,
    bpm = 60,

    pattern = swing_pattern,
    pattern_length = 3,
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
  -- 3*12+1 pulses in the first 3*0.25 seconds, and the rest
  -- in the remaining time. We'll allow some time overrun to cater
  -- for imperfections in the small steps and precision errors.
  --
  -- Remember: 3*24+1 pulses in total, because there's one each at 0.0 and 1.0 seconds.

  start_pulses()

  for t = 0.0001, 3*0.2502, 0.0001 do -- Start running time from after second 0.
    _norns.set_time(t)
  end
  lu.assertEquals(pulses, 3*12+1)

  for t = 3*0.2502, 3*1.0005, 0.0001 do -- Continue the clock
    _norns.set_time(t)
  end
  lu.assertEquals(pulses, 3*24+1)

end


function test_pattern_can_regenerate_after_end_of_pattern()
  slog('- - - - - - - - - - - - - - - - -')

  -- Make our own pattern, like random, but with our own regenerate()
  -- which checks that it's been called

  local regenerate_called = false

  local our_pattern = {}
  for k, v in pairs(random_pattern) do
    our_pattern[k] = random_pattern[k]
  end

  our_pattern.regenerate = function()
    regenerate_called = true
  end

  -- Now run the metros as usual

  _norns.init()
  metro.init_module()

  g = init_globals({
    pulse_num = 1,
    beat_num = 1,
    bpm = 60,

    pattern = our_pattern,
    pattern_length = 1,
  })

  our_pattern.init_pattern()

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

  -- Just to be sure, check we get 25 pulses.

  start_pulses()

  for t = 0.0001, 1.0005, 0.0001 do -- Start running time from after second 0.
    _norns.set_time(t)
  end
  lu.assertEquals(pulses, 25)

  -- Now the real test.

  lu.assertEquals(regenerate_called, true)

end
