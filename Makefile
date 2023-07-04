BINNACLE_VERSION ?= 0.0.0
BINNACLE_FILE ?= -
VERBOSE ?= -vv

gen-version:
	@echo "# frozen_string_literal: true"        > lib/kadalu/binnacle/version.rb
	@echo					    >> lib/kadalu/binnacle/version.rb
	@echo "module Kadalu"			    >> lib/kadalu/binnacle/version.rb
	@echo "  module Binnacle"                   >> lib/kadalu/binnacle/version.rb
	@echo "	   VERSION = '${BINNACLE_VERSION}'" >> lib/kadalu/binnacle/version.rb
	@echo "  end"				    >> lib/kadalu/binnacle/version.rb
	@echo "end"				    >> lib/kadalu/binnacle/version.rb

build: gen-version
	gem build kadalu-binnacle.gemspec

run:
	RUBYLIB=./lib ruby bin/binnacle ${BINNACLE_FILE} ${VERBOSE}

publish: build
	gem push kadalu-binnacle-${BINNACLE_VERSION}.gem

deps-install:
	bundle install

lint: gen-version deps-install
	bundle exec rubocop
