#!/usr/bin/env bash

# init script
#
# 1. resolve all dependencies 解决所有依赖
# 2. init google drive oauth2 初始化GoogleDrive的OAuth2认证

# Proxy environment variables
#   export http_proxy=127.0.0.1:8118;
#   export https_proxy=127.0.0.1:8118;


# checkout to directory same with this script
__DIRNAME=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`;
pushd "$__DIRNAME" > /dev/null;

source ./src/style_print.sh;
source ./src/user_config.sh;

echo ' ================================================'
echo '   ___       _ _     ____            _       _   '
echo '  |_ _|_ __ (_) |_  / ___|  ___ _ __(_)_ __ | |_ '
echo '   | || '\''_ \| | __| \___ \ / __| '\''__| | '\''_ \| __|'
echo '   | || | | | | |_   ___) | (__| |  | | |_) | |_ '
echo '  |___|_| |_|_|\__| |____/ \___|_|  |_| .__/ \__|'
echo '                                      |_|        '
echo '    1. resolve all dependencies'
echo '    2. init google drive oauth2'
echo ' ================================================'


#   ____                 _                  _
#  |  _ \ ___  ___  ___ | |_   _____     __| | ___ _ __  ___
#  | |_) / _ \/ __|/ _ \| \ \ / / _ \   / _` |/ _ \ '_ \/ __|
#  |  _ <  __/\__ \ (_) | |\ V /  __/  | (_| |  __/ |_) \__ \
#  |_| \_\___||___/\___/|_| \_/ \___|   \__,_|\___| .__/|___/
#                                                 |_|
source ./libs/resolve.sh;



#    ___    _         _   _     ____      ___        __
#   / _ \  / \  _   _| |_| |__ |___ \    |_ _|_ __  / _| ___
#  | | | |/ _ \| | | | __| '_ \  __) |    | || '_ \| |_ / _ \
#  | |_| / ___ \ |_| | |_| | | |/ __/     | || | | |  _| (_) |
#   \___/_/   \_\__,_|\__|_| |_|_____|   |___|_| |_|_|  \___/
loadConfig;
INPUT_OAUTH2_CLIENT_INFO=true;
if [[ -n "$OAUTH2_CLIENT_ID" ]] && [[ -n "$OAUTH2_CLIENT_SECRET" ]]; then
	INPUT_OAUTH2_CLIENT_INFO=false;

	read -p "Do you want reset OAuth2 client info? (y/N) > " _INPUT;
	if [[ "$_INPUT" == y* ]] || [[ "$_INPUT" == Y* ]]; then INPUT_OAUTH2_CLIENT_INFO=true; fi
fi

while [[ "$INPUT_OAUTH2_CLIENT_INFO" == "true" ]]; do
	read -p "OAuth2 client id > " OAUTH2_CLIENT_ID;
	read -p "OAuth2 client secret > " OAUTH2_CLIENT_SECRET;

	echo "{}" |
		jq ".oauth2_client_id = \"$OAUTH2_CLIENT_ID\"" |
		jq ".oauth2_client_secret = \"$OAUTH2_CLIENT_SECRET\"";

	read -p "Do you confirm? (Y/n) > " _INPUT;

	INPUT_OAUTH2_CLIENT_INFO=false;
	if [[ "$_INPUT" == n* ]] || [[ "$_INPUT" == N* ]]; then
		INPUT_OAUTH2_CLIENT_INFO=true;
		saveConfig;
	fi
done

if [[ -z "$OAUTH2_CLIENT_ID" ]] || [[ -z "$OAUTH2_CLIENT_SECRET" ]]; then
	print_fatal_exit_1 "OAuth2 client id is empty, Or OAuth2 client secret is empty!";
fi



