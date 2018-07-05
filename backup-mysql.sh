#!/usr/bin/env bash

# MySQL/MariaDB backup script
#
# Example:
#
#    ./backup-mysql                                          # backup prefix is "mysql-"
#    ./backup-mysql --name "mike-mysql"                      # backup prefix is "mike-mysql-"
#    ./backup-mysql --host "192.168.1.8" --port 3306
#    ./backup-mysql --host "192.168.1.8" --port 3306 --username "root" --password "123456" \
#                   --database "testdb" --database "testdb2"

#
# More Options:
#
#    --date        date format, "+%Y-%m-%d-%H-%M" by default
#    --database    backup special database(s). all databases by default
#

MYSQL_DUMP="mysqldump";
DUMP_OPTS="";
DUMP_DB="";
DUMP_EXTRA="[client]\n";
GOOGLE_DRIVER="./libs/gdrive";
EXTRA_FILE="/tmp/backup-mysql-extra-file";
TMP_DIR="/tmp/backup-mysql-to-gdrive";
BACKUP_PREFIX="mysql";
DATE_FORMAT="+%Y-%m-%d-%H-%M";

# checkout to directory same with this script
__DIRNAME=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`;
pushd "$__DIRNAME" > /dev/null;

source ./src/style_print.sh;
source ./src/user_config.sh;
source ./src/get_google_access_token.sh;

HAVE_YOU_RESOLVE="(have you resolve dependencies by script \"./libs/resolve.sh\" ?)";
[[ -z `which $MYSQL_DUMP` ]] && print_fatal_exit_1 "\"$MYSQL_DUMP\" is not installed!";
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
			--host) DUMP_EXTRA="${DUMP_EXTRA}host = \"$argument\"\n" ;;
			--port) DUMP_EXTRA="${DUMP_EXTRA}port = \"$argument\"\n" ;;
			--username) DUMP_EXTRA="${DUMP_EXTRA}user = \"$argument\"\n" ;;
			--password) DUMP_EXTRA="${DUMP_EXTRA}password = \"$argument\"\n" ;;

			--database) DUMP_DB="${DUMP_DB}${argument} " ;;

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
		C1="\e[37;1m"; C2="\e[36;1m";
	fi
fi


echo -e "${C1} ____             _                 ${C2}   __  __       ____   ___  _";
echo -e "${C1}| __ )  __ _  ___| | ___   _ _ __   ${C2}  |  \\/  |_   _/ ___| / _ \\| |";
echo -e "${C1}|  _ \\ / _\` |/ __| |/ / | | | '_ \\  ${C2}  | |\\/| | | | \\___ \\| | | | |";
echo -e "${C1}| |_) | (_| | (__|   <| |_| | |_) | ${C2}  | |  | | |_| |___) | |_| | |___";
echo -e "${C1}|____/ \\__,_|\___|_|\\_\\\\\\__,_| .__/ ${C2}   |_|  |_|\\__, |____/ \\__\\_\\_____|";
echo -e "${C1}                            |_|          ${C2}     |___/";
echo -e "${C1}=====================================${C2}==================================";
echo -e "${C1}=======================================================================";
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
TMP_OUTPUT="$TMP_DIR/mysql-dump.sql";
TMP_TAR_NAME="$BACKUP_PREFIX-$NOW.tar.gz";
TMP_TAR="$TMP_DIR/$TMP_TAR_NAME";

print_info "temp output:  $TMP_OUTPUT";
print_info "temp archive: $TMP_TAR";

if [[ -e "$TMP_DIR" ]]; then
	rm -rf "$TMP_DIR" || print_fatal_exit_1 "Could not delete temporary directory: \"${TMP_DIR}\"";
fi
if [[ ! -d "$TMP_DIR" ]]; then
	mkdir -p "$TMP_DIR" || print_fatal_exit_1 "Create directory \"$TMP_DIR\" failed!";
fi


#   ____             _
#  | __ )  __ _  ___| | ___   _ _ __
#  |  _ \ / _` |/ __| |/ / | | | '_ \
#  | |_) | (_| | (__|   <| |_| | |_) |
#  |____/ \__,_|\___|_|\_\\__,_| .__/
#                              |_|
DISPLAY_INFO="(ALL)";
if [[ -z "$DUMP_DB" ]]; then             DUMP_OPTS="${DUMP_OPTS} --all-databases ";
else  DISPLAY_INFO="(DB: ${DUMP_DB})";   DUMP_OPTS="${DUMP_OPTS} --databases ${DUMP_DB} "; fi

print_doing "Executing $MYSQL_DUMP $DISPLAY_INFO...";

echo -e "$DUMP_EXTRA" > "$EXTRA_FILE";
$MYSQL_DUMP --defaults-extra-file="$EXTRA_FILE" $DUMP_OPTS > "$TMP_OUTPUT"; DUMP_OK="$?";
rm "$EXTRA_FILE";

if [[ "$DUMP_OK" != "0" ]]; then
	print_fatal_exit_1 "Execute \`$MYSQL_DUMP --defaults-extra-file=\"$EXTRA_FILE\" $DUMP_OPTS\` failed!";
fi

print_done "Executed $MYSQL_DUMP success!";

print_doing "Creating archive file: \"$TMP_TAR_NAME\" ...";
pushd $TMP_DIR;
tar czf "$TMP_TAR" "mysql-dump.sql"  || print_fatal_exit_1 "Create archive file failed!";
popd;
print_done "Created archive file: $TMP_TAR";

exit;

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
