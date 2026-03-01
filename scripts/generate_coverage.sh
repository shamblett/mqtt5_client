#!/usr/bin/env bash
#
# Generate test coverage
#
dart pub global run coverage:test_with_coverage
cd coverage || exit
genhtml lcov.info -o coverage --no-function-coverage -s -p "$(pwd)"
