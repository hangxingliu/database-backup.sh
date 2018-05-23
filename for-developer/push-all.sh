#!/usr/bin/env bash

# checkout to directory same with this script
command pushd `cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd` > /dev/null;
command pushd .. > /dev/null;

source ./src/style_print.sh

git remote | while read REMOTE; do
	print_doing "Pushing into \"${REMOTE}\"";
	git push --all "${REMOTE}" || print_fatal_exit_1 "Could not push to \"${REMOTE}\" ";
	print_done "Pushed to \"${REMOTE}\"";
done

print_all_done "Pushed to all git remotes!";
