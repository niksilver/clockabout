-- Testing the critical function within the main code.


require('clockabout')
metro = require('mock_metro')


-- We'll put these tests in a table to be able to use setUp() / tearDown()


TestSendPulse = {


  setUp = function()
    -- Replace the redraw() function

    TestSendPulse.redraw = redraw
    redraw = function() end
  end,


  tearDown = function()
    -- Restore the redraw() function

    redraw = TestSendPulse.redraw
  end,


  test_send_pulse_sends_25_pulses_when_60_bpm = function()

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
  end,


  test_sends_pulses_according_to_swing = function()
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

  end,


  test_sends_pulses_according_to_swing_over_3_beats = function()
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

  end,


  test_pattern_can_regenerate_after_end_of_pattern = function()
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

  end,


  test_first_pulse_of_pattern_starts_regularly = function()
    -- The first pulse should always be on the beat. E.g. with 60 bpm
    -- those first pulses should be 1 second apart.

    -- Run the metros as usual, and capture when the first pulse happens.

    _norns.init()
    metro.init_module()

    g = init_globals({
      pulse_num = 1,
      beat_num = 1,
      bpm = 60,

      pattern = random_pattern,
      pattern_length = 1,
    })

    random_pattern.init_pattern()

    local pulses = 0
    local pulse_times = {}

    -- Override the basic connection object

    g.connection = {
      clock = function(self)
        pulses = pulses + 1
        if (pulses-1) % 24 == 0 then
          local idx = (pulses // 24) + 1
          pulse_times[idx] = _norns.time
        end
      end,

      start = function(self) end,

      stop = function(self) end,
    }

    -- Run the metro for a bit over 5 'seconds', which will mean six first-pulses,
    -- at seconds 0, 1, 2, 3, 4, 5.

    start_pulses()

    for t = 0.0001, 5.1, 0.0001 do
      _norns.set_time(t)
    end

    -- Now see what we've got

    lu.assertEquals(#pulse_times, 6)

    for i = 1, #pulse_times-1 do
      local time1 = pulse_times[i]
      local time2 = pulse_times[i+1]
      lu.assertAlmostEquals(time2 - time1, 1.0, 0.01)
    end

  end,


  test_can_cycle_through_many_metros = function()
    -- Just to see if we're using the Metro module correctly.
    -- Can we use > 36 metros without a problem?

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
      clock = function(self) end,
      start = function(self) end,
      stop = function(self) end,
    }

    -- If we assume 4 metros per second (1 beat/sec at 60 bpm)
    -- then 12 seconds takes us through 48 metros.

    start_pulses()

    for t = 0, 12, 0.001 do
      _norns.set_time(t)
    end

  end,
}
