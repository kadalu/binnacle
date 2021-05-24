BINNACLE_VERSION ?= devel

build:
	mkdir -p bin
	echo "#!/usr/bin/env ruby" > ./bin/binnacle
	echo "VERSION = \"${BINNACLE_VERSION}\"" >> ./bin/binnacle
	cat src/runner.rb >> ./bin/binnacle
	cat src/plugins.rb >> ./bin/binnacle
	cat src/binnacle.rb >> ./bin/binnacle
	chmod +x ./bin/binnacle
