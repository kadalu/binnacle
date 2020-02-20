import os
from typing import Tuple

from binnacle.testutils import TEST_KEYWORDS


def replace_pipe(text: str) -> str:
    """
    If Line contains pipe char "|" then replace it with
    "--pipe" so that Test runner will understand
    """
    return text.replace("|", " --pipe ")


def sequence_include(line:str, seq:int) -> Tuple[str, int]:
    """
    Sets Sequence number for each test line. Returns
    incremented sequence for future use.
    """
    if not line:
        return (line, seq)

    startword = line.split()[0]
    if startword in TEST_KEYWORDS:
        line = line.replace(startword, "%s --seq=%d" % (startword, seq))
        seq += 1

    return (line, seq)


def parse(content: str) -> str:
    """
    Parse the input Test file and generates the bash file
    which can be run using prove command.
    """
    moduledir = os.path.dirname(os.path.abspath(__file__))
    outlines = [
        # Set Bash hashbang
        "#!/bin/bash",
        "",
        # Include utils
        "source %s/binnacle_utils.rc" % moduledir,
        "",
        # Test plan writer
        "testplan",
        "",
    ]

    # Test number, start with 1
    seq = 1

    for line in content.split("\n"):
        # Extra spaces and Newline char cleanup
        line = line.strip()

        # Replace pipe char
        line = replace_pipe(line)

        # Update Sequence
        line, seq = sequence_include(line, seq)

        outlines.append(line)

    return "\n".join(outlines)


def parse_write(infile:str, outfile:str) -> None:
    """
    Convert the input file and write to Output file specified
    """
    with open(infile) as inf:
        data = parse(inf.read())
        with open(outfile, "w") as outf:
            outf.write(data)
