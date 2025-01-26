-- Testing our mock metro code.


local metro = require('mock_metro')


-- We'll put these tests in a table to be able to use setUp() / tearDown()

TestMockNorns = {


  setUp = function()
    _norns_init()
    metro.init_module()
  end,


  test_can_start_and_run_a_metro = function()
    slog('*******')
    _norns.set_time(100)

    -- Start metro that runs exactly three times, once every 0.5 seconds.
    -- We'll record how many times it ticks at each stage.

    local ticks = { 0, 0, 0 }
    local record_tick = function(stage)
      slog('In record_tick(%d)', stage)
      ticks[stage] = ticks[stage] + 1
    end

    -- Init the metro, but don't start it for a while
    local m = metro.init(record_tick, 0.5, 3)
    slog('Our metro has id %d', m.id)

    _norns.inc_time(0.25)
    _norns.inc_time(0.25)
    _norns.inc_time(0.25)
    _norns.inc_time(0.25)
    lu.assertEquals(_norns.time, 101)  -- Time should be at 101 seconds
    lu.assertEquals(ticks, { 0, 0, 0 })

    -- Now start the metro
    m:start()
    lu.assertEquals(ticks, { 0, 0, 0 })

    _norns.inc_time(0.25)
    lu.assertEquals(_norns.time, 101 + 0.25)
    lu.assertEquals(ticks, { 0, 0, 0 })

    _norns.inc_time(0.25)  -- At start + 0.5 seconds, should trigger for first time
    lu.assertEquals(_norns.time, 101 + 0.50)
    slog(' - - - - - - -')
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

}
