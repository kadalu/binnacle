# Test and infra automation Framework - Binnacle

## Install

```
gem install kadalu-binnacle
```

## Usage

Check the version

```
binnacle --version
```

```
binnacle <task-file|task_files_list> [options]
```

Run a single task file

```ruby
# File: verify_report.t
command_run "my-script ~/report.csv"
command_run "stat ~/report.csv"
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

### Run any command (`command_run` or `command_test`)

```ruby
command_run "stat ~/report.csv"
```

```ruby
command_test "stat ~/report.csv"
```

To test a command that returns a specific error

```ruby
command_test 1, "stat ~/non/existing/file"
```

Ignore errors and run any command

```ruby
command_run nil, "docker stop app-dev"
command_run nil, "docker rm app-dev"
```

### Run the command and validate the output

```ruby
#              Expect value         Command
command_expect "node1.example.com", "hostname"
```

### Run a command in a docker container

```ruby
command_mode "docker"
command_container "myapp"

command_run "stat /var/www/html/index.html"
```

### Run a command using SSH

```ruby
command_mode "ssh"
command_ssh_user "ubuntu"
command_sudo true
command_ssh_pem_file "~/.ssh/id_rsa"

command_node "node1.example.com"
command_run "stat /var/www/html/index.html"
```

### Equal and Not Equal

```ruby
compare_equal? var1, 100, "Test if var1 == 100"
compare_not_equal? var1, 100, "Test if var1 != 100"
```

### True and False

```ruby
compare_true? var1 == 100, "Test if var1 == 100"
compare_false? var1 == 100, "Test if var1 != 100"
```

## Customization

`command_node`, `command_mode` etc are used to adjust the behaviour of the plugins. These options can be used as global options or as block options. Block options helps to limit those settings only for that block.

```ruby
command_node "server1"
command_run "command 1"

command_node "server2"
command_run "command 2"

command_node "server1"
command_run "command 3"
```

```ruby
command_node "server1"
command_run "command 1"

command_node "server2" do
    command_run "command 2"
end

command_run "command 3"
```

Both examples above are same. The second one is easy since no need to remember the changed options after executing the command 2.

### Options

- `command_mode` (`local` (default), `docker`, `ssh`)
- `command_node` or `command_container`
- `command_ssh_user`
- `command_ssh_port`
- `command_ssh_pem_file`
- `command_sudo`
- `exit_on_not_ok`

## Embed other task files

Use load keyword to include the tests/utilities from other files.

For example, `repeat_tests.t`

```ruby
command_test "command 1"
command_test "command 2"
```

and the `main.t` tests file

```ruby
command_mode "docker"

containers = ["node1.example.com", "node2.example.com", "node3.example.com"]
containers.each do |container|
    command_node container

    load "./repeat_tests.t"
end
```

## Testing ReST APIs

```ruby
http_base_url "http://localhost:3000"

http_get "/api/users"

# Test a specific status code
http_get "/api/users", status: 200

# Create a user with JSON data
data = {
  "name" => "Binnacle",
  "url" => "https://binnacle.kadalu.tech"
}

http_post "/api/users", json: data, status: 201

# JSON as Text
http_post "/api/users", json: <<-DATA, status: 201
{
  "name": "Binnacle",
  "url": "https://binnacle.kadalu.tech"
}
DATA

# As Form data
data = {
  "name" => "Binnacle",
  "url" => "https://binnacle.kadalu.tech"
}

http_post "/api/users", form: data, status: 201

# Upload a file
data = {
  "name" => "Binnacle",
  "url" => "https://binnacle.kadalu.tech",
  "profile" => "@./binnacle_logo.png"
}

http_post "/api/users", multipart: data, status: 201

# Edit
data = {
  "name" => "Kadalu Binnacle"
}

http_put "/api/users/1", form: data, status: 200

# Delete
http_delete "/api/users/1", status: 204

# Get JSON response
http_response_type "json"
data = http_get "/api/users"
compare_equal "Kadalu Binnacle", data[:json]["name"]

# Add and Remove header
http_add_header "Authorization", "Bearer 1234"
http_get "/api/users", status: 200 # With Auth Header
http_remove_header "Authorization"
http_get "/api/users", status: 401 # Without Auth header
```

A simple script to check the status of websites

```ruby
http_get "https://kadalu.tech"
http_get "https://content.kadalu.tech"
http_get "https://aravindavk.in"
```
