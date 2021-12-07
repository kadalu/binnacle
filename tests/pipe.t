USE_NODE "local"
puts TEST "echo \"Hello World\" | awk '{print $2}'"

USE_NODE "server1"
USE_REMOTE_PLUGIN "ssh"
USE_SSH_USER "aravinda"

puts TEST "echo \"Hello World\" | awk '{print $2}'"
puts TEST "pwd"
puts TEST "ls hello.txt | xargs stat"