#    ___    _         _   _     ____     ____  _             _
#   / _ \  / \  _   _| |_| |__ |___ \   / ___|| |_ ___ _ __ / |
#  | | | |/ _ \| | | | __| '_ \  __) |  \___ \| __/ _ \ '_ \| |
#  | |_| / ___ \ |_| | |_| | | |/ __/    ___) | ||  __/ |_) | |
#   \___/_/   \_\__,_|\__|_| |_|_____|  |____/ \__\___| .__/|_|
#                                                     |_|
print_doing "Getting device code for Google OAuth2 ...";

OAUTH_URL1="https://accounts.google.com/o/oauth2/device/code";
OAUTH_SCOPE="https://www.googleapis.com/auth/drive.file";
TMP_FILE="/tmp/google-oauth2-device-code.json";

[[ -f "$TMP_FILE" ]] && rm $TMP_FILE;
curl -X POST -o "$TMP_FILE" \
	--data "client_id=$OAUTH2_CLIENT_ID&scope=$OAUTH_SCOPE" "$OAUTH_URL1" \
	|| print_fatal_exit_1 "POST $OAUTH_URL1 failed!";

print_done "Got response from $OAUTH_URL1";
[[ ! -f "$TMP_FILE" ]] && print_fatal_exit_1 "POST $OAUTH_URL1 with empty response!";
RESPONSE=`cat "$TMP_FILE"`;

ERROR=`echo "$RESPONSE" | jq -r ".error // \"\""`;
if [[ -n "$ERROR" ]]; then
	echo "$RESPONSE" | jq ".";
	print_fatal_exit_1 "response has error, please try again!";
fi

DEVICE_CODE=`echo "$RESPONSE" | jq -r ".device_code // \"\""`;
USER_CODE=`echo "$RESPONSE" | jq -r ".user_code // \"\""`;
VERIFY_URL=`echo "$RESPONSE" | jq -r ".verification_url // \"\""`;
if [[ -z "$DEVICE_CODE" ]] || [[ -z "$USER_CODE" ]] || [[ -z "$VERIFY_URL" ]]; then
	echo "$RESPONSE" | jq ".";
	print_fatal_exit_1 "some required fields are missing in the response! (required fields: device_code, user_code, verification_url)";
fi

print_info "=====================================";
print_info "|  Plese input following code:      |";
print_info "|                                   |";
print_info "|             ${BOLD}${USER_CODE}${RESET}${CYAN}             |";
print_info "|                                   |";
print_info "|  into URL:                        |";
print_info "|                                   |";
print_info "|     ${VERIFY_URL} |";
print_info "|                                   |";
print_info "=====================================";

INPUT_DONE="false";
while [[ "$INPUT_DONE" == "false" ]]; do
	read -p "Have you inputed code? (y/N) > " _INPUT;
	if [[ "$_INPUT" == y* ]] || [[ "$_INPUT" == Y* ]]; then INPUT_DONE=true; fi
done



#    ___    _         _   _     ____     ____  _            ____
#   / _ \  / \  _   _| |_| |__ |___ \   / ___|| |_ ___ _ __|___ \
#  | | | |/ _ \| | | | __| '_ \  __) |  \___ \| __/ _ \ '_ \ __) |
#  | |_| / ___ \ |_| | |_| | | |/ __/    ___) | ||  __/ |_) / __/
#   \___/_/   \_\__,_|\__|_| |_|_____|  |____/ \__\___| .__/_____|
#                                                     |_|
print_doing "Getting access token and refresh token by Google OAuth2 ...";

OAUTH_URL2="https://accounts.google.com/o/oauth2/token";
GRANT_TYPE="http://oauth.net/grant_type/device/1.0";
TMP_FILE="/tmp/google-oauth2-token.json";

[[ -f "$TMP_FILE" ]] && rm $TMP_FILE;
curl -X POST -o "$TMP_FILE" \
	--data "client_id=${OAUTH2_CLIENT_ID}&client_secret=${OAUTH2_CLIENT_SECRET}&code=${DEVICE_CODE}&grant_type=${GRANT_TYPE}" \
	"$OAUTH_URL2" \
	|| print_fatal_exit_1 "POST $OAUTH_URL2 failed!";

