import subprocess
from argparse import ArgumentParser
from typing import List, Tuple
import sys

from binnacle import commands

PIPEARG = "--pipe"
RC_SUCCESS = 0
TEST_KEYWORDS = [
    "TEST"
]

CommandOutput = Tuple[int, List[str], List[str]]


def execute(node: str, cmd: str, args: List[str],
            stdin_lines:List[str]=[]) -> CommandOutput:
    """
    Execute the given command. If given command is a Python func in
    commands module then call that function, else execute as command
    """
    func = getattr(commands, "command_" + cmd, None)
    if func is not None:
        return func(node, args, stdin_lines)
    else:
        # TODO: Handle node != "local" and execute via ssh
        # depending on the command. Not required if command is only
        # post processing first command's output
        cmdargs = [cmd] + args
        
        proc = subprocess.Popen(
            cmdargs,
            stderr=subprocess.PIPE,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            universal_newlines=True
        )
        for line in stdin_lines:
            proc.stdin.write(line + "\n")

        out, err = proc.communicate()
        return (
            proc.returncode,
            out.strip().split("\n"),
            err.strip().split("\n")
        )


def parse_tester_args(args):
    """Global arguments for each test line"""
    parser = ArgumentParser()
    parser.add_argument("--ret", type=int, default=0)
    parser.add_argument("--not", type=int, default=None)
    parser.add_argument("--seq", type=int, default=0)
    return parser.parse_known_args(args)


def command_groups(args: List[str]) -> List[List[str]]:
    """
    Split and Group the commands based on `--pipe` argument
    """
    groups:List[List[str]] = []
    for arg in args:
        if len(groups) == 0:
            groups.append([])

        if arg == PIPEARG:
            groups.append([])
            continue

        groups[-1].append(arg)

    return groups


def ok(seq: int, node: str, cmd: str) -> None:
    """
    "ok" output as required in TAP(Test Anything Protocol)
    """
    print("%-6s %4d - [{node=%s}, {cmd=%s}]" % ("ok", seq, node, cmd))


def notok(seq: int, node: str, cmd: str, errlines: List[str]=[]) -> None:
    """
    "not ok" output as required in TAP(Test Anything Protocol)
    """
    print("%-6s %4d - [{node=%s}, {cmd=%s}]" % ("not ok", seq, node, cmd))
    for line in errlines:
        print("#    " + line)


def handle_TEST(node: str, args: List[str]) -> None:
    """
    Runs the tests which starts with TEST.
    """
    global_args, remaining_args = parse_tester_args(args)
    cmdgrps = command_groups(remaining_args)
    out: List[str] = []
    num_groups = len(cmdgrps)
    for idx, cmd in enumerate(cmdgrps):
        rc, out, err = execute(node, cmd[0], cmd[1:], out)

        # If command failed and this is not the last command in Pipe
        # then do not continue
        # TODO: What to do for non success return code?
        if idx+1 < num_groups and rc != RC_SUCCESS:
            break

    print_cmd = "TEST " + " ".join(args)
    if global_args.ret == rc:
        ok(global_args.seq, node, print_cmd)
    else:
        notok(global_args.seq, node, print_cmd, err)
