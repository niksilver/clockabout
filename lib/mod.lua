-- Clockabout - the mod


local mod = require('core/mods')            -- norns' mod functionality
local c   = require('clockabout/lib/core')  -- Clockabout's core functionality
local log = require('clockabout/lib/log')

local run_once = false

local m = {

  -- Called when we enter the mod's own screen
  init = function()
    if not(run_once) then
      c.init({ENV = 'mod'})
      run_once = true
    end
  end,

  -- Called when we exit the mod's own screen
  deinit = function() end,

  key = c.key,
  enc = c.enc,
  redraw = c.redraw,
}

mod.menu.register(mod.this_name, m)
