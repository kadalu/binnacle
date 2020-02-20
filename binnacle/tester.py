import os
import sys

from binnacle import testutils


def main():
    node = os.environ.get("NODE", None)
    subcmd = sys.argv[1]
    func = getattr(testutils, "handle_%s" % subcmd, None)
    if func is None:
        print("Invalid subcommand", file=sys.stderr)
        sys.exit(1)

    func(node, sys.argv[2:])


if __name__ == "__main__":
    main()
