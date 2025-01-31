-- Logging module

local log = {

  -- Write a log line with a timestamp.
  --
  t = function(msg, ...)
    local time_fn = util and util.time or os.clock

    if not(g) then
      g = {}
    end

    if not(g.log_init_time) then
      -- Get this to work on norns and in testing (off norns)
      g.log_init_time = time_fn()
    end

    local time = time_fn() - g.log_init_time

    print(time .. ',' .. string.format(msg, table.unpack({...})))
  end,


  -- Simple log: log without a timestamp.
  --
  s = function(msg, ...)
    print(string.format(msg, table.unpack({...})))
  end,

}

return log



