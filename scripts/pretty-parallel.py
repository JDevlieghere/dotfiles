#!/usr/bin/env python3

import argparse
import subprocess
import sys
import multiprocessing
import logging

from rich.progress import Progress
from rich.logging import RichHandler
from concurrent.futures import ThreadPoolExecutor

log = logging.getLogger(__name__)


def run(command):
    res = subprocess.run(command,
                         stdout=subprocess.PIPE,
                         stderr=subprocess.STDOUT,
                         check=False,
                         shell=True)
    return res


def main():
    # Set up logging.
    logging.basicConfig(level="NOTSET",
                        format="%(message)s",
                        datefmt="[%X]",
                        handlers=[RichHandler()])

    # Parse arguments.
    parser = argparse.ArgumentParser(
        description="Run multiple commands in parallel and show progress")
    parser.add_argument('commands', type=str, nargs='+', help='command to run')
    args = parser.parse_args()

    commands = args.commands
    max_workers = multiprocessing.cpu_count()
    futures = []
    num_errors = 0

    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        with Progress() as progress:
            tasks = []
            main_task = progress.add_task(
                f'Executing {len(commands)} commands')

            # Create a task and future for each job.
            for command in commands:
                tasks.append(progress.add_task(f'Executing \'{command}\''))
                futures.append(executor.submit(run, command))

            # Update progress
            while True:
                finished = sum([future.done() for future in futures])

                # Update the main tasks
                progress.update(main_task,
                                completed=finished,
                                total=len(futures))

                # Update the subtasks
                for i in range(len(futures)):
                    task = tasks[i]
                    future = futures[i]
                    if future.done() and future.result().returncode == 0:
                        progress.update(task, completed=1, total=1)

                # Check if we're done.
                if finished == len(futures):
                    break

    # Deal with errors.
    for i in range(len(futures)):
        command = commands[i]
        result = futures[i].result()
        if result.returncode != 0:
            num_errors += 1
            stdout = result.stdout.decode('utf-8').strip()
            log.error(f'Failed to clone {command}:\n{stdout}')

    # The exit code indicates the number of errors.
    return num_errors


if __name__ == '__main__':
    sys.exit(main())
