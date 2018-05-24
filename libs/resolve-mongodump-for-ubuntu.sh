#!/usr/bin/env bash

# use environment FORCE_RESOLVE_MONGODUMP=yes to force executing resolve flow.

# checkout to directory same with this script
command pushd `cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd` > /dev/null;

# install color variables
source ../src/style_print.sh

function getUbuntuVersionID() {
	cat /etc/os-release |
		tr "=\"'" '   ' | # replace "'= to blank space
		awk '/^VERSION_ID/ {print $2}';
}
function getComparableUbuntuVersionID() {
	cat /etc/os-release |
		tr "=\"'." '   0' | # replace "'= to blank space, and replace . to 0 (18.04 => 18004)
		awk '/^VERSION_ID/ {print $2}';
}

function resolveMongoDumpForUbuntu() {
	if [[ -n `which mongodump` ]]; then
		print_done "mongodump has been installed before execute this script!";
		if [[ "$FORCE_RESOLVE_MONGODUMP" != "yes" ]]; then
			return;
		fi
	fi

	# ====================================================================================
	print_doing "Verifying System information ...";
	local IS_UBUNTU  TMP_FILE  EXPECTED_KEY  EXPECTED_LIST_FILE   MONGODB_HTML_URL;
	TMP_FILE="/tmp/install-mongodump.html"
	EXPECTED_KEY="2930ADAE8CAF5059EE73BB4B58712A2291FA4AD5";
	EXPECTED_LIST_FILE="/etc/apt/sources.list.d/mongodb-org-3.6.list";
	MONGODB_HTML_URL="https://docs.mongodb.com/manual/tutorial/install-mongodb-on-ubuntu/";

	if [[ ! -f "/etc/os-release" ]]; then
		print_warning "\"resolve-mongodump-for-ubuntu.sh\" should be only use on ubuntu!"
		return;
	fi
	IS_UBUNTU=`cat /etc/os-release | awk '/^NAME/' | awk '/Ubuntu/'`;
	if [[ -z "$IS_UBUNTU" ]]; then
		print_warning "\"resolve-mongodump-for-ubuntu.sh\" should be only use on ubuntu!"
		return;
	fi
	local OS_VER OS_VER_COMPARE;
	OS_VER=`getUbuntuVersionID`;
	OS_VER_COMPARE=`getComparableUbuntuVersionID`;
	if [[ -z "$OS_VER_COMPARE" ]] || [[ "$OS_VER_COMPARE" -lt 14004 ]]; then
		print_fatal_exit_1 "Your Ubuntu version ($OS_VER) is too old to install MongoDB via package mangement!"
	fi

	# ====================================================================================
	print_doing "Fetching MongoDB install guide page ...";
	if [[ -f "$TMP_FILE" ]]; then rm "$TMP_FILE"; fi
	curl --fail -Lo $TMP_FILE "$MONGODB_HTML_URL" ||
		print_fatal_exit_1 "Could not fetch $MONGODB_HTML_URL";

	# ====================================================================================
	print_doing "Validating MongoDB public key and source list is latest ...";
	# Verify MongoDB key
	local MATCHED;
	MATCHED=`grep $TMP_FILE -e $EXPECTED_KEY`;
	[[ -z "$MATCHED" ]] && print_fatal_exit_1 "Could not match key \"$EXPECTED_KEY\" in \"$MONGODB_HTML_URL\"!";

	MATCHED=`grep $TMP_FILE -e $EXPECTED_LIST_FILE`;
	[[ -z "$MATCHED" ]] && print_fatal_exit_1 "Could not match list file \"$EXPECTED_LIST_FILE\" in \"$MONGODB_HTML_URL\"!";
	rm "$TMP_FILE";

	# ====================================================================================
	print_doing "Importing the public key used by the package management system ...";
	print_info "sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv $EXPECTED_KEY";
	sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv $EXPECTED_KEY ||
		print_fatal_exit_1 "Could not import the public key!";

	# ====================================================================================
	print_doing "Create a list file for MongoDB ...";
	local CTX;
	CTX="deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.6 multiverse";
	if [[ $OS_VER_COMPARE -lt 16004 ]]; then
		# for 14.04
		CTX="deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.6 multiverse";
	fi
	print_info "echo \"$CTX\" | sudo tee $EXPECTED_LIST_FILE";
	echo "$CTX" | sudo tee $EXPECTED_LIST_FILE ||
		print_fatal_exit_1 "Could not create list file for MongoDB!";

	# ====================================================================================
	print_doing "Updating apt-get ...";
	sudo apt-get update || print_warning "sudo apt-get update failed!";

	# ====================================================================================
	print_doing "sudo apt-get install -y mongodb-org-tools ...";
	sudo apt-get install -y mongodb-org-tools ||
		print_fatal_exit_1 "install mongodb-org-tools failed!";

	print_all_done "Installed mongodump for this computer!";
}

resolveMongoDumpForUbuntu;

# restore directory path
command popd > /dev/null;
