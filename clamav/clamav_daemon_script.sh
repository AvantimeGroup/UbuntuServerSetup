#!/bin/bash
# Script "ClamAV Real Time", par HacKurx
# https://hackurx.wordpress.com
# Licence: GPL v3
# Dépendance: clamav-daemon inotify-tools
# Recommandé pour PC de bureau: libnotify-bin

DIRECTORY=/var/www/
QUARANTAINE=/var/quarantaine
LOG=$HOME/.clamav-tr.log

inotifywait -q -m -r -e create,modify,access "$DIRECTORY" --format '%w%f|%e' | sed --unbuffered 's/|.*//g' |

while read FILE; do 
        clamscan --quiet --no-summary -i -m "$FILE" --move=$QUARANTAINE
        if [ "$?" == "1" ]; then
		echo "`date` - Malware was detected in the file '$FILE'. The file has been moved to $QUARANTAINE." >> $LOG 
		echo -e "33[31mMalware trouvé!!!33[00m" "The file '$FILE' was moved to quarantine."
		if [ -f /usr/bin/notify-send ]; then
			notify-send -u critical "ClamAV Temps Réel" "Malware trouvé!!! The file '$FILE' was moved to quarantine."
		fi
        fi
done