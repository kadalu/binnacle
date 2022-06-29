# -*- mode: ruby -*-

puts TEST "stat tests/keywords.t"
TEST 1, "stat /non/existing/file"
TEST "sleep 0.5"
EXPECT "Hello World!", "echo -n Hello World!"
EXPECT "Hello World!\n", "echo Hello World!"
x = 10
TRUE x == 10, "Check if x == 10", "Failed"
TRUE x == 10, "Check if x == 10"
TRUE "#{x} == 10", "Check if x == 10"

FALSE x == 15, "Check if x != 15", "Failed"
FALSE x == 15, "Check if x != 15"
FALSE "#{x} == 15", "Check if x != 15"

EQUAL x, 10, "Check if x == 10"
NOT_EQUAL x, 15, "Check if x != 15"
puts TEST "stat tests/keywords.t"
