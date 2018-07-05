#!/usr/bin/env bash

# use environment variable FORCE_RESOLVE_MYSQLDUMP=yes to force executing resolve flow.
# use environment variable PERFECT_MYSQLDUMP_CLIENT=mariadb-client to force choose apt package for mysqldump

APT_PACKAGE_NAME_MYSQL="mysql-client";
APT_PACKAGE_NAME_MARIADB="mariadb-client";
BINARY_NAME="mysqldump";

# checkout to directory same with this script
__DIRNAME=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`;
pushd "$__DIRNAME" > /dev/null;

# install color variables
source ../src/style_print.sh

function getUbuntuVersionID() {
	cat /etc/os-release |
		tr "=\"'" '   ' | # replace "'= to blank space
		awk '/^VERSION_ID/ {print $2}';
}
function getUbuntuCodeName() {
	if [[ -f "/etc/lsb-release" ]]; then
		cat /etc/lsb-release |
			tr "=\"'" '   ' | # replace "'= to blank space
			awk '/^DISTRIB_CODENAME/ {print $2}';
	fi
}

function resolveMySQLDumpForUbuntu() {
	if [[ -n `which ${BINARY_NAME}` ]]; then
		print_done "${BINARY_NAME} has been installed before execute this script!";
		if [[ "$FORCE_RESOLVE_MYSQLDUMP" != "yes" ]]; then
			return;
		fi
	fi

	# ====================================================================================
	print_doing "Verifying System information ...";
	local IS_UBUNTU;
	if [[ ! -f "/etc/os-release" ]]; then
		print_warning "\"resolve-mysql-for-ubuntu.sh\" should be only use on ubuntu!"
		return;
	fi
	IS_UBUNTU=`cat /etc/os-release | awk '/^NAME/' | awk '/Ubuntu/'`;
	if [[ -z "$IS_UBUNTU" ]]; then
		print_warning "\"resolve-mysql-for-ubuntu.sh\" should be only use on ubuntu!"
		return;
	fi

	# ====================================================================================
	if [[ -n "$PERFECT_MYSQLDUMP_CLIENT" ]]; then
		print_info "use package name \"$PERFECT_MYSQLDUMP_CLIENT\" from environment variable: \$PERFECT_MYSQLDUMP_CLIENT";
		APT_PACKAGE="$PERFECT_MYSQLDUMP_CLIENT";
	else
		print_doing "Choose the client you want to install:"
		local CLIENT_ID APT_PACKAGE;
		print_info "[1] $APT_PACKAGE_NAME_MYSQL (by default)";
		print_info "[2] $APT_PACKAGE_NAME_MARIADB";
		read -p "input the client id you want to install (1/2) > " CLIENT_ID;
		[[ -z "$CLIENT_ID" ]] && CLIENT_ID=1;

		if [[ "$CLIENT_ID" == 1 ]]; then    APT_PACKAGE="$APT_PACKAGE_NAME_MYSQL";
		elif [[ "$CLIENT_ID" == 2 ]]; then  APT_PACKAGE="$APT_PACKAGE_NAME_MARIADB";
		else print_fatal_exit_1 "invalid client id: \"$CLIENT_ID\" "; fi
	fi

	# ====================================================================================
	print_doing "Checking sudo ...";
	if [[ -z `which sudo` ]]; then
		print_doing "Installing sudo ...";
		apt-get update && apt-get install -y sudo;
		[[ "$?" != 0 ]] && print_fatal_exit_1 "\"apt-get install -y sudo\" failed!";
	else
		print_doing "Updating apt-get ...";
		sudo apt-get update || print_warning "sudo apt-get update failed!";
	fi

	# ====================================================================================
	print_doing "sudo apt-get install -y ${APT_PACKAGE} ...";
	sudo apt-get install -y ${APT_PACKAGE} ||
		print_fatal_exit_1 "install ${APT_PACKAGE} failed!";

	print_all_done "Installed ${BINARY_NAME} for this computer!";
}

resolveMySQLDumpForUbuntu;

# restore directory path
popd > /dev/null;
