-- To run these tests just go to this directory and run
-- lua test_clockabout.lua
-- or from the parent directory run
-- lua lib/test_clockabout.lua

-- Allow packages to be picked up from both this directory
-- and its parent directory

package.path = package.path .. ";../?.lua;lib/?.lua"

lu = require('luaunit')
require('clockabout')

g = {}

-- calc_interval for linear pattern -------------------------------------

function test_calc_interval_60_bpm()
  g = init_globals({
    bpm = 60,
    pulse_num = 1,
    pulse_total = 0,
  })

  local beat_dur_sec = 60 / g.bpm
  local expected_interval = beat_dur_sec / 24

  lu.assertAlmostEquals( calc_interval(g.pulse_num), expected_interval, 0.01 )
end

function test_calc_interval_60_bpm_in_middle_of_bar()
  g = init_globals({
    bpm = 60,
    pulse_num = 17,
    pulse_total = 16 + 96,
  })

  local beat_dur_sec = 60 / g.bpm
  local expected_interval = beat_dur_sec / 24

  lu.assertAlmostEquals( calc_interval(g.pulse_num), expected_interval, 0.01 )
end

function test_calc_interval_60_bpm_in_middle_of_bar_3_beats_per_bar()
  g = init_globals({
    bpm = 60,
    pulse_num = 17,
    pulse_total = 16 + 96,
  })

  local beat_dur_sec = 60 / g.bpm
  local expected_interval = beat_dur_sec / 24

  lu.assertAlmostEquals( calc_interval(g.pulse_num), expected_interval, 0.01 )
end

function test_calc_interval_120_bpm()
  g = init_globals({
    bpm = 120,
    pulse_num = 1,
    pulse_total = 0,
  })

  local beat_dur_sec = 60 / g.bpm
  local expected_interval = beat_dur_sec / 24

  lu.assertAlmostEquals( calc_interval(g.pulse_num), expected_interval, 0.01 )
end

-- transform for swing pattern -------------------------------------

function test_transform_for_swing_pattern_50pc_swing()
  swing_pattern.swing = 0.50
  swing_pattern.init_pattern()

  lu.assertAlmostEquals( swing_pattern.transform(0.00), 0,    0.001 )
  lu.assertAlmostEquals( swing_pattern.transform(0.25), 0.25, 0.001 )
  lu.assertAlmostEquals( swing_pattern.transform(0.50), 0.50, 0.001 )
  lu.assertAlmostEquals( swing_pattern.transform(0.75), 0.75, 0.001 )
  lu.assertAlmostEquals( swing_pattern.transform(1.00), 1.0,  0.001 )
end

function test_transform_for_swing_pattern_75pc_swing()
  swing_pattern.swing = 0.75
  swing_pattern.init_pattern()

  lu.assertAlmostEquals( swing_pattern.transform(0.00), 0,     0.001 )
  lu.assertAlmostEquals( swing_pattern.transform(0.25), 0.375, 0.001 )
  lu.assertAlmostEquals( swing_pattern.transform(0.50), 0.75,  0.001 )
  lu.assertAlmostEquals( swing_pattern.transform(0.75), 0.875, 0.001 )
  lu.assertAlmostEquals( swing_pattern.transform(1.00), 1.0,   0.001 )
end

function test_transform_for_swing_pattern_10pc_swing()
  swing_pattern.swing = 0.10
  swing_pattern.init_pattern()

  lu.assertAlmostEquals( swing_pattern.transform(0.00), 0,    0.001 )
  lu.assertAlmostEquals( swing_pattern.transform(0.25), 0.05, 0.001 )
  lu.assertAlmostEquals( swing_pattern.transform(0.50), 0.10, 0.001 )
  local y = (0.9/0.5) * 0.25 + 0.1
  lu.assertAlmostEquals( swing_pattern.transform(0.75), y,    0.001 )
  lu.assertAlmostEquals( swing_pattern.transform(1.00), 1.0,  0.001 )
end

-- calc_interval for swing pattern -------------------------------------

function test_calc_interval_swing_60_bpm_in_middle_of_bar()
  g = init_globals({
    bpm = 60,
    pattern = swing_pattern,
    pattern_length = 1,
    beat_num = 1,
  })

  -- Assume we're on pulse 14 of 24 (so over halfway) on the 5th beat.
  -- So pulse 15 is the next one.
  -- We rely on the transform() function, as we've tested that above.

  g.pulse_num = 15
  g.pulse_total = 4 * 24 + g.pulse_num - 1

  swing_pattern.swing = 0.10
  swing_pattern.init_pattern()

  local y_start = swing_pattern.transform((g.pulse_num-1) / 24)
  local y_end = swing_pattern.transform((g.pulse_num - 1 + g.PULSES_PP) / 24)

  local beat_duration = 60 / g.bpm  -- Also the scale for calculating duration

  local expected_pulse_duration = (y_end - y_start) / g.PULSES_PP * beat_duration

  lu.assertAlmostEquals( calc_interval(g.pulse_num), expected_pulse_duration, 0.001 )
