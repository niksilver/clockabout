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
    pattern_length = 3,
    beat_num = 1,
  })

  swing_pattern.swing = 0.79
  swing_pattern.init_pattern()

  g.beat_num = 1
  g.pulse_num = 1
  g.pulse_total = 0

  -- We need to scale our expected values to a pattern that's
  -- 60 bpm and running over 3 beats

  local scale = 3

  -- Count our assertions, because they're in if statements and we may
  -- erroneously miss some

  local assertion_count = 0

  local time = 0
  for beat = 1, g.pattern_length do
    g.beat_num = beat

    for next_pulse = 1, 24, g.PULSES_PP do
      local interval = calc_interval(next_pulse)
      for pulse = next_pulse, (next_pulse + g.PULSES_PP - 1) do

        time = time + interval

        -- At the half way point should be the swing value, scaled

        if beat == 2 and pulse == 12 then
          lu.assertAlmostEquals( time, 0.79 * scale, 0.001 )
          assertion_count = assertion_count + 1
        end

        -- At the quarter-way point, should be half the swing value, scaled

        if beat == 1 and pulse == 18 then
          lu.assertAlmostEquals( time, 0.79/2 * scale, 0.001 )
          assertion_count = assertion_count + 1
        end

        -- At the three-quarter-way point, should be between the swing value and the full beat, scaled

        if beat == 3 and pulse == 6 then
          local expected = (0.79 + 1.00) / 2
          lu.assertAlmostEquals( time, expected * scale, 0.001 )
          assertion_count = assertion_count + 1
        end

      end
    end
  end

  lu.assertEquals(assertion_count, 3)

  lu.assertAlmostEquals( time, 1.0 * scale, 0.001 )

end


function test_calc_interval_swing_90_bpm_pattern_length_3()

  -- Should be just like bpm 90, but 90/60 faster - only the scale is different

  g = init_globals({
    bpm = 90,
    pattern = swing_pattern,
    pattern_length = 3,
    beat_num = 1,
  })

  swing_pattern.swing = 0.79
  swing_pattern.init_pattern()

  g.beat_num = 1
  g.pulse_num = 1
  g.pulse_total = 0

  -- We need to scale our expected values to a pattern that's
  -- 90 bpm and running over 3 beats

  local scale = 3 / (90/60)

  -- Count our assertions, because they're in if statements and we may
  -- erroneously miss some

  local assertion_count = 0

  local time = 0
  for beat = 1, g.pattern_length do
    g.beat_num = beat

    for next_pulse = 1, 24, g.PULSES_PP do
      local interval = calc_interval(next_pulse)
      for pulse = next_pulse, (next_pulse + g.PULSES_PP - 1) do

        time = time + interval

        -- At the half way point should be the swing value, scaled

        if beat == 2 and pulse == 12 then
          lu.assertAlmostEquals( time, 0.79 * scale, 0.001 )
          assertion_count = assertion_count + 1
        end

        -- At the quarter-way point, should be half the swing value, scaled

        if beat == 1 and pulse == 18 then
          lu.assertAlmostEquals( time, 0.79/2 * scale, 0.001 )
          assertion_count = assertion_count + 1
        end

        -- At the three-quarter-way point, should be between the swing value and the full beat, scaled

        if beat == 3 and pulse == 6 then
          local expected = (0.79 + 1.00) / 2
          lu.assertAlmostEquals( time, expected * scale, 0.001 )
          assertion_count = assertion_count + 1
        end

      end
    end
  end

  lu.assertEquals(assertion_count, 3)

  lu.assertAlmostEquals( time, 1.0 * scale, 0.001 )

end


-- calc_interval for superellipse pattern -------------------------------------


function test_calc_interval_superellipse_60_bpm_power_2()
  g = init_globals({
    bpm = 60,
    pattern = superellipse_pattern,
    pattern_length = 1,
    beat_num = 1,
  })

  superellipse_pattern.power = 2.00
  superellipse_pattern.init_pattern()

  g.beat_num = 1
  g.pulse_num = 1
  g.pulse_total = 0

  -- No special scaling needed

  local scale = 1

  -- Count our assertions, because they're in if statements and we may
  -- erroneously miss some

  local assertion_count = 0

  -- Expected values below are from calculations in Excel

  print('power 2.0')
  local time = 0

  for next_pulse = 1, 24, g.PULSES_PP do
    local interval = calc_interval(next_pulse)
    for pulse = next_pulse, (next_pulse + g.PULSES_PP - 1) do

      time = time + interval
      print(string.format('%d, %d, %f', 1, pulse, time))

      -- At the quarter-way point

      if beat == 1 and pulse == 6 then
        lu.assertAlmostEquals( time, 0.6614 * scale, 0.01 )
        assertion_count = assertion_count + 1
      end

      -- At the half way point

      if beat == 1 and pulse == 12 then
        lu.assertAlmostEquals( time, 0.8660 * scale, 0.001 )
        assertion_count = assertion_count + 1
      end

      -- At the three-quarter-way point

      if beat == 1 and pulse == 18 then
        lu.assertAlmostEquals( time, 0.9682 * scale, 0.001 )
        assertion_count = assertion_count + 1
      end

    end
  end

  -- lu.assertEquals(assertion_count, 3)

  lu.assertAlmostEquals( time, 1.0 * scale, 0.001 )

end


function test_calc_interval_superellipse_60_bpm_power_0_5()
  g = init_globals({
    bpm = 60,
    pattern = superellipse_pattern,
    pattern_length = 1,
    beat_num = 1,
  })

  superellipse_pattern.power = 0.50
  superellipse_pattern.init_pattern()

  g.beat_num = 1
  g.pulse_num = 1
  g.pulse_total = 0

  -- No special scaling needed

  local scale = 1

  -- Count our assertions, because they're in if statements and we may
  -- erroneously miss some

  local assertion_count = 0

  -- Expected values below are from calculations in Excel

  print('power 0.5')
  local time = 0

  for next_pulse = 1, 24, g.PULSES_PP do
    local interval = calc_interval(next_pulse)
    for pulse = next_pulse, (next_pulse + g.PULSES_PP - 1) do

      time = time + interval
      print(string.format('%d, %d, %f', 1, pulse, time))

      -- At the quarter-way point

      if beat == 1 and pulse == 6 then
        lu.assertAlmostEquals( time, 0.0179 * scale, 0.01 )
        assertion_count = assertion_count + 1
      end

      -- At the half way point

      if beat == 1 and pulse == 12 then
        lu.assertAlmostEquals( time, 0.0858 * scale, 0.001 )
        assertion_count = assertion_count + 1
      end

      -- At the three-quarter-way point

      if beat == 1 and pulse == 18 then
        lu.assertAlmostEquals( time, 0.25 * scale, 0.001 )
        assertion_count = assertion_count + 1
      end

    end
  end

  -- lu.assertEquals(assertion_count, 3)

  lu.assertAlmostEquals( time, 1.0 * scale, 0.001 )

end


os.exit( lu.LuaUnit.run() )
