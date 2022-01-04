
DIR := ${CURDIR}

install:
	dart compile exe bin/main.dart -o git-salt-box
	mv git-salt-box /usr/local/bin/

fmt:
	dart run import_sorter:main

test:
	dart test

.PHONY: test
