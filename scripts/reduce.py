#!/usr/bin/env python3

import argparse
import subprocess
import logging
import shutil
import os


class FixpointCheck:
    def __init__(self, file, baseline):
        self.file = file
        self.baseline = baseline

    def reached(self):
        return os.path.getsize(self.file) == os.path.getsize(self.baseline)


class Fixpoint:
    def __init__(self, file):
        self.file = file
        self.baseline = '{}.baseline'.format(file)

    def __enter__(self):
        shutil.copy2(self.file, self.baseline)
        return FixpointCheck(self.file, self.baseline)

    def __exit__(self, type, value, traceback):
        os.remove(self.baseline)


def test_file(test, file):
    invocation = [test, file]
    return subprocess.call(
        invocation, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def sanity_check(test, file):
    exit_code = test_file(test, file)
    if exit_code != 0:
        logging.error('Sanity check failed (exit code {})'.format(exit_code))
        return False
    else:
        logging.info('Sanity check passed')
        return True


def log_delta_output(output):
    for line in output.splitlines():
        if 'SUCCESS' in line:
            logging.info(line)


def multi_delta(test, file, levels):
    for i in range(levels):
        logging.info('Running multi-delta level {}'.format(i))
        invocation = ['multidelta', '-level={}'.format(i), test, file]
        output = subprocess.check_output(invocation, stderr=subprocess.STDOUT)
        log_delta_output(output.decode('utf-8'))


def delta(test, file):
    invocation = ['delta', '-test={}'.format(test), '-in_place', file]
    i = 0
    fixpoint_reached = False
    while not fixpoint_reached:
        i += 1
        logging.info('Running delta iteration {}'.format(i))
        with Fixpoint(file) as fixpoint:
            output = subprocess.check_output(
                invocation, stderr=subprocess.STDOUT)
            log_delta_output(output.decode('utf-8'))
            fixpoint_reached = fixpoint.reached()
    logging.info('Delta fixpoint reached')


def clang_format(file):
    invocation = ['clang-format', '-i', '-style=WebKit', file]
    logging.info('Running clang-format')
    subprocess.call(
        invocation, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def creduce(test, file):
    invocation = ['creduce', test, file]
    logging.info('Running creduce')
    output = subprocess.check_output(invocation, stderr=subprocess.STDOUT)


def reduce(test,
           file,
           with_multidelta=False,
           with_clang_format=False,
           with_creduce=False):
    if with_multidelta:
        multi_delta(test, file, 5)

    delta(test, file)

    if with_clang_format:
        clang_format(file)
        delta(test, file)

    if with_creduce:
        creduce(test, file)
        delta(test, file)


def main():
    logging.basicConfig(
        format='%(asctime)s | %(message)s',
        datefmt='%H:%M:%S',
        level=logging.DEBUG)

    parser = argparse.ArgumentParser(
        description=
        "This script wraps several tool to automatically reducing files.")

    parser.add_argument(
        '-s', '--sanity', action='store_true', help="Do sanity check and stop")

    parser.add_argument(
        '-m', '--multi', action='store_true', help="Use multidelta")
    parser.add_argument(
        '-c', '--creduce', action='store_true', help="Use creduce")
    parser.add_argument(
        '-f', '--format', action='store_true', help="Use clang-format")

    parser.add_argument("test", help="the test script", type=str)
    parser.add_argument("file", help="the file to reduce", type=str)

    args = parser.parse_args()

    # Always run the sanity check. Don't do anything if it fails.
    if not sanity_check(args.test, args.file):
        exit(1)

    # Finish if only a sanity check was requested.
    if args.sanity:
        exit(0)

    # Run the different reducers.
    reduce(args.test, args.file, args.multi, args.format, args.creduce)


if __name__ == "__main__":
    main()
