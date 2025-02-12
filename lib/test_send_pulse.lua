-- Testing the critical function within the main code.


local m     = require('mod')
metro = require('mock_metro')


-- We'll put these tests in a table to be able to use setUp() / tearDown()


TestSendPulse = {


  setUp = function()
    -- Replace the redraw() function

    TestSendPulse.redraw = m.redraw
    m.redraw = function() end

    -- Save the pulse_interval() function if we need to restore it

    TestSendPulse.pulse_interval = m.pulse_interval
  end,


  tearDown = function()
    -- Restore the saved functions

    m.redraw = TestSendPulse.redraw
    m.pulse_interval = TestSendPulse.pulse_interval
  end,


  test_send_pulse_sends_25_pulses_when_60_bpm = function()

    -- Should send 25 pulses per beat at 60 bpm
    -- because it's 24 per beat, but we're also including
    -- a pulse at second 0.

    _norns.init()
    metro.init_module()

    g = m.init_globals({
      pulse_num = 1,
      beat_num = 1,
      bpm = 60,

      pattern = linear_pattern,
      pattern_length = 1,
    })

    local pulses = 0

    -- Create a mock connection in a mock MIDI device

    g.devices = {
      {
        name = 'Mock device',

        active = 1,

        connection = {

          clock = function(self)
            pulses = pulses + 1
          end,

          start = function(self) end,

          stop = function(self) end,
        }
      }
    }

    -- Start the pulses and run the pretend clock for 1 second,
    -- with a resolution of 0.001 seconds.

    m.start_pulses()

    for t = 0, 1.005, 0.001 do
      _norns.set_time(t)
    end

    lu.assertEquals(pulses, 25)
  end,


  test_sends_pulses_according_to_swing = function()
    _norns.init()
    metro.init_module()

    g = m.init_globals({
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

    -- Create a mock connection in a mock MIDI device

    g.devices = {
      {
        name = 'Mock device',

        active = 1,

        connection = {

          clock = function(self)
            pulses = pulses + 1
          end,

          start = function(self) end,

          stop = function(self) end,
        }
      }
    }

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

    m.start_pulses()

    for t = 0.0001, 0.2505, 0.0001 do -- Start running time from after second 0.
      _norns.set_time(t)
    end
    lu.assertEquals(pulses, 13)

    for t = 0.2506, 1.0005, 0.0001 do -- Continue the clock
      _norns.set_time(t)
    end
    lu.assertEquals(pulses, 25)

  end,


  test_sends_pulses_according_to_swing_over_3_beats = function()
    _norns.init()
    metro.init_module()

    g = m.init_globals({
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

    -- Create a mock connection in a mock MIDI device

    g.devices = {
      {
        name = 'Mock device',

        active = 1,

        connection = {

          clock = function(self)
            pulses = pulses + 1
          end,

          start = function(self) end,

          stop = function(self) end,
        }
      }
    }

    -- When we start the pulses and move through time we should get
    -- 3*12+1 pulses in the first 3*0.25 seconds, and the rest
    -- in the remaining time. We'll allow some time overrun to cater
    -- for imperfections in the small steps and precision errors.
    --
    -- Remember: 3*24+1 pulses in total, because there's one each at 0.0 and 1.0 seconds.

    m.start_pulses()

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

    g = m.init_globals({
      pulse_num = 1,
      beat_num = 1,
      bpm = 60,

      pattern = our_pattern,
      pattern_length = 1,
    })

    our_pattern.init_pattern()

    local pulses = 0

    -- Create a mock connection in a mock MIDI device

    g.devices = {
      {
        name = 'Mock device',

        active = 1,

        connection = {

          clock = function(self)
            pulses = pulses + 1
          end,

          start = function(self) end,

          stop = function(self) end,
        }
      }
    }

    -- Just to be sure, check we get 25 pulses.

    m.start_pulses()

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

    g = m.init_globals({
      pulse_num = 1,
      beat_num = 1,
      bpm = 60,

      pattern = random_pattern,
      pattern_length = 1,
    })

    random_pattern.init_pattern()

    local pulses = 0
    local pulse_times = {}

    -- Create a mock connection in a mock MIDI device

    g.devices = {
      {
        name = 'Mock device',

        active = 1,

        connection = {

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
      }
    }
    -- Run the metro for a bit over 5 'seconds', which will mean six first-pulses,
    -- at seconds 0, 1, 2, 3, 4, 5.

    m.start_pulses()

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

    g = m.init_globals({
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

    m.start_pulses()

    for t = 0, 12, 0.001 do
      _norns.set_time(t)
    end

  end,


  test_parts_are_at_correct_points = function()
    -- When we calculate the pulse intervals for each part, those parts
    -- should be each start at the correct point.

    -- Run the metros as usual, and capture when the first pulse happens.

    _norns.init()
    metro.init_module()

    g = m.init_globals({
      PULSES_PP = 4,  -- We set this to be sure, for calculations further down.
      pulse_num = 1,
      beat_num = 1,
      bpm = 60,

      pattern = random_pattern,
      pattern_length = 1,
    })

    random_pattern.init_pattern()

    -- Create a mock connection in a mock MIDI device

    g.devices = {
      {
        name = 'Mock device',

        active = 1,

        connection = {
          clock = function(self) end,
          start = function(self) end,
          stop = function(self) end,
        }
      }
    }

    -- Wrap the pulse_interval() function to check that we're making
    -- our calculations from the correct points. The tearDown() function
    -- will restore our override.

    local from_pulse = {}
    local orig_pulse_interval = m.pulse_interval

    m.pulse_interval = function(pulse_num, beat_num)
      from_pulse[#from_pulse+1] = pulse_num
      return orig_pulse_interval(pulse_num, beat_num)
    end

    m.start_pulses()

    for t = 0.0001, 5.1, 0.0001 do
      _norns.set_time(t)
    end

    -- Now see what we've got

    -- Initial pulse should be manually sent from start_pulses
    lu.assertEquals(from_pulse[1],  1)  -- First interval should be calculated from 1 to 5
    lu.assertEquals(from_pulse[2],  5)  -- Next interval should be calculated from 5 to 9
    lu.assertEquals(from_pulse[3],  9)  -- Next interval should be calculated from 9 to 13
    lu.assertEquals(from_pulse[4], 13)  -- Next interval should be calculated from 13 to 17
    lu.assertEquals(from_pulse[5], 17)  -- Next interval should be calculated from 17 to 21
    lu.assertEquals(from_pulse[6], 21)  -- Next interval should be calculated from 21 to 25

    -- Then again for the second beat
    lu.assertEquals(from_pulse[7],   1)  -- First interval should be calculated from 1 to 5
    lu.assertEquals(from_pulse[8],   5)  -- Next interval should be calculated from 5 to 9
    lu.assertEquals(from_pulse[9],   9)  -- Next interval should be calculated from 9 to 13
    lu.assertEquals(from_pulse[10], 13)  -- Next interval should be calculated from 13 to 17
    lu.assertEquals(from_pulse[11], 17)  -- Next interval should be calculated from 17 to 21
    lu.assertEquals(from_pulse[12], 21)  -- Next interval should be calculated from 21 to 25

  end,
}
