#!/bin/sh
# shellcheck shell=dash
# shellcheck disable=SC2039  # local is non-POSIX
# shellcheck disable=SC2268  # no harm in supporting older shells

has_local() {
    # shellcheck disable=SC2034  # deliberately unused
    local _has_local
}

has_local 2>/dev/null || alias local=typeset

set -u

echo "Hello Test"