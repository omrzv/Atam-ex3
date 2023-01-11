# ATAM Wet 3 Tests

These are some minimal tests that attempt to cover most reasonable simple cases.

## Part 1

### How to Run Part 1 Tests

1. Copy `build.sh`, `test.sh`, `test_files/` into your `part1` directory
   (or alternatively, copy your `hw3_part1.c` and `elf64.h` to the tests'
   `part1` directory).
2. Make sure the scripts have execute permissions (`chmod +x *.sh`)
3. Run `./test.sh`

## Part 2

### How to Run Part 2 Tests

1. Copy `build.sh`, `run.sh`, `run-all.sh`, `examples/` into your `part2`
   directory (or alternatively, copy your `hw3_part2.ld` to the tests' `part2`
   directory).
2. Make sure the scripts have execute permissions (`chmod +x *.sh`)
3. Run `./run-all.sh` to run all tests or `./run.sh examples/TEST_NAME.s` to run
   a specific tests.

### How to Add More Tests

Add a new assembly file (named `YOUR_TEST_NAME.s`) or a directory with files in
it to the examples directory.

## Misc

The tests leave the binary files they work with if they fail and print the
commands being executed to help with debugging.
