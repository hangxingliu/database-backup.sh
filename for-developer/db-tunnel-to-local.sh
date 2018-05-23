#!/usr/bin/env bash

function throw() { echo -e "$1"; exit 1; }
function kill_by_ports() {
	echo -e "fuser -k 27017/tcp";
	fuser -k 27017/tcp;

	echo -e "fuser -k 5432/tcp";
	fuser -k 5432/tcp
}

[[ -z "$1" ]] && throw "Usage: ./db-tunnel-to-local.sh \$SERVER";

# clean old listener
kill_by_ports

# MongoDB
ssh -NL 27017:127.0.0.1:27017 "$1" &

# PostgreSQL
ssh -NL 5432:127.0.0.1:5432 "$1" &

# display jobs
jobs;

read -p "Enter to stop > ";

kill %2;
kill %1;
# why not following command, because it will kill bash itself
# kill_by_ports;


jobs;
while [[ `jobs | wc -l` -gt 0 ]]; do
	echo -e "waiting background jobs exit ...";

	wait;
	sleep 1;
	jobs;
done

echo -e "exit";
