TEST hello
TEST echo "Hello\nWorld" | grep "H"
TEST ls /tmp/abcd
TEST --ret 1 ls /tmp/abcd
TEST --not 0 ls /tmp/abcd
EXPECT -v "Hello World" echo "Hello World"
