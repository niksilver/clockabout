-- Mocking up _norns C functions, for testing purposes.


function _norns_init()

  _norns = {}

  -- In reality a C function.
  -- @tparam int id  Metro id (number).
  -- @tparam number time  Gap between clicks.
  --
  _norns.metro_start = function(id, time, count, init_stage)
  end

  -- In reality a C function.
  -- @tparam int id  Metro id (number).
  --
  _norns.metro_stop = function(id)
  end

  -- From the metro module:
  -- NB: metro time isn't applied until the next wakeup.
  -- this is true even if you are setting time from the metro callback;
  -- metro has already gone to sleep when lua main thread gets
  -- if you need a fully dynamic metro, re-schedule on the wakeup
  --
  -- @tparam int id  Metro id (number)
  -- @tparam number time  Gap between clicks.
  _norns.metro_set_time = function(id, time)
  end

  -- Callback function to be set by the metro moduule.
  --
  _norns.metro = nil


  -- Functions to mock time passing -------------------------------------------------


  -- Read the (pretend) time. Do not write to this variable, because
  -- setting the time may also need to trigger a metronome event.
  --
  -- @tfield number time  The clock time in seconds
  --
  _norns.time = 0


  -- Set the time (in seconds).
  --
  _norns.set_time = function(s)
    _norns.time = s
  end


  -- Increment the time by some number of seconds.
  --
  _norns.inc_time = function(delta)
    _norns.time = _norns.time + delta
  end


end


_norns_init()

