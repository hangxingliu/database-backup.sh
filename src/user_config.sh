#!/usr/bin/env bash

#
#  load $HOME/.backup-database-config.json
#
#  - oauth2_client_id
#  - oauth2_client_secret
#  - oauth2_refresh_token

# checkout to directory same with this script
command pushd `cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd` > /dev/null;

# install color variables
source ./style_print.sh

CFG_FILE="$HOME/.backup-database-config.json";

# load from config
OAUTH2_CLIENT_ID="";
OAUTH2_CLIENT_SECRET="";
OAUTH2_REFRESH_TOKEN="";

GOOGLE_DRIVE_DIR="";

function loadConfig() {
	# if [[ ! -f "$CFG_FILE" ]]; then return; fi

	print_doing "loading user config from \"$CFG_FILE\" ";

	local JSON;
	JSON=`cat "$CFG_FILE"`;
	if [[ -z "$JSON" ]]; then return; fi

	# test JSON
	echo "$JSON" | jq -r '.' > /dev/null;
	if [[ "$?" != "0" ]]; then print_fatal_exit_1 "user config is invalid!"; fi

	OAUTH2_CLIENT_ID=`echo "$JSON" | jq -r '.oauth2_client_id // ""'`;
	OAUTH2_CLIENT_SECRET=`echo "$JSON" | jq -r '.oauth2_client_secret // ""'`;
	OAUTH2_REFRESH_TOKEN=`echo "$JSON" | jq -r '.oauth2_refresh_token // ""'`;
	GOOGLE_DRIVE_DIR=`echo "$JSON" | jq -r '.google_driver_dir // ""'`;

	print_info "OAuth2 Client ID: ${OAUTH2_CLIENT_ID}";
	print_info "OAuth2 Client Secret: ${OAUTH2_CLIENT_SECRET}";
	print_info "OAuth2 Refresh Token: ${OAUTH2_REFRESH_TOKEN}";
	print_info "Google Drive Dir: ${GOOGLE_DRIVE_DIR}";
	print_done "loaded user config";
}

function _newConfig() {
	echo "{}" |
		jq ".oauth2_client_id = \"$OAUTH2_CLIENT_ID\"" |
		jq ".oauth2_client_secret = \"$OAUTH2_CLIENT_SECRET\"" |
		jq ".oauth2_refresh_token = \"$OAUTH2_REFRESH_TOKEN\"" |
		jq ".google_driver_dir = \"$GOOGLE_DRIVE_DIR\"";
}

function saveConfig() {
	print_doing "saving user config into \"$CFG_FILE\" ";

	local NEW_JSON;
	NEW_JSON=`_newConfig`;
	echo -e "$NEW_JSON" > $CFG_FILE;

	print_done "saved user config";
}

command popd > /dev/null;
