Tests

- Startup test cases:
  - With no mod, from a restart:
    - Clockabout picks up its own saved params.
  - With mod, from a restart:
    - Awake picks up saved params.
    - Awake, then Clockabout - Clockabout picks up its own saved params.
    - Clockabout picks up its own saved params.
    - Clockabout, then Awake - Awake picks up its own saved params.


To do

- Fix bug with random mode in menus.
- Fix bug with random mode (changing pattern length quickly down a lot)
    lua: /home/we/dust/code/clockabout/lib/random_pattern.lua:168: No segment found for x = 1.5
    stack traceback:
    in function 'error'
            /home/we/dust/code/clockabout/lib/random_pattern.lua:168: in function 'clockabout/lib/random_pattern.transform'
            /home/we/dust/code/clockabout/lib/core.lua:645: in function 'clockabout/lib/core.pulse_interval'
            /home/we/dust/code/clockabout/lib/core.lua:570: in function 'clockabout/lib/core.send_pulse'
            /home/we/norns/lua/core/metro.lua:169: in function </home/we/norns/lua/core/metro.lua:165>
    lua: /home/we/dust/code/clockabout/lib/random_pattern.lua:168: No segment found for x = 1.5625
- Remove '- - - -' debug logging.
- Don't start the clock when loaded as a mod.
- Maybe remove mod screen.
- For mod, stop metros on cleanup.
- For the mod part of README:
  - Use the script with a MIDI device and feed back in.
  - Mod attaches to the end of any script.
  - Use the script as a screen.
  - Will it start automatically?
  - Explain saving and loading params.
  - If no metros it will show up in the log output.


Done

- Create logging for norns-only output.
- Fix bug with cheatcodes_2 (run out of metros).
- Save and load mod params.
- Allow script to run when mod runs.
- For mod, add K2 to exit.
- Add to norns.community.
- Add deinit() to the mod script.
- Fix bug: With random pattern, script keeps redrawing in SELECT menu.
- Remove global variables (for being a mod):
    g, linear, swing, superellipse, random, double superellipse.
- Write readme.
- Set default MIDI vport to 1.
- Ensure redraw() for a pattern is called between beats.
- Add credits.
- Save/Load params on init/exit.
- Fix bug where toggling off one vport in multi mode doesn't
  stop the clock being sent.
- Allow multiple MIDI out channels.
- Optimise metro init/start work.
- Check if we need to free metros (we do).
- Remove 'metro_for_testing' param in send_pulse().
- Restore redraw() from send_pulse() regenerate clause.
- Change norns_init() to norns.init().
- Add s-curve (double superellipse).
- Allow change of inflection point on double superellipse.
- Add a random pattern.
- Random pattern regenerates after each run-through.
- Send MIDI start/stop on pattern start/stop.
- Shift-E3 to change second pattern param.
- Allow change of swing inflection point.
- Add a superellipse pattern.
- Improve the pattern graph.
- Remove TMP clock code.
- Allow patterns to run over several bars.
- Add stop/start on K2.
- Fix bpm bug with swing pattern.
- Check whether we don't need to stop, free and re-init the current metro
  each time it reaches the end of its run.
