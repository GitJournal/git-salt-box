
DIR := ${CURDIR}

install:
	dart compile exe bin/git_salt_box.dart -o git-salt-box
	mv git-salt-box /usr/local/bin/

fmt:
	dart run import_sorter:main

test:
	dart test

.PHONY: test
