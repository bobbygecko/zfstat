#!/bin/bash

## Specify pools to be checked
declare -a pools=("tank")

## Specify pool capacity alert (as a percent)
maxcap="80"

## Specify how often alerts should be sent if there is an error (in minutes)
notify="60"

## Specify Email Options
emailsendnm="ZFStat Service"
emailtoaddr="email@gmail.com"
emailsubject="Alert: ZFStat Service on $HOSTNAME has Detected a Problem"

## Set environment for cron
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/zfstat

## End user-configurable options ##

## Ensure working directory is the same as script for cron
cd "${0%/*}"

## Create log directory if it doesn't exist
mkdir -p logs

## Remove log entries older than 30 days
find logs/ -type f -name 'log*' -mtime +30 -exec rm {} +

## Create logfile
log="logs/log-`date +%m-%d-%Y`"
date=`date '+%H:%M:%S %m-%d-%Y'`

## Initiate log entry
touch $log
echo "Starting ZFStat script - $date..." > $log

## Run checks on each pool specified
for pool in "${pools[@]}"
do
    ## Check pool health
    status=$(zpool list -H -o health $pool)
    if [ $status != "ONLINE" ]; then
    error="true"
    printf "\nThe pool \x22$pool\x22 has experienced an issue and is not functioning properly. Immediate attention is advised." >> $log
        else
        :
    fi

    ## Check pool capacity
    capacity=$( zpool list -H -o capacity $pool | cut -d'%' -f1 )
    if [ $capacity -ge $maxcap ]; then
    error="true"
    printf "\nThe pool \x22$pool\x22 is $capacity%% full and may experience performance issues.\n" >> $log
        else
        :
    fi

    ## Add newline to log, serves to seperate status by pool
    printf "\n" >> $log
done

## Setup notification timer
timefile=".time"
linuxtime=`date '+%s'`
touch $timefile
if [ -s $timefile ]; then
    :
else
    printf "$linuxtime" > $timefile
fi
lastsent=`cat $timefile`
notetime=$(( $notify * 60 + $lastsent ))

## If no errors encountered, record in log
if [ "$error" != "true" ]; then
   printf "\nScan finished without errors." >> $log
else
   printf "\nEnd of scan service." >> $log
fi

## If errors exist, and it has been longer than the specified interval, handle notification
if [[ "$error" = "true" && "$linuxtime" > "$notetime" ]]; then

    ## Setup temp directory
    mkdir -p tmp

    ## Prepare log content with HTML formatting
    perl -ne 'print "$_<br />"' $log > tmp/log.sending

    ## Populate email template with relevant data
    mailsend="tmp/mail.sending"
    cp mail.template $mailsend
    emailheader="The Following Issues Were Detected"
    perl -pi -e 's#%%emailsendnm%%#'"$emailsendnm"'#' $mailsend
    perl -pi -e 's#%%emailsubject%%#'"$emailsubject"'#' $mailsend
    perl -pi -e 's#%%emailheader%%#'"$emailheader"'#' $mailsend
    perl -pi -e 's#%%emailmessage%%#'"`cat tmp/log.sending`"'#' $mailsend

    ## Send the notification email
    cat $mailsend | msmtp -a gmail $emailtoaddr

    ## Clean up temp files
    rm -r tmp

    ## Reset notification timer
    printf $linuxtime > $timefile

else
    :
fi

exit 0
