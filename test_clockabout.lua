lu = require('luaunit')
require('clockabout')

function test_calc_interval_60_bpm()
    init_globals()

    g.bpm = 60
    g.pulse_num = 1
    g.pulse_total = 0

    local pulses_per_beat = (60 / g.bpm) / 24 * BEATS_PB

    lu.assertAlmostEquals( calc_interval(), pulses_per_beat / PARTS_PQN, 0.01 )
end

function test_calc_interval_60_bpm_in_middle_of_bar()
    init_globals()

    g.bpm = 60
    g.pulse_num = 17
    g.pulse_total = 16 + 96

    local pulses_per_beat = (60 / g.bpm) / 24 * BEATS_PB

    lu.assertAlmostEquals( calc_interval(), pulses_per_beat / PARTS_PQN, 0.01 )
end

function test_calc_interval_120_bpm()
    init_globals()

    g.bpm = 120
    g.pulse_num = 1
    g.pulse_total = 0

    local pulses_per_beat = (60 / g.bpm) / 24 * BEATS_PB

    lu.assertAlmostEquals( calc_interval(), pulses_per_beat / PARTS_PQN, 0.01 )
end

os.exit( lu.LuaUnit.run() )
