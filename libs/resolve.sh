#!/usr/bin/env bash

#
# Resolve third-part libraries script
#  (resolve dependencies)
#

GDRIVE_GITHUB="https://github.com/prasmussen/gdrive"
GDRIVE_DESC="Google Drive CLI Client";
GDRIVE_VERSION="2.1.0";
GDRIVE_DL_LIST='https://github.com/prasmussen/gdrive#downloads'

GDRIVE_BIN="gdrive"

GDRIVE_OSX_64='https://docs.google.com/uc?id=0B3X9GlR6Embnb010SnpUV0s2ZkU&export=download'
GDRIVE_OSX_32='https://docs.google.com/uc?id=0B3X9GlR6EmbnTjByNlNvZVNRTjQ&export=download'

GDRIVE_LINUX_64='https://docs.google.com/uc?id=0B3X9GlR6EmbnQ0FtZmJJUXEyRTA&export=download'
GDRIVE_LINUX_32='https://docs.google.com/uc?id=0B3X9GlR6EmbnLV92dHBpTkFhTEU&export=download'

GDRIVE_URL=''; # it will be load by function get_gdrive_download_url
GDRIVE_URL_DESC='';

function get_gdrive_download_url() {
	GDRIVE_URL=''; # reset
	GDRIVE_URL_DESC='Unknwon';

	local OS ARCH OSX;
	OSX=false;

	OS=`uname -s`;
	case "$OS" in
		"Darwin") OSX=true; ;;
		"Linux") OSX=false; ;;
		*) return;
	esac

	ARCH=`uname -m`;
	case "$ARCH" in
	    "x86_64")
			if [[ "$OSX" == "true" ]]; then
				GDRIVE_URL="$GDRIVE_OSX_64";
				GDRIVE_URL_DESC="osx-x64";
			else
				GDRIVE_URL="$GDRIVE_LINUX_64";
				GDRIVE_URL_DESC="linux-x64";
			fi
			;;
		"i386" | "i486" | "i586" | "i686")
			if [[ "$OSX" == "true" ]]; then
				GDRIVE_URL="$GDRIVE_OSX_32";
				GDRIVE_URL_DESC="osx-386";
			else
				GDRIVE_URL="$GDRIVE_LINUX_32";
				GDRIVE_URL_DESC="linux-386";
			fi
			;;
		*) return;
	esac
}

function installViaPackageManagement() {
	local PKG_MAN PKG_OPT NAME URL;
	NAME="$1"; URL="$2";

	print_doing "installing \"$NAME\" (Command-line JSON processor)";

	PKG_MAN=""; PKG_OPT="install -y";
	if [[ -n `which apt-get` ]]; then PKG_MAN="apt-get"; # Ubuntu/Debian
	elif [[ -n `which dnf` ]]; then PKG_MAN="dnf"; # Fedora
	elif [[ -n `which zypper` ]]; then PKG_MAN="zypper"; # openSUSE
	elif [[ -n `which pacman` ]]; then PKG_MAN="pacman"; PKG_OPT="-Sy"; # Arch
	elif [[ `uname -s` == "Darwin" ]]; then
		if [[ -z `which brew` ]]; then
			print_fatal_exit_1 "brew is missing! [Homebrew](https://brew.sh/)";
		fi
		PKG_MAN="brew"; PKG_OPT="install";
	fi

	if [[ -z "$PKG_MAN" ]]; then
		print_fatal_exit_1 "could not found any package manager in this computer to install \"$NAME\"" \
			"\n             please download $NAME manuualy from:" \
			"\n\n             $URL\n"
	fi

	# ======================================================================================
	print_doing "sudo $PKG_MAN $PKG_OPT $NAME";
	_CODE="1";
	if [[ "$PKG_MAN" == "brew" ]]; then
		$PKG_MAN $PKG_OPT $NAME; _CODE="$?";
	else
		sudo $PKG_MAN $PKG_OPT $NAME; _CODE="$?";
	fi
	if [[ "$_CODE" != "0" ]]; then print_fatal_exit_1 "install \"$NAME\" failed!"; fi
	print_done "installed \"$NAME\"!";
}

# checkout to directory same with this script
__DIRNAME=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`;
pushd "$__DIRNAME" > /dev/null;

# install color variables
source ../src/style_print.sh


[[ -z `which jq` ]] && installViaPackageManagement "jq" "https://stedolan.github.io/jq/download/";
[[ -z `which curl` ]] && installViaPackageManagement "curl" "https://curl.haxx.se/download.html";

if [[ ! -x "$GDRIVE_BIN" ]]; then
	# ======================================================================================
	print_doing "resolving \"gdrive\" [${GDRIVE_DESC} ${GDRIVE_VERSION}](${GDRIVE_GITHUB})";

	get_gdrive_download_url;
	print_info "uname: $DIM$(uname -a)";
	print_info "matched gdrive: $DIM$GDRIVE_URL_DESC";
	if [[ -z "$GDRIVE_URL" ]]; then
		print_fatal_exit_1 "could not match any gdrvie binary file from" \
			"\"osx-x64\", \"osx-386\", \"linux-x64\", \"linux-386\",  " \
			"\n             please download binary file manuualy from:" \
			"\n\n             ${GDRIVE_DL_LIST}" \
			"\n\n             and put binary file \"gdriver-***-***\" into \"libs/gdriver\" \n"
	fi

	# ======================================================================================
	print_doing "downloading $GDRIVE_URL";
	# --location: follow Google Drive redirect
	curl --fail --location --output "$GDRIVE_BIN" "$GDRIVE_URL" ||
		print_fatal_exit_1 "download failed!";
	print_done "downloaded \"$GDRIVE_BIN\"";

	# ======================================================================================
	print_doing "chmod +x $GDRIVE_BIN (executable)";
	chmod +x "$GDRIVE_BIN" || print_fatal_exit_1 "chmod +x failed!";
fi


print_all_done "resolved all thrid-party libraries";
# restore directory path
popd > /dev/null;
