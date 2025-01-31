-- Testing our mock metro code.


require('clockabout')
local metro = require('mock_metro')


-- We'll put these tests in a table to be able to use setUp() / tearDown()

TestMockNorns = {


  setUp = function()
    _norns.init()
    metro.init_module()
  end,


  IGNORE_test_can_start_and_run_a_metro = function()
    slog('- - - - - - - Start test - - - - - - -')
    _norns.set_time(100)

    -- Start metro that runs exactly three times, once every 0.5 seconds.
    -- We'll record how many times it ticks at each stage.

    local ticks = { 0, 0, 0 }
    local record_tick = function(stage)
      ticks[stage] = ticks[stage] + 1
    end

    -- Init the metro, but don't start it for a while
    local m = metro.init(record_tick, 0.5, 3)
    m.name = 'MockMeetro'
    slog('test_...(): Inited metro m = %s', tostring(m))

    _norns.inc_time(0.25)
    _norns.inc_time(0.25)
    _norns.inc_time(0.25)
    _norns.inc_time(0.25)
    lu.assertEquals(_norns.time, 101)  -- Time should be at 101 seconds
    lu.assertEquals(ticks, { 0, 0, 0 })

    -- Now start the metro
    slog('test_...(): Starting metro = %s', tostring(m))
    m:start()
    lu.assertEquals(ticks, { 0, 0, 0 })

    _norns.inc_time(0.25)
    lu.assertEquals(_norns.time, 101 + 0.25)
    lu.assertEquals(ticks, { 0, 0, 0 })

    _norns.inc_time(0.25)  -- At start + 0.5 seconds, should trigger for first time
    lu.assertEquals(_norns.time, 101 + 0.50)
    lu.assertEquals(ticks, { 1, 0, 0 })

    _norns.inc_time(0.25)
    lu.assertEquals(_norns.time, 101 + 0.75)
    lu.assertEquals(ticks, { 1, 0, 0 })

    _norns.inc_time(0.25)  -- At start + 1.0 seconds, should trigger for second time
    lu.assertEquals(_norns.time, 101 + 1.00)
    lu.assertEquals(ticks, { 1, 1, 0 })

    _norns.inc_time(0.25)
    lu.assertEquals(_norns.time, 101 + 1.25)
    lu.assertEquals(ticks, { 1, 1, 0 })

    _norns.inc_time(0.25)  -- At start + 1.5 seconds, should trigger for final time
    lu.assertEquals(_norns.time, 101 + 1.50)
    lu.assertEquals(ticks, { 1, 1, 1 })

    -- If time continues we shouldn't trigger any more events

    _norns.inc_time(0.25)
    _norns.inc_time(0.25)
    lu.assertEquals(_norns.time, 101 + 2.00)
    lu.assertEquals(ticks, { 1, 1, 1 })

  end,


  IGNORE_test_can_run_two_metros = function()
    _norns.set_time(10)

    -- Start metro that runs exactly three times, once every 0.5 seconds.
    -- We'll record how many times it ticks at each stage.

    -- We'll run two metros which each run three times (at different intervals)
    -- and track their ticks.

    local ticks_a = { 0, 0, 0 }
    local ticks_b = { 0, 0, 0 }
    local record_tick_a = function(stage)
      ticks_a[stage] = ticks_a[stage] + 1
    end
    local record_tick_b = function(stage)
      ticks_b[stage] = ticks_b[stage] + 1
    end

    -- Init the metros, but don't start them immediately
    -- Metro A: Run at start + 1.0 and 2.0 and 3.0 only
    -- Metro B: Run at start + 0.5 and 1.0 and 1.5 only
    local m_a = metro.init(record_tick_a, 1.0, 3)
    local m_b = metro.init(record_tick_b, 0.5, 3)

    _norns.inc_time(0.5)
    _norns.inc_time(0.5)
    lu.assertEquals(_norns.time, 11)  -- Time should be at 101 seconds
    lu.assertEquals(ticks_a, { 0, 0, 0 })
    lu.assertEquals(ticks_b, { 0, 0, 0 })

    -- Now start the metros
    m_a:start()
    m_b:start()
    lu.assertEquals(ticks_a, { 0, 0, 0 })
    lu.assertEquals(ticks_b, { 0, 0, 0 })

    _norns.inc_time(0.5)
    lu.assertEquals(_norns.time, 11 + 0.5)
    lu.assertEquals(ticks_a, { 0, 0, 0 })
    lu.assertEquals(ticks_b, { 1, 0, 0 })

    _norns.inc_time(0.5)
    lu.assertEquals(_norns.time, 11 + 1.0)
    lu.assertEquals(ticks_a, { 1, 0, 0 })
    lu.assertEquals(ticks_b, { 1, 1, 0 })

    _norns.inc_time(0.5)
    lu.assertEquals(_norns.time, 11 + 1.5)
    lu.assertEquals(ticks_a, { 1, 0, 0 })
    lu.assertEquals(ticks_b, { 1, 1, 1 })

    _norns.inc_time(0.5)
    lu.assertEquals(_norns.time, 11 + 2.0)
    lu.assertEquals(ticks_a, { 1, 1, 0 })
    lu.assertEquals(ticks_b, { 1, 1, 1 })

    _norns.inc_time(0.5)
    lu.assertEquals(_norns.time, 11 + 2.5)
    lu.assertEquals(ticks_a, { 1, 1, 0 })
    lu.assertEquals(ticks_b, { 1, 1, 1 })

    _norns.inc_time(0.5)
    lu.assertEquals(_norns.time, 11 + 3.0)
    lu.assertEquals(ticks_a, { 1, 1, 1 })
    lu.assertEquals(ticks_b, { 1, 1, 1 })

    -- Should be no more changes from here on

    _norns.inc_time(0.5)
    lu.assertEquals(_norns.time, 11 + 3.5)
    lu.assertEquals(ticks_a, { 1, 1, 1 })
    lu.assertEquals(ticks_b, { 1, 1, 1 })

    _norns.inc_time(0.5)
    lu.assertEquals(_norns.time, 11 + 4.0)
    lu.assertEquals(ticks_a, { 1, 1, 1 })
    lu.assertEquals(ticks_b, { 1, 1, 1 })

  end,


  test_can_start_at_different_stage = function()
    slog('- - - - - - - Start test - - - - - - -')
    _norns.set_time(55)

    -- Start metro that runs exactly 5 times, once every 0.5 seconds,
    -- but we'll really start it at stage 4.
    -- We'll record which stages it gets called at.

    local ticks = { 0, 0, 0, 0, 0 }
    local record_tick = function(stage)
      ticks[stage] = ticks[stage] + 1
    end

    -- Init the metro, but don't start it for a while
    local m = metro.init(record_tick, 0.5, 5)
    slog('test_...(): Inited metro m = %s', tostring(m))

    _norns.inc_time(0.25)
    _norns.inc_time(0.25)
    _norns.inc_time(0.25)
    _norns.inc_time(0.25)
    lu.assertEquals(_norns.time, 56)  -- This should be the time now
    lu.assertEquals(ticks, { 0, 0, 0, 0, 0 })

    -- Now start the metro at stage 4
    slog('test_...(): Starting metro = %s', tostring(m))
    m:start(m.time, m.count, 4)
    lu.assertEquals(ticks, { 0, 0, 0, 0, 0 })

    _norns.inc_time(0.25)
    lu.assertEquals(_norns.time, 56 + 0.25)
    lu.assertEquals(ticks, { 0, 0, 0, 0, 0 })

    _norns.inc_time(0.25)
    lu.assertEquals(_norns.time, 56 + 0.50)
    lu.assertEquals(ticks, { 0, 0, 0, 1, 0 })  -- Should have triggered event

    _norns.inc_time(0.25)
    lu.assertEquals(_norns.time, 56 + 0.75)
    lu.assertEquals(ticks, { 0, 0, 0, 1, 0 })

    _norns.inc_time(0.25)
    lu.assertEquals(_norns.time, 56 + 1.00)
    lu.assertEquals(ticks, { 0, 0, 0, 1, 1 })  -- Should have triggered event

    -- Should not trigger any more events

    _norns.inc_time(0.25)
    _norns.inc_time(0.25)
    _norns.inc_time(0.25)
    _norns.inc_time(0.25)
    lu.assertEquals(_norns.time, 56 + 2.00)
    lu.assertEquals(ticks, { 0, 0, 0, 1, 1 })

  end,

}