print_done "Got response from $OAUTH_URL2";
[[ ! -f "$TMP_FILE" ]] && print_fatal_exit_1 "POST $OAUTH_URL2 with empty response!";
RESPONSE=`cat "$TMP_FILE"`;

ERROR=`echo "$RESPONSE" | jq -r ".error // \"\""`;
if [[ -n "$ERROR" ]]; then
	echo "$RESPONSE" | jq ".";
	print_fatal_exit_1 "response has error, please try again!";
fi

OAUTH2_ACCESS_TOKEN=`echo "$RESPONSE" | jq -r ".access_token // \"\""`;
OAUTH2_REFRESH_TOKEN=`echo "$RESPONSE" | jq -r ".refresh_token // \"\""`;
if [[ -z "$OAUTH2_ACCESS_TOKEN" ]] || [[ -z "$OAUTH2_REFRESH_TOKEN" ]]; then
	echo "$RESPONSE" | jq ".";
	print_fatal_exit_1 "some required fields are missing in the response! (required fields: access_token, refresh_token)";
fi

saveConfig;



#   ____                                   ____  _
#  |  _ \ _ __ ___ _ __   __ _ _ __ ___   |  _ \(_)_ __
#  | |_) | '__/ _ \ '_ \ / _` | '__/ _ \  | | | | | '__|
#  |  __/| | |  __/ |_) | (_| | | |  __/  | |_| | | |
#  |_|   |_|  \___| .__/ \__,_|_|  \___|  |____/|_|_|
#                 |_|
print_doing "Prepare backup directory on Google drive ...";

GOOGLE_DRIVE='./libs/gdrive';
# Reference: https://developers.google.com/drive/api/v3/search-parameters
QUERY_OPTS="trashed = false and 'me' in owners and 'root' in parents and mimeType = 'application/vnd.google-apps.folder'";
TMP_FILE="/tmp/google-drive-list.result";

print_doing "Querying is backup directory existed!";
[[ -f "$TMP_FILE" ]] && rm $TMP_FILE;
$GOOGLE_DRIVE --access-token "$OAUTH2_ACCESS_TOKEN" list -q "$QUERY_OPTS" > "$TMP_FILE" ||
	print_fatal_exit_1 "query files on google drive failed!";
print_done "Query files on Google drive success!";

# only one line (header)
LINES=`wc -l "$TMP_FILE" | awk '{print $1}'`;
if [[ $LINES -le 1 ]]; then
	print_doing "Creating backup directory on Google drive ...";

	DIR_NAME="database-backup-files";
	MKDIR_TMP_FILE="/tmp/google-drive-mkdir.result";

	[[ -f "$MKDIR_TMP_FILE" ]] && rm $MKDIR_TMP_FILE;
	$GOOGLE_DRIVE --access-token "$OAUTH2_ACCESS_TOKEN" mkdir "$DIR_NAME" > "$MKDIR_TMP_FILE" ||
		print_fatal_exit_1 "mkdir directory "$DIR_NAME" on google drive failed!";
	print_done "Created files on Google drive success!";
	print_info `cat "$MKDIR_TMP_FILE"`;


	print_doing "Querying backup directory again ...";
	[[ -f "$TMP_FILE" ]] && rm $TMP_FILE;
	$GOOGLE_DRIVE --access-token "$OAUTH2_ACCESS_TOKEN" list -q "$QUERY_OPTS" > "$TMP_FILE" ||
		print_fatal_exit_1 "query files on google drive failed!";
fi

print_done "Backup directory has been created on Google drive!";
print_info "directory info:\n$(cat $TMP_FILE)";

function getGoogleDirId() { cat "$TMP_FILE" | awk 'NR > 1 { print $1; exit; }'; }
GOOGLE_DRIVE_DIR=`getGoogleDirId`;
saveConfig;

print_all_done "Initialized Google drive for backup!";
