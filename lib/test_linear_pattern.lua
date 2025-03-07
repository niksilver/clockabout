-- These tests need to be run from test_all.lua, as that will also
-- set up the packages correctly.


local c              = require('core')
local linear_pattern = require('linear_pattern')


g = {}


-- pulse_interval for linear pattern -------------------------------------


function test_pulse_interval_60_bpm()
  c.init_globals({
    bpm = 60,
    pulse_num = 1,
    beat_num = 1,
    pattern_length = 1,
    pattern = linear_pattern,
  })
  local g = c.g  -- For convenience

  local beat_dur_sec = 60 / g.bpm
  local expected_interval = beat_dur_sec / 24

  lu.assertAlmostEquals( c.pulse_interval(g.pulse_num, g.beat_num), expected_interval, 0.01 )
end


function test_pulse_interval_60_bpm_in_middle_of_bar()
  c.init_globals({
    bpm = 60,
    pulse_num = 17,
    beat_num = 1,
    pattern_length = 1,
    pattern = linear_pattern,
  })
  local g = c.g  -- For convenience

  local beat_dur_sec = 60 / g.bpm
  local expected_interval = beat_dur_sec / 24

  lu.assertAlmostEquals( c.pulse_interval(g.pulse_num, g.beat_num), expected_interval, 0.01 )
end


function test_pulse_interval_60_bpm_in_middle_of_bar_3_beats_per_bar()
  c.init_globals({
    bpm = 60,
    pulse_num = 17,
    beat_num = 1,
    pattern_length = 1,
    pattern = linear_pattern,
  })
  local g = c.g  -- For convenience

  local beat_dur_sec = 60 / g.bpm
  local expected_interval = beat_dur_sec / 24

  lu.assertAlmostEquals( c.pulse_interval(g.pulse_num, g.beat_num), expected_interval, 0.01 )
end


function test_pulse_interval_120_bpm()
  c.init_globals({
    bpm = 120,
    pulse_num = 1,
    beat_num = 1,
    pattern_length = 1,
    pattern = linear_pattern,
  })
  local g = c.g  -- For convenience

  local beat_dur_sec = 60 / g.bpm
  local expected_interval = beat_dur_sec / 24

  lu.assertAlmostEquals( c.pulse_interval(g.pulse_num, g.beat_num), expected_interval, 0.01 )
end


