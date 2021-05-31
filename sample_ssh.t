USE_NODE mynode
PORT 2233

TEST "hello"
TEST "echo \"Hello\nWorld\" | grep \"H\""
TEST "ls /tmp/abcd"
TEST 2, "ls /tmp/abcd"
EXPECT "Hello World", "echo \"Hello World\""
