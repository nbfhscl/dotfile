#!/usr/bin/env python3

# time tracking hooks for taskwarrior
# define UDA keys as follow:
# Label: key
# Time Estimated: timeest
# Time Spent: timespent
# Time Diff: timediff

from datetime import datetime
from datetime import timedelta
import json
import re
import sys
# from tasklib import TaskWarrior

debug=0

TIME_FORMAT = '%Y%m%dT%H%M%SZ'
TIMEEST = 'timeest'
TIMESPENT = 'timespent'
TIMEDIFF = 'timediff'

# w = TaskWarrior()
# config = w.config

# Convert duration string into a timedelta object.
# Valid formats for duration_str include
# - int (in seconds)
# - string ending in seconds e.g "123seconds"
# - ISO-8601: e.g. "PtimespentH10M31S"
ISO8601DURATION = re.compile(
    "P((\d*)Y)?((\d*)M)?((\d*)D)?T((\d*)H)?((\d*)M)?((\d*)S)?")
def duration_str_to_time_delta(duration_str):
    if (duration_str.startswith("P")):
        match = ISO8601DURATION.match(duration_str)
        if (match):
            year = match.group(2)
            month = match.group(4)
            day = match.group(6)
            hour = match.group(8)
            minute = match.group(10)
            second = match.group(12)
            value = 0
            if (second):
                value += float(second)
            if (minute):
                value += int(minute)*60
            if (hour):
                value += int(hour)*3600
            if (day):
                value += int(day)*3600*24
            if (month):
                # Assume a month is 30 days for now.
                value += int(month)*3600*24*30
            if (year):
                # Assume a year is 365 days for now.
                value += int(year)*3600*24*365
        else:
            value = float(duration_str)
    elif (duration_str.endswith("seconds")):
        value = float(duration_str.rstrip("seconds"))
    else:
        value = float(duration_str)
    return timedelta(seconds=value)

def main():
    original = json.loads(sys.stdin.readline())
    modified = json.loads(sys.stdin.readline())

    if TIMESPENT not in modified: timespent = timedelta(0)
    else: timespent = duration_str_to_time_delta(modified[TIMESPENT])
    if TIMEEST not in modified: timeest = timedelta(0)
    else: timeest = duration_str_to_time_delta(modified[TIMEEST])
    if debug: print("timeest %s, timespent %s" % (timeest, timespent))

    if 'end' not in modified: end = datetime.utcnow()
    else: end = datetime.strptime(modified['end'], TIME_FORMAT)
    entry = datetime.strptime(original['entry'], TIME_FORMAT)

    # # An active task has just been stopped.
    # if 'start' in original and 'start' not in modified:
    #     # Let's see how much time has elapsed
    #     start = datetime.strptime(original['start'], TIME_FORMAT)
    #     timespent += (end - start)
    #     modified[TIMESPENT] = str(timespent.total_seconds()) + "seconds"
    #     print("Time Spent: %s, Total: %s)" % (end-start, timespent) )
    
    # when a task done
    if original['status'] == 'pending' and modified['status'] == 'completed':
        if timeest == timedelta(0) and timespent == timedelta(0):
            print("please provide timespent for task without a timeest")
            exit(1)
        if timespent == timedelta(0): 
            actualtime = end-entry if end-entry<timeest else timeest
            modified[TIMESPENT] = str(actualtime.total_seconds()) + "seconds"

    # calc timediff
    if timespent != timedelta(0) and timeest != timedelta(0):
        timediff = (timespent-timeest)
        modified[TIMEDIFF] = str(timediff.total_seconds()) + "seconds"
        print("Time Diff: %s" % (timediff))

    return print(json.dumps(modified, separators=(',',':')))

main()


# if __name__ == '__main__':
#     cmdline()
