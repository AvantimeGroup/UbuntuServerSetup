#!/bin/bash
## A modded version of https://github.com/RoverWire/virtualhost
### Set Language
TEXTDOMAIN=virtualhost

### Set default parameters
action=$1
domain=$2
alias=$3
regularUser=$4
email=$5
uploadFolder=$6
sshUser=$7
gitDeploy=$8
gitCloneAddress=$9
gitBranch=""
owner=$(who am i | awk '{print $1}')

sitesEnable='/etc/apache2/sites-enabled/'
sitesAvailable='/etc/apache2/sites-available/'
userDir='/var/www/'
gitFolder='/.git/'


### don't modify from here unless you know what you are doing ####

if [ "$(whoami)" != 'root' ]; then
	echo $"You have no permission to run $0 as non-root user. Use sudo"
		exit 1;
fi

if [ "$action" != 'create' ] && [ "$action" != 'delete' ]
	then
		echo $"You need to prompt for action (create or delete) -- Lower-case only"
		exit 1;
fi

while [ "$domain" == "" ]
do
	echo -e $"Please provide domain. e.g.dev,staging"
	read domain
done

while [ "$alias" == "" ]
do
	echo -e $"Please provide the server alias"
	read alias
done

while [ "$email" == "" ]
do
	echo -e $"Please provide the email to the server admin"
	read email
done

while [ "$uploadFolder" == "" ]
do
	echo -e $"Please provide the upload folder"
	read uploadFolder
done

while [ "$sshUser" == "" ]
do
	echo -e $"Who is the ssh user to set as owner (and member of www-data group)?"
	read sshUser
done

while [[ "$gitDeploy" != "y"&& "$gitDeploy" != "n" ]]
do
	echo -e $"Are you going to deploy using git(y/n)?"
	read gitDeploy
done

sitesAvailabledomain=$sitesAvailable$domain.conf
rootdir=${domain//./-}


if [ "$action" == 'create' ]
	then
		### check if domain already exists
		if [ -e $sitesAvailabledomain ]; then
			echo -e $"This domain already exists.\nPlease Try Another one"
			exit;
		fi

		### check if directory exists or not
		if ! [ -d $userDir$rootdir ]; then

			if [ "$gitDeploy" = 'y' ] 
			then
								 while [ "$cloneAddress" == "" ]
									do
										echo -e $"Please provide clone address?"
									read cloneAddress
								done

								while [ "$gitBranch" == "" ]
									do
										echo -e $"Which branch to use?"
									read gitBranch
								done

					  			git clone $cloneAddress $userDir$rootdir
					  			git --git-dir=$userDir$rootdir$gitFolder --work-tree=$userDir$rootdir checkout $gitBranch
					  			### give permission to root dir
					  			chmod 755 $userDir$rootdir
				else

						### create the directory
						mkdir $userDir$rootdir
						### give permission to root dir
						chmod 755 $userDir$rootdir

						### write test file in the new domain dir
						if ! echo "<?php echo phpinfo(); ?>" > $userDir$rootdir/phpinfo.php
						then
							echo $"ERROR: Not able to write in file $userDir/$rootdir/phpinfo.php. Please check permissions"
							exit;
						else
							rm $userDir$rootdir/phpinfo.php
							cp -r webroot/* $userDir$rootdir
						fi
				fi



		fi

		### create virtual host rules file
		if ! echo "
		<VirtualHost *:80>
			ServerAdmin $email
			ServerName $domain
			ServerAlias $alias
			DocumentRoot $userDir$rootdir
			RedirectMatch 404 /\.git
			<Directory />
				AllowOverride All
			</Directory>
			<Directory $userDir$rootdir>
				Options FollowSymLinks MultiViews
				AllowOverride all
				Require all granted
			</Directory>

			<Files xmlrpc.php>
                                order deny,allow
                                deny from all
                        </Files>

			ErrorLog /var/log/apache2/$domain-error.log
			LogLevel error
			CustomLog /var/log/apache2/$domain-access.log combined
		</VirtualHost>" > $sitesAvailabledomain
		then
			echo -e $"There is an ERROR creating $domain file"
			exit;
		else
			echo -e $"\nNew Virtual Host Created\n"
		fi

		### Add domain in /etc/hosts
		if ! echo "127.0.0.1	$domain" >> /etc/hosts
		then
			echo $"ERROR: Not able to write in /etc/hosts"
			exit;
		else
			echo -e $"Host added to /etc/hosts file \n"
		fi

		# if [ "$owner" == "" ]; then
		# 	chown -R $(whoami):www-data $userDir$rootdir
		# else
		# 	chown -R $owner:www-data $userDir$rootdir
		# fi

		a2enmod rewrite

		usermod -a -G www-data $sshUser
		chown -R $sshUser:www-data $userDir$rootdir
		chmod -R g+w $userDir$rootdir$uploadFolder
		chmod -R g+s $userDir$rootdir$uploadFolder
		### enable website
		a2ensite $domain

		### restart Apache
		/etc/init.d/apache2 reload

		### show the finished message
		echo -e $"Complete! \nYou now have a new Virtual Host \nYour new host is: http://$domain \nAnd its located at $userDir$rootdir"
		exit;
	else
		### check whether domain already exists
		if ! [ -e $sitesAvailabledomain ]; then
			echo -e $"This domain does not exist.\nPlease try another one"
			exit;
		else
			### Delete domain in /etc/hosts
			newhost=${domain//./\\.}
			sed -i "/$newhost/d" /etc/hosts

			### disable website
			a2dissite $domain

			### restart Apache
			/etc/init.d/apache2 reload

			### Delete virtual host rules files
			rm $sitesAvailabledomain
		fi

		### check if directory exists or not
		if [ -d $userDir$rootdir ]; then
			echo -e $"Delete host root directory ? (y/n)"
			read deldir

			if [ "$deldir" == 'y' -o "$deldir" == 'Y' ]; then
				### Delete the directory
				rm -rf $userDir$rootdir
				echo -e $"Directory deleted"
			else
				echo -e $"Host directory conserved"
			fi
		else
			echo -e $"Host directory not found. Ignored"
		fi

		### show the finished message
		echo -e $"Complete!\nYou just removed Virtual Host $domain"
		exit 0;
fi
