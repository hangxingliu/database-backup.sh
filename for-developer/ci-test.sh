#!/usr/bin/env bash

function throw () { echo "fatal: $1"; echo "exit 1"; exit 1; }

function print_system_release() {
	echo "[.] cat /etc/os-release";
	cat /etc/os-release;

	echo "[.] which tar";
	which tar;

	echo "[.] which jq";
	which jq;
}

function main() {
	echo "[.] testing ../libs/resolve.sh ...";
	bash ../libs/resolve.sh || exit 1;

	echo "[.] testing ../libs/gdrive ...";
	../libs/gdrive help >/dev/null || exit 1;

	echo "[.] testing jq ...";
	jq --version || exit 1;
}

# =============================
pushd "$( dirname "${BASH_SOURCE[0]}" )";
print_system_release;
main;
echo "ci-test.sh done!";
exit 0;
