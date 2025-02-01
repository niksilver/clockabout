# This file is just so we can run :make in vim

test:
	@echo "\n\n\n\n\n\n\n\n\n\n\n"
	lua lib/test_all.lua


# Push files to norns.
# Note we need norns.lan, but most machines will want norns.local.

FROM_DIR := .
TO_DIR := we@norns.lan:/home/we/dust/code/clockabout

push:
	rsync --recursive --delete --itemize-changes \
		--exclude=.git \
		--exclude=.gitignore \
		--exclude=push.sh \
		--exclude-from=.gitignore \
		$(FROM_DIR) $(TO_DIR)
