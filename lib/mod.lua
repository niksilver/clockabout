-- Clockabout - the mod


local mod = require('core/mods')            -- norns' mod functionality
local c   = require('clockabout/lib/core')  -- Clockabout's core functionality
local log = require('clockabout/lib/log')


local api = {
  -- If this file is executed as a mod (rather than just required) then
  -- there will be a key/value pair here of
  -- mod_running = true

  -- We will also make the globals c.g available here in field g.
}


-- There's no menu screen for the mod, so no init, deinit, key, enc or redraw.


-- Only try to register things if this file is beign executed as
-- a mod (rather than required by the main script)

if mod.this_name then

  mod.menu.register(mod.this_name, m)

  -- Runs after system startup
  --
  mod.hook.register("system_post_startup", "Clockabout post-startup", function()
    api.mod_running = true
  end)

  -- Runs before a script's init() function is called
  --
  mod.hook.register("script_pre_init", "Clockabout pre-init", function()
    c.init_norns_params({metro_running = 0})

    -- Make the globals available to the clockabout script, if it runs
    api.g = c.g

    -- Final touches:
    --   - Bang all the params (except the metronome, which is last).
    --   - Set the metronome going, if it should be.

    params:bang()
    c.g.initialised = true
    params:lookup_param("clockabout_metro_running"):bang()

  end)


  -- When a scipt finishes its initialisation, but before it starts
  --
  mod.hook.register("script_post_init", "Clockabout post-init", function()
  end)

  -- Runs after a script's cleanup() function has been called
  --
  mod.hook.register("script_post_cleanup", "Clockabout post-cleanup", function()
  end)

end


return api
