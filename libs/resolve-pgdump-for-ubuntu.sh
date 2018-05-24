#!/usr/bin/env bash

# use environment FORCE_RESOLVE_PGDUMP=yes to force executing resolve flow.

# checkout to directory same with this script
command pushd `cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd` > /dev/null;

# install color variables
source ../src/style_print.sh

function getUbuntuVersionID() {
	cat /etc/os-release |
		tr "=\"'" '   ' | # replace "'= to blank space
		awk '/^VERSION_ID/ {print $2}';
}
function getUbuntuCodeName() {
	cat /etc/os-release |
		tr "=\"'" '   ' | # replace "'= to blank space
		awk '/^VERSION_CODENAME/ {print $2}';
}

function resolvePGDumpForUbuntu() {
	if [[ -n `which pg_dump` ]]; then
		print_done "pg_dump has been installed before execute this script!";
		if [[ "$FORCE_RESOLVE_PGDUMP" != "yes" ]]; then
			return;
		fi
	fi

	# ====================================================================================
	print_doing "Verifying System information ...";
	local IS_UBUNTU  TMP_FILE  EXPECTED_KEY  EXPECTED_LIST_FILE   PGSQL_HTML_URL;
	TMP_FILE="/tmp/install-pgdump.html"
	EXPECTED_KEY="www.postgresql.org/media/keys/ACCC4CF8.asc";
	EXPECTED_LIST_FILE="/etc/apt/sources.list.d/pgdg.list";
	PGSQL_HTML_URL="https://www.postgresql.org/download/linux/ubuntu/";

	if [[ ! -f "/etc/os-release" ]]; then
		print_warning "\"resolve-pgdump-for-ubuntu.sh\" should be only use on ubuntu!"
		return;
	fi
	IS_UBUNTU=`cat /etc/os-release | awk '/^NAME/' | awk '/Ubuntu/'`;
	if [[ -z "$IS_UBUNTU" ]]; then
		print_warning "\"resolve-pgdump-for-ubuntu.sh\" should be only use on ubuntu!"
		return;
	fi
	local OS_VER;
	OS_VER=`getUbuntuVersionID`;
	if [[ "$OS_VER" != "14.04" ]] && [[ "$OS_VER" != "16.04" ]] && [[ "$OS_VER" != "18.04" ]]; then
		print_fatal_exit_1 "Your Ubuntu version ($OS_VER) is not supported to install PostgreSQL via package mangement!"
	fi

	# ====================================================================================
	print_doing "Fetching PostgreSQL install guide page ...";
	if [[ -f "$TMP_FILE" ]]; then rm "$TMP_FILE"; fi
	curl --fail -Lo $TMP_FILE "$PGSQL_HTML_URL" ||
		print_fatal_exit_1 "Could not fetch $PGSQL_HTML_URL";

	# ====================================================================================
	print_doing "Validating PostgreSQL public key and source list is latest ...";
	# Verify PostgreSQL key
	local MATCHED;
	MATCHED=`grep $TMP_FILE -e $EXPECTED_KEY`;
	[[ -z "$MATCHED" ]] && print_fatal_exit_1 "Could not match key \"$EXPECTED_KEY\" in \"$PGSQL_HTML_URL\"!";

	MATCHED=`grep $TMP_FILE -e $EXPECTED_LIST_FILE`;
	[[ -z "$MATCHED" ]] && print_fatal_exit_1 "Could not match list file \"$EXPECTED_LIST_FILE\" in \"$PGSQL_HTML_URL\"!";
	rm "$TMP_FILE";

	# ====================================================================================
	print_doing "Importing the public key used by the package management system ...";
	print_info "sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv $EXPECTED_KEY";
	wget --quiet -O - "https://$EXPECTED_KEY" | sudo apt-key add - ||
		print_fatal_exit_1 "Could not import the public key!";

	# ====================================================================================
	print_doing "Create a list file for PostgreSQL ...";
	local CTX;
	CTX="deb http://apt.postgresql.org/pub/repos/apt/ $(getUbuntuCodeName)-pgdg main";
	print_info "echo \"$CTX\" | sudo tee $EXPECTED_LIST_FILE";
	echo "$CTX" | sudo tee $EXPECTED_LIST_FILE ||
		print_fatal_exit_1 "Could not create list file for PostgreSQL!";

	# ====================================================================================
	print_doing "Updating apt-get ...";
	sudo apt-get update || print_warning "sudo apt-get update failed!";

	# ====================================================================================
	print_doing "sudo apt-get install -y postgresql-client-10 ...";
	sudo apt-get install -y postgresql-client-10 ||
		print_fatal_exit_1 "install postgresql-client-10 failed!";

	print_all_done "Installed pg_dump for this computer!";
}

resolvePGDumpForUbuntu;

# restore directory path
command popd > /dev/null;
