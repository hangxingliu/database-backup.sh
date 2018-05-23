#!/usr/bin/env bash

# MongoDB backup script
#
# Example:
#
#    ./backup-mongodb                                       # backup prefix is "mongodb-"
#    ./backup-mongodb --name "mike-mongodb"                 # backup prefix is "mike-mongodb-"
#    ./backup-mongodb --host "192.168.1.8" --port 37017
#    ./backup-mongodb --host "192.168.1.8" --port 37017 --username "admin" --password "admimmm"
#
# More Options:
#
#    --date      date format, "+%Y-%m-%d-%H-%M" by default
#

MONGODUMP="mongodump";
DUMP_OPTS="";
GOOGLE_DRIVER="./libs/gdrive";
TMP_DIR="/tmp/backup-mongodb-to-gdrive";
BACKUP_PREFIX="mongodb";
DATE_FORMAT="+%Y-%m-%d-%H-%M";

# checkout to directory same with this script
command pushd `cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd` > /dev/null;

source ./src/style_print.sh;
source ./src/user_config.sh;
source ./src/get_google_access_token.sh;

HAVE_YOU_RESOLVE="(have you resolve dependencies by script \"./libs/resolve.sh\" ?)";
[[ -z `which $MONGODUMP` ]] && print_fatal_exit_1 "\"$MONGODUMP\" is not installed!";
[[ -z `which tar` ]] && print_fatal_exit_1 "\"tar\" is not installed!";
[[ -z `which jq` ]] &&
	print_fatal_exit_1 "\"jq\" is not installed! $HAVE_YOU_RESOLVE";
[[ -x "$GOOGLE_DRIVER" ]] ||
	print_fatal_exit_1 "\"$GOOGLE_DRIVER\" is missing! $HAVE_YOU_RESOLVE";



#   ____                           _                                         _
#  |  _ \ __ _ _ __ ___  ___      / \   _ __ __ _ _   _ _ __ ___   ___ _ __ | |_ ___
#  | |_) / _` | '__/ __|/ _ \    / _ \ | '__/ _` | | | | '_ ` _ \ / _ \ '_ \| __/ __|
#  |  __/ (_| | |  \__ \  __/   / ___ \| | | (_| | |_| | | | | | |  __/ | | | |_\__ \
#  |_|   \__,_|_|  |___/\___|  /_/   \_\_|  \__, |\__,_|_| |_| |_|\___|_| |_|\__|___/
#                                           |___/
arg_name="";
for argument in "$@"; do
	if [[ -n "$arg_name" ]]; then
		case "$arg_name" in
			--host) DUMP_OPTS="$DUMP_OPTS -h $argument " ;;
			--port) DUMP_OPTS="$DUMP_OPTS --port $argument " ;;
			--username) DUMP_OPTS="$DUMP_OPTS -u $argument " ;;
			--password) DUMP_OPTS="$DUMP_OPTS -p $argument " ;;

			--name) BACKUP_PREFIX="$argument"; ;;
			--date) DATE_FORMAT="$argument" ;;
			*)  print_fatal_exit_1 "Unknwon option: \"$arg_name\" " ;;
		esac
		arg_name="";
	else
		arg_name="$argument";
	fi
done



#   ____
#  | __ )  __ _ _ __  _ __   ___ _ __
#  |  _ \ / _` | '_ \| '_ \ / _ \ '__|
#  | |_) | (_| | | | | | | |  __/ |
#  |____/ \__,_|_| |_|_| |_|\___|_|
if [[ -t 1 ]]; then # is terminal?
	COLOR_MODE=`tput colors`;
	if [[ -n "$COLOR_MODE" ]] && [[ "$COLOR_MODE" -ge 8 ]]; then
		C1="\e[37;1m"; C2="\e[32;1m";
	fi
