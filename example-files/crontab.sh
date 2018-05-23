#!/usr/bin/env bash

LOG_DIR="/var/log/backup-database";
MONGODB_OPTS="--host 127.0.0.1 --port 27017";
POSTGRESQL_OPTS="--host 127.0.0.1 --port 5432 --username test --password test --database test";

# ===============================================
function throw() { echo -e "fatal: $1\nexit with code 1;"; exit 1; }

NOW="$(date "+%Y-%m-%d-%H-%M-%S")";
LOG_FILE="$LOG_DIR/$NOW.log";
APPEND_LOG="tee --append $LOG_FILE";

# checkout to directory same with this script
pushd `cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`;

echo "Start backup databases ...";
echo "Log file: $LOG_FILE";
echo "===================================";

if [[ ! -d "$LOG_DIR" ]]; then
	mkdir -p "$LOG_DIR" || throw "could not create ${LOG_DIR}";
fi

echo -e "\nTASK: backing up MongoDB ..." | $APPEND_LOG;
bash ../backup-mongodb.sh $MONGODB_OPTS 2>&1 | $APPEND_LOG  \
	|| echo -e "\nERROR: backup MongoDB failed!";
echo "========================================================="  | $APPEND_LOG;

echo -e "\nTASK: backing up PostgreSQL ..." | $APPEND_LOG;
bash ../backup-postgresql.sh $POSTGRESQL_OPTS 2>&1 | $APPEND_LOG  \
	|| echo -e "\nERROR: backup PostgreSQL failed!";
echo "========================================================="  | $APPEND_LOG;

popd;
