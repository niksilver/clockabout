-- Mocking up _norns C functions, for testing purposes.


function _norns_init()

  _norns = {}


  -- Mocking real internal _norns functions -----------------------------------------

  -- In reality a C function.
  -- @tparam int id  Metro id (number).
  -- @tparam number time  Gap between clicks.
  --
  _norns.metro_start = function(id, time, count, init_stage)
    local m = _norns.metros[id]
    m.is_running = true
    m.time = time
    m.count = count
    m.next_event_time = _norns.time + time
    m.stage = init_stage
  end


  -- In reality a C function.
  -- @tparam int id  Metro id (number).
  --
  _norns.metro_stop = function(id)
    local m = _norns.metros[id]
    m.is_running = false
    m.next_event_time = math.maxinteger
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
    local m = _norns.metros[id]
    local old_time = m.time
    m.time = time
    m.next_event_time = m.next_event_time + (time - old_time)
  end


  -- Callback function to be set internally by the metro module.
  -- @tparam int id  Numeric id of the metro.
  -- @tparam int stage  Stage number of the metro (from 1).
  --
  _norns.metro = function(id, stage)
  end


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

    for id, m in ipairs(_norns.metros) do
      if s >= m.next_event_time then
        _norns.metro(id, m.stage)
        m.stage = m.stage + 1
        m.next_event_time = m.next_event_time + m.time

        if m.stage > m.count then
          _norns.metro_stop(id)
        end
      end
    end

  end


  -- Increment the time by some number of seconds.
  --
  _norns.inc_time = function(delta)
    _norns.set_time( _norns.time + delta )
  end


  -- Simulate internal metros -------------------------------------------------------


  _norns.metros = {}

  for i = 1,36 do
    _norns.metros[i] = {
      is_running = false,
      next_event_time = math.maxinteger,
      time = 0,
      stage = 0,  -- Next or currently-running stage
    }
  end


end


_norns_init()

