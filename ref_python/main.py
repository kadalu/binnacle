import os
import sys
from argparse import ArgumentParser

from binnacle import testparser, testutils


def get_args():
    parser = ArgumentParser()
    parser.add_argument(
        "testfile",
        help="Test input File"
    )
    parser.add_argument(
        "--prove-command",
        default="prove",
        help="Prove command Path"
    )
    parser.add_argument(
        "-v", "--verbose",
        help="Verbose output",
        action="store_true"
    )
    return parser.parse_args()


def main():
    try:
        args = get_args()
        testsdir = os.path.dirname(args.testfile)
        try:
            os.makedirs(os.path.join(testsdir, ".run"))
        except FileExistsError:
            pass

        newpath = os.path.join(testsdir, ".run", os.path.basename(
            args.testfile))
        testparser.parse_write(
            args.testfile,
            newpath
        )
        cmd = [args.prove_command]
        if args.verbose:
            cmd.append("-v")
        cmd.append(newpath)
        os.system(" ".join(cmd))
    except KeyboardInterrupt:
        sys.exit(1)


if __name__ == "__main__":
    main()
