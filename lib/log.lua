-- Logging module

local log = {}


-- Write a log line with a timestamp.
--
log.t = function(msg, ...)
  -- We're either on a norns or in our test environment
  local time = util and util.time() or _norns.time

  if not(g) then
    g = {}
  end

  if not(g.log_init_time) then
    -- Get this to work on norns and in testing (off norns)
    g.log_init_time = time
  end

  local rel_time = time - g.log_init_time

  print(rel_time .. ',' .. string.format(msg, table.unpack({...})))
end


-- Simple log: log without a timestamp.
--
log.s = function(msg, ...)
  print(string.format(msg, table.unpack({...})))
end


-- Whether to suppress log.n messages. False by default.
--
log.suppress_n = false


-- norns log message. A simple log message intended to be used for
-- norns' logs. These can be suppressed (e.g. for tests) by setting
-- log.suppress_n = true.
--
log.n = function(msg, ...)
  if not(log.suppress_n) then
    print(string.format(msg, table.unpack({...})))
  end
end


return log