end

-- Not really a test... just a way to print out pulses and visually check them
--
function pulse_printing_function()
  g = init_globals({
    bpm = 60,
    pattern = swing_pattern,
    pattern_length = 3,    -- Pattern length 2
    beat_num = 1,
  })

  swing_pattern.swing = 0.79
  swing_pattern.init_pattern()

  g.beat_num = 1
  g.pulse_num = 1
  g.pulse_total = 0

  print()
  local time = 0
  for beat = 1, 6 do
    g.beat_num = beat
    for next_pulse = 1,24,6 do
      local interval = calc_interval(next_pulse)
      for pulse = next_pulse, next_pulse+5 do
        print(beat ..", ".. pulse ..", ".. time)
        time = time + interval
      end
    end
  end
  print(time)

end

function test_calc_interval_swing_60_bpm_in_middle_of_bar_pattern_length_2()
  g = init_globals({
    bpm = 60,
    pattern = swing_pattern,
    pattern_length = 2,    -- Pattern length 2
    beat_num = 1,
  })

  swing_pattern.swing = 0.10
  swing_pattern.init_pattern()

  -- Assume we're on pulse 14 of 24 of the 3rd beat, so that's the 1st
  -- beat in a two-beat pattern.
  -- And that means pulse 15 is the next one.

  g.beat_num = 1
  g.pulse_num = 15
  g.pulse_total = 2 * 24 + g.pulse_num - 1

  local x_start_normally = (g.pulse_num-1) / 24
  -- Scale down for first beat of two
  local x_start_scaled = x_start_normally / g.pattern_length
  local y_start = swing_pattern.transform(x_start_scaled)

  local x_end_normally = (g.pulse_num - 1 + g.PULSES_PP) / 24
  -- Scale down for first beat of two
  local x_end_scaled = x_end_normally / g.pattern_length
  local y_end = swing_pattern.transform(x_end_scaled)

  local beat_duration = 60 / g.bpm  -- Also the scale for calculating duration

  local expected_pulse_duration = (y_end - y_start) / g.PULSES_PP * beat_duration
  -- Scale up for multi-beat pattern
  local expected_pulse_duration_scaled = expected_pulse_duration * g.pattern_length

  lu.assertAlmostEquals( calc_interval(g.pulse_num), expected_pulse_duration_scaled, 0.001 )

  -- Now let's do similar, but for the 2nd beat in a two-beat pattern.
  -- This is just like the last one, but the x start and end are further along.

  -- Assume we're on pulse 14 of 24 of the 4th beat, so that's the 2st
  -- beat in a two-beat pattern.
  -- And that means pulse 15 is the next one.

  g.beat_num = 2
  g.pulse_num = 15
  g.pulse_total = 3 * 24 + g.pulse_num - 1

  local x_start_normally = (g.pulse_num-1) / 24
  -- Scale down and shift across for second beat of two
  local x_start_scaled = x_start_normally / g.pattern_length + 0.5
  local y_start = swing_pattern.transform(x_start_scaled)

  local x_end_normally = (g.pulse_num - 1 + g.PULSES_PP) / 24
  -- Scale down and shift across for second beat of two
  local x_end_scaled = x_end_normally / g.pattern_length + 0.5
  local y_end = swing_pattern.transform(x_end_scaled)

  local beat_duration = 60 / g.bpm  -- Also the scale for calculating duration

  local expected_pulse_duration = (y_end - y_start) / g.PULSES_PP * beat_duration
  -- Scale up for multi-beat pattern
  local expected_pulse_duration_scaled = expected_pulse_duration * g.pattern_length

  lu.assertAlmostEquals( calc_interval(g.pulse_num), expected_pulse_duration_scaled, 0.001 )

end

function test_calc_interval_swing_60_bpm_pattern_length_3()
  g = init_globals({
    bpm = 60,
    pattern = swing_pattern,
    pattern_length = 8,
    beat_num = 1,
  })

  swing_pattern.swing = 0.79
  swing_pattern.init_pattern()

  g.beat_num = 1
  g.pulse_num = 1
  g.pulse_total = 0

  local time = 0
  for beat = 1, g.pattern_length do
    g.beat_num = beat

    for next_pulse = 1, 24, g.PULSES_PP do
      local interval = calc_interval(next_pulse)
      for pulse = next_pulse, (next_pulse + g.PULSES_PP - 1) do

        print(beat ..", ".. pulse ..", ".. time)
        time = time + interval

      end
    end
  end

  lu.assertAlmostEquals( time, g.pattern_length, 0.001 )

end

os.exit( lu.LuaUnit.run() )
