#!/usr/bin/env python3

import json
import subprocess
import sys

debug=0;

def main():
    original = json.loads(sys.stdin.readline())
    modified = json.loads(sys.stdin.readline())

    # An inactive task has just been started.
    if 'start' in modified and 'start' not in original:
        # Check if `task +ACTIVE count` is greater than MAX_ACTIVE. If so
        # prevent this task from starting.
        p = subprocess.Popen(
            ['task', '+ACTIVE', 'status:pending', 'count', 'rc.verbose:off'],
            stdout=subprocess.PIPE)
        out, _ = p.communicate()
        count = int(out.rstrip())
        if (not debug and count >= 1):
            print("No one could actually handle more than one task at a time!")
            sys.exit(1)

    return print(json.dumps(modified, separators=(',',':')))

main()

