USE_NODE "192.168.64.3"
USE_REMOTE_PLUGIN "ssh"
USE_SSH_SUDO true
USE_SSH_USER "aravinda"

puts TEST "gluster volume info"

puts TEST "awk '/def/ {print $2}' \"snapshots_zfs_single_node.t\""
