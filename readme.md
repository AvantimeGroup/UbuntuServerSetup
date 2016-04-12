Ubuntu Server Setup Script for PHP sites
===
# make script runable
chmod a=r+w+x your_script_file_name

Set up server
===
#add user
useradd <username>
git clone <url>
cd UbuntuServerSetup

# Install apache, php, mysql, fail2ban, clamav, inotify. Configure fail2ban for wordpress and secure the mysql installation
run ./install.sh

# create a folder
mkdir webroot

#move content of website to webroot folder.

#Set up website
./set_up_website.sh create

# The script will set up a virualhost, add right permissions to the upload folder, add hostname to /etc/hosts


#set up database
./mysql_config.sh dbname dbuser password source (path to sql-script)

# The script will create a database with an local user and import all data from source

# Update connectionstrings in your web application to the database.

# To monitor process, for example restart mysql if it crashes.
./monit.sh

