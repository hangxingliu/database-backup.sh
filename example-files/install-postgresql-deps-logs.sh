#
# This is only a example logs. DONT'T just copy paste it into terminal
#
exit 0; # this exit 0 for safe for somebody just run it as a Bash script file

wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

# 18.04 bionic
echo "deb http://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main" |
	sudo tee /etc/apt/sources.list.d/pgdg.list

sudo apt-get update

# for `pg_dump`
apt-get install -y postgresql-client-10

env PGPASSWORD="test" \
	pg_dump --encoding UTF8 --format directory --host=192.168.1.20 --port=5432 --username=test --dbname=test --file out

