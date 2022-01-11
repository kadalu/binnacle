#!/bin/bash

curl -fsSL https://github.com/kadalu/binnacle/releases/latest/download/binnacle -o /tmp/binnacle

install /tmp/binnacle /usr/bin/binnacle
