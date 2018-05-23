#!/usr/bin/env bash

# checkout to directory same with this script
command pushd `cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd` > /dev/null;

# install color variables
source ./style_print.sh
source ./user_config.sh

OAUTH2_ACCESS_TOKEN="";

#
# IMPORTANT!!!  please call `loadConfig` before
#
function getGoogleAccessToken() {

	if [[ -n "$OAUTH2_ACCESS_TOKEN" ]]; then return; fi

	local URL TMP_FILE BODY RESPONSE ERROR;
	URL="https://accounts.google.com/o/oauth2/token";
	TMP_FILE="/tmp/google-oauth2-refresh.json";

	BODY="client_id=${OAUTH2_CLIENT_ID}&client_secret=${OAUTH2_CLIENT_SECRET}&refresh_token=${OAUTH2_REFRESH_TOKEN}";
	BODY="${BODY}&grant_type=refresh_token";

	print_doing "Getting access token by Google OAuth2 ...";
	[[ -f "$TMP_FILE" ]] && rm $TMP_FILE;
	curl -X POST -o "$TMP_FILE" --data "$BODY" \
		"$URL" || print_fatal_exit_1 "POST $URL failed!";

	print_done "Got response from $URL";
	[[ ! -f "$TMP_FILE" ]] && print_fatal_exit_1 "POST $URL with empty response!";
	RESPONSE=`cat "$TMP_FILE"`;

	ERROR=`echo "$RESPONSE" | jq -r ".error // \"\""`;
	if [[ -n "$ERROR" ]]; then
		echo "$RESPONSE" | jq ".";
		print_fatal_exit_1 "response has error, please try again!";
	fi

	OAUTH2_ACCESS_TOKEN=`echo "$RESPONSE" | jq -r ".access_token // \"\""`;
	if [[ -z "$OAUTH2_ACCESS_TOKEN" ]]; then
		echo "$RESPONSE" | jq ".";
		print_fatal_exit_1 "access_token is missing in the response!";
	fi

	print_done "Got access token: $OAUTH2_ACCESS_TOKEN";
}

command popd > /dev/null;
