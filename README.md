# Test Framework - Binnacle

Proposal for a Test framework with the focus for Tester's delight!

Automating tests in a distributed setup is always hard. Binnacle aims
to simplify the ergonomics so that a tester without Programming
language expertise can adapt to this quickly.

If someone knows which command to test, then write that command with
the prefix `TEST`. For example, the command `touch
/var/www/html/index.html` tries to create a file inside the directory
to see if it succeeds. To convert this into a test case, write as
below.

```
# File: hello.t
TEST touch /var/www/html/index.html
```

That's it! Run the test file using the binnacle command, and it gives
the beautiful Output as below.

```console
$ binnacle hello.t
hello.t .. ok
All tests successful.
Files=1, Tests=1,  0 wallclock secs ( 0.03 usr  0.01 sys +  0.07 cusr  0.05 csys =  0.16 CPU)
Result: PASS
```

The verbose(`-v`) Output gives other useful details about executed
command and error lines in case of errors.

Learning the new programming language is not required to write test
cases.

**Note**: This framework is not for Unit testing

## Features

- [Multi node support](#Multi-node-support)

[and more](https://kadalu.io/rfcs/0002-test-framework-binnacle.html)

### Multi-node support

Just specify `NODE=<nodename>` before any test to run in that
node. For example,

```
NODE=node1.example.com
TEST command1
TEST command2

NODE=node2.example.com
TEST command3
```

**Note**: Passwordless SSH access is required from the current node
for all the nodes which are specified in Tests.

