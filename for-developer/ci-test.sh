#!/usr/bin/env bash

function throw () { echo "fatal: $1"; echo "exit 1"; exit 1; }

function print_system_release() {
	if [[ -f "/etc/os-release" ]]; then
		echo "[.] cat /etc/os-release";
		cat /etc/os-release;
	fi

	echo "[.] which tar";
	which tar;

	echo "[.] which jq";
	which jq;
}

function main() {
	echo "[.] testing ../libs/resolve-mongodump-for-ubuntu.sh ...";
	env FORCE_RESOLVE_MONGODUMP=yes ../libs/resolve-mongodump-for-ubuntu.sh || exit 1;

	echo "[.] testing ../libs/resolve-pgdump-for-ubuntu.sh ...";
	env FORCE_RESOLVE_PGDUMP=yes ../libs/resolve-pgdump-for-ubuntu.sh || exit 1;

	echo "[.] testing ../libs/resolve-mysqldump-for-ubuntu.sh ...";
	env FORCE_RESOLVE_MYSQLDUMP=yes PERFECT_MYSQLDUMP_CLIENT=mariadb-client ../libs/resolve-mysqldump-for-ubuntu.sh || exit 1;

	echo "[.] testing ../libs/resolve.sh ...";
	bash ../libs/resolve.sh || exit 1;

	echo "[.] testing ../libs/gdrive ...";
	# gdrive binary file on travis-ci osx environment will throw an exception from binary program inside
	if [[ "$TRAVIS_OS_NAME" != "osx" ]]; then
		../libs/gdrive help > /dev/null || echo "gdrive is invalid!"; # exit 1;
	fi

	echo "[.] testing jq ...";
	jq --version || exit 1;

	echo "[.] testing curl ...";
	curl --version || exit 1;
}

# =============================
pushd "$( dirname "${BASH_SOURCE[0]}" )";
print_system_release;
main;
echo "[+] ci-test.sh done!";
exit 0;
