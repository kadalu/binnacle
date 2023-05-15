BINNACLE_VERSION ?= 0.0.0
BINNACLE_FILE ?= -
VERBOSE ?= -vv

gen-version:
	@echo "# frozen_string_literal: true"      > lib/binnacle/version.rb
	@echo                                     >> lib/binnacle/version.rb
	@echo "module Binnacle"                   >> lib/binnacle/version.rb
	@echo "  VERSION = '${BINNACLE_VERSION}'" >> lib/binnacle/version.rb
	@echo "end"                               >> lib/binnacle/version.rb

build: gen-version
	gem build binnacle.gemspec

run:
	RUBYLIB=./lib ruby bin/binnacle ${BINNACLE_FILE} ${VERBOSE}

publish: build
	gem push binnacle-${BINNACLE_VERSION}.gem

deps-install:
	bundle install

lint: gen-version deps-install
	bundle exec rubocop
