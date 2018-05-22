#
# This is only a example logs. DONT'T just copy paste it into terminal
#
exit 0; # this exit 0 for safe for somebody just run it as a Bash script file

sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2930ADAE8CAF5059EE73BB4B58712A2291FA4AD5

echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.6 multiverse" |
	sudo tee /etc/apt/sources.list.d/mongodb-org-3.6.list

sudo apt-get update

sudo apt-get install -y mongodb-org-tools

# install `mongo` command line tools for test
sudo apt-get install -y mongodb-org-shell

mongo 127.0.0.1:27017
# > show dbs;
# > quit();
