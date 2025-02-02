To do

- Allow multiple MIDI out channels.
- Save/Load params on init/exit.
- Write readme and add to norns.community.
- Add credits.
- Set default MIDI vport to 1.


Done

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
