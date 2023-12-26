# Test and infra automation Framework - Binnacle

## Install

```
gem install kadalu-binnacle
```

## Usage

```
binnacle <task-file|task_files_list> [options]
```

Run a single task file

```ruby
# File: verify_report.t
run "my-script ~/report.csv"
run "stat ~/report.csv"
```

```
binnacle verify_report.t
```

For detailed output, use `-v` and to print the output of the commands, use `-vv`

```
binnacle -vv verify_report.t
```

For JSON results,

```
binnacle -vv verify_report.t --results-json=report.json
```

To run multiple files,

```
binnacle -vv file1.t file2.t file3.t
```

Alternatively give list of files as task list(`*.tl`)

File: tasks.tl

```
file1.t
file2.t
file3.t
```

Or give directory path to run all the tasks in the directory

```
binnacle -vv tasks_dir
```

Wide output: Set this flag to not crop the output lines

```
binnacle -vv -w verify_report.t
```

## Syntax and Keywords

### Run any command (`run` or `test`)

```ruby
run "stat ~/report.csv"
```

```ruby
test "stat ~/report.csv"
```

To test a command that returns a specific error

```ruby
test 1, "stat ~/non/existing/file"
```

Ignore errors and run any command

```ruby
run nil, "docker stop app-dev"
run nil, "docker rm app-dev"
```

### Run the command and validate the output

```ruby
#      Expect value         Command
expect "node1.example.com", "hostname"
```

### Run a command in a docker container

```ruby
use_remote_plugin "docker"
use_container "myapp"

run "stat /var/www/html/index.html"
```

### Run a command using SSH

```ruby
use_remote_plugin "ssh"
use_ssh_user "ubuntu"
use_sudo true
use_ssh_pem_file "~/.ssh/id_rsa"

use_node "node1.example.com"
run "stat /var/www/html/index.html"
```

### Equal and Not Equal

```ruby
equal var1, 100, "Test if var1 == 100"
not_equal var1, 100, "Test if var1 != 100"
```

### True and False

```ruby
true? var1 == 100, "Test if var1 == 100"
false? var1 == 100, "Test if var1 != 100"
```

## Customization

`use_node`, `use_remote_plugin` etc are used to adjust the behaviour of the plugins. These options can be used as global options or as block options. Block options helps to limit those settings only for that block.

```ruby
use_node "server1"
run "command 1"

use_node "server2"
run "command 2"

use_node "server1"
run "command 3"
```

```ruby
use_node "server1"
run "command 1"

use_node "server2" do
    run "command 2"
end

run "command 3"
```

Both examples above are same. The second one is easy since no need to remember the changed options after executing the command 2.

### Options

- `use_remote_plugin`
- `use_node` or `use_container`
- `use_ssh_user`
- `use_ssh_port`
- `use_ssh_pem_file`
- `use_sudo`
- `exit_on_not_ok`

## Embed other task files

Use load keyword to include the tests/utilities from other files.

For example, `repeat_tests.t`

```ruby
test "command 1"
test "command 2"
```

and the `main.t` tests file

```ruby
use_remote_plugin "docker"

nodes = ["node1.example.com", "node2.example.com", "node3.example.com"]
nodes.each do |node|
    use_node node

    load "./repeat_tests.t"
end
```
