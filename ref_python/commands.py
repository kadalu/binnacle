from typing import List, Tuple

CommandOutput = Tuple[int, List[str], List[str]]


def command_hello(node:str, args: List[str], stdin=[]) -> CommandOutput:
    # TODO: Handle node != "local" if required
    return (0, ["Hello", "world"], [])
