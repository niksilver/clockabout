-- Clockabout
--
-- Why should swing be the
-- only non-linear clock pattern?
--
-- E1: Select pattern
-- E2: Change BPM
-- E3: Pattern-specific param
-- K1+E3: Second pattern param
-- K3: Start/stop clock
--
-- Version 0.10.0


local c       = require('clockabout/lib/core')
local log     = require('clockabout/lib/log')
local mod_api = require('clockabout/lib/mod')


init = function()
  if mod_api.mod_running then
    -- Use globals set in the mod... but also start the metro by default,
    -- because this is the script.
    c.g = mod_api.g
    c.set_metro_running_param(1)
  else
    -- Use script default params, but also make sure the metro starts by default
    c.init_norns_params({metro_running = 1})
  end

  -- Final touches:
  --   - Load the last paramset. That will also bang all the parameters, except
  --     the metronome.
  --   - Set the metronome going, if it should be.

  params:default()
  c.g.initialised = true
  params:lookup_param("clockabout_metro_running"):bang()
end


-- Basic norns functions ------------------------------------------------


enc = c.enc


key = c.key


redraw = c.redraw