fi
echo -e "${C1} ____             _                 ${C2}  __  __                         ____  ____";
echo -e "${C1}| __ )  __ _  ___| | ___   _ _ __   ${C2} |  \\/  | ___  _ __   __ _  ___ |  _ \\| __ )";
echo -e "${C1}|  _ \\ / _\` |/ __| |/ / | | | '_ \\  ${C2} | |\\/| |/ _ \\| '_ \\ / _\` |/ _ \| | | |  _ \\";
echo -e "${C1}| |_) | (_| | (__|   <| |_| | |_) | ${C2} | |  | | (_) | | | | (_| | (_) | |_| | |_) |";
echo -e "${C1}|____/ \\__,_|\___|_|\\_\\\\\\__,_| .__/ ${C2}  |_|  |_|\\___/|_| |_|\\__, |\\___/|____/|____/";
echo -e "${C1}                            |_|          ${C2}                |___/";
echo -e "${C1}=====================================${C2}============================================";
echo -e "${C1}=================================================================================";
echo -e "$RESET";
unset C1;
unset C2;



#   ____
#  |  _ \ _ __ ___ _ __   __ _ _ __ ___
#  | |_) | '__/ _ \ '_ \ / _` | '__/ _ \
#  |  __/| | |  __/ |_) | (_| | | |  __/
#  |_|   |_|  \___| .__/ \__,_|_|  \___|
#                 |_|
print_doing "Preparing backup environemnts ...";
date "$DATE_FORMAT" >/dev/null || print_fatal_exit_1 "Could not get current date string by format: \"$DATE_FORMAT\" !";
NOW=`date "$DATE_FORMAT"`;
TMP_OUTPUT="$TMP_DIR/mongodb-files";
TMP_TAR_NAME="$BACKUP_PREFIX-$NOW.tar.gz";
TMP_TAR="$TMP_DIR/$TMP_TAR_NAME";

print_info "temp output:  $TMP_OUTPUT";
print_info "temp archive: $TMP_TAR";

if [[ -e "$TMP_DIR" ]]; then
	rm -rf "$TMP_DIR" || print_fatal_exit_1 "Could not delete temporary directory: \"${TMP_DIR}\"";
fi
if [[ ! -d "$TMP_OUTPUT" ]]; then
	mkdir -p "$TMP_OUTPUT" || print_fatal_exit_1 "Create directory \"$TMP_OUTPUT\" failed!";
fi



#   ____             _
#  | __ )  __ _  ___| | ___   _ _ __
#  |  _ \ / _` |/ __| |/ / | | | '_ \
#  | |_) | (_| | (__|   <| |_| | |_) |
#  |____/ \__,_|\___|_|\_\\__,_| .__/
#                              |_|
print_doing "Executing $MONGODUMP ...";
$MONGODUMP $DUMP_OPTS -o "$TMP_OUTPUT" ||
	print_fatal_exit_1 "Execute \"$MONGODUMP $DUMP_OPTS -o $TMP_OUTPUT\" failed!";
print_done "Executed $MONGODUMP success!";

print_doing "Creating archive file: \"$TMP_TAR_NAME\" ...";
pushd $TMP_DIR;
tar czf "$TMP_TAR" "mongodb-files"  || print_fatal_exit_1 "Create archive file failed!";
popd;
print_done "Created archive file: $TMP_TAR";



#   _   _       _                 _
#  | | | |_ __ | | ___   __ _  __| |
#  | | | | '_ \| |/ _ \ / _` |/ _` |
#  | |_| | |_) | | (_) | (_| | (_| |
#   \___/| .__/|_|\___/ \__,_|\__,_|
#        |_|
print_doing "Uploading to Google drive ...";

loadConfig;
getGoogleAccessToken;

$GOOGLE_DRIVER --access-token "$OAUTH2_ACCESS_TOKEN" upload \
	--parent "${GOOGLE_DRIVE_DIR}" --name "${TMP_TAR_NAME}" ${TMP_TAR} ||
	print_fatal_exit_1 "upload archive "$TMP_TAR_NAME" to google drive failed!";
print_done "Upload success!"


#    ____ _
#   / ___| | ___  __ _ _ __
#  | |   | |/ _ \/ _` | '_ \
#  | |___| |  __/ (_| | | | |
#   \____|_|\___|\__,_|_| |_|
print_doing "Cleaning temporary files ...";
rm -rf "$TMP_DIR" || print_fatal_exit_1 "clean temporary directory \"$TMP_DIR\" failed!";

print_all_done "backup done!";
