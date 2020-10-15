#! /usr/bin/env bash
# vim: set filetype=sh ts=4 sw=4 sts=4 et:

basedir=$(readlink -f "$(dirname "$0")"/../../..)
# shellcheck source=lib/shell/colors.inc
. "$basedir"/lib/shell/colors.inc

cd "$(dirname "$0")" || exit 1

targets=$(./docker_build_and_run_tests.sh --list-targets)

printf '%b%b%b\n' "$WHITE_ON_BLUE" "============================================================" "$NOC"
printf '%b%b%b\n' "$WHITE_ON_BLUE" "Testing all targets in parallel, ensure you have enough RAM!" "$NOC"
printf '%b%b%b\n' "$WHITE_ON_BLUE" "============================================================" "$NOC"
echo "Targets: $targets"

sleep 5

for t in $targets
do
    (
        rm -f "/tmp/.$t"
        DOCKER_TTY=false ./docker_build_and_run_tests.sh "$t"
        echo $? > "/tmp/.$t"
    ) &
done
wait

echo

nberrors=0

for t in $targets
do
    err=$(cat "/tmp/.$t" 2>/dev/null)
    rm -f "/tmp/.$t"
    if [ -z "$err" ]; then
        printf "%b%15s: tests couldn't run properly%b\\n" "$BLACK_ON_RED" "$t" "$NOC"
        nberrors=$(( nberrors + 1 ))
    elif [ "$err" = 0 ]; then
        printf "%b%15s: no errors :)%b\\n" "$BLACK_ON_GREEN" "$t" "$NOC"
    elif [ "$err" = 143 ]; then
        printf "%b%15s: tests interrupted%b\\n" "$BLACK_ON_RED" "$t" "$NOC"
        nberrors=$(( nberrors + 1 ))
    elif [ "$err" -lt 254 ]; then
        printf "%b%15s: $err tests failed%b\\n" "$BLACK_ON_RED" "$t" "$NOC"
        nberrors=$(( nberrors + 1 ))
    else
        printf "%b%15s: $err errors%b\\n" "$BLACK_ON_RED" "$t" "$NOC"
        nberrors=$(( nberrors + 1 ))
    fi
done

exit "$nberrors"
