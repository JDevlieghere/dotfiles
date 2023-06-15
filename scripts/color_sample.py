#!/usr/bin/python3
"""
usage: color_sample.py [-h] [file]

Color a call tree file generated by sample

positional arguments:
  file        sample file

optional arguments:
  -h, --help  show this help message and exit
"""

import re
import argparse
import fileinput
import bisect

END_MARKER = "Total number in stack"
BEGIN_MARKER = "Call graph:"
REGEX = re.compile(r"^\D*(\d+)")


def fg(r, g, b):
    """Change foreground color."""
    return "\033[38;2;{:d};{:d};{:d}m".format(r, g, b)


def reset():
    """Reset foreground color."""
    return "\033[0m"


def rgb(minimum, maximum, value):
    """Convert value within range to RGB."""
    assert value <= maximum
    assert value >= minimum
    minimum, maximum = float(minimum), float(maximum)
    r = 2 * (value - minimum) / (maximum - minimum)
    b = int(max(0, 255 * (1 - r)))
    r = int(max(0, 255 * (r - 1)))
    g = 255 - b - r
    return r, g, b


def binary_find(a, x):
    """Find value in sorted list."""
    i = bisect.bisect_left(a, x)
    if i != len(a) and a[i] == x:
        return i
    return -1


def get_all_samples(lines):
    """Compute a list of all samples."""
    parsing = False
    samples = []
    for line in lines:
        if BEGIN_MARKER in line:
            parsing = True
            continue

        if END_MARKER in line:
            break

        if not parsing:
            continue

        match = re.match(REGEX, line)
        if not match:
            continue

        samples.append(int(match.group(1)))

    return sorted(set(samples))


def color(lines, all_samples):
    """Color the call tree based on the amount of samples for each branch."""
    minimum = 0
    maximum = len(all_samples)
    coloring = False
    for line in lines:
        if BEGIN_MARKER in line:
            coloring = True

        if END_MARKER in line:
            coloring = False

        if not coloring:
            print(line)
            continue

        match = re.match(REGEX, line)
        if not match:
            print(line)
            continue

        samples = int(match.group(1))
        value = binary_find(all_samples, samples)
        r, g, b = rgb(minimum, maximum, value)
        print(fg(r, g, b) + line + reset())


def main():
    """Color a call tree file generated by sample."""
    parser = argparse.ArgumentParser(
        description="Color a call tree file generated by sample"
    )
    parser.add_argument("file", nargs="?", help="sample file")
    args = parser.parse_args()

    with fileinput.input(args.file) as file:
        lines = []
        for line in file:
            lines.append(line.rstrip())
        color(lines, get_all_samples(lines))


if __name__ == "__main__":
    main()
