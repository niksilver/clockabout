-- Clockabout - the mod


local mod = require('core/mods')            -- norns' mod functionality
local c   = require('clockabout/lib/core')  -- Clockabout's core functionality

local m = {
  init = c.init,
  key = c.key,
  enc = c.enc,
  redraw = c.redraw,
}

mod.menu.register(mod.this_name, m)
