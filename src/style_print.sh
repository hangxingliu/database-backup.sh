#!/usr/bin/env bash

if [[ -t 1 ]]; then # is terminal?
	COLOR_MODE=`tput colors`;
	if [[ -n "$COLOR_MODE" ]] && [[ "$COLOR_MODE" -ge 8 ]]; then
		# using \x1b but not \e is for gawk

		BOLD="\x1b[1m";
		DIM="\x1b[2m";
		ITALIC="\x1b[3m";
		UNDERLINE="\x1b[4m";
		RESET="\x1b[0m";

		RED="\x1b[31m";
		GREEN="\x1b[32m";
		YELLOW="\x1b[33m";
		BLUE="\x1b[34m";
		PURPLE="\x1b[35m";
		CYAN="\x1b[36m";
		GREY="\x1b[37m";

		BG_WHITE="\x1b[107m\x1b[48;5;231m"; # it actual is dark grey # rgb8 and rgb256
	fi
fi

function print_doing() {
	echo -e "$BOLD$CYAN[.] $*$RESET";
}

function print_done() {
	echo -e "$GREEN$BOLD[~] $*$RESET";
}

function print_all_done() {
	echo -e "$GREEN$BG_WHITE$BOLD[+] $*$RESET";
}

function print_info() {
	echo -e "    $CYAN$*$RESET";
}

function print_warning() {
	echo -e "$YELLOW$BOLD    warning:$RESET$YELLOW $*$RESET";
}

function print_error() {
	echo -e "$RED$BOLD[-] error:$RESET$RED $*$RESET";
}

function print_fatal_exit_1() {
	echo -e "$RED$BOLD[-] fatal:$RESET$RED $*$RESET";
	echo -e "${RED}exit with code 1$RESET";
	exit 1;
}

