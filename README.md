# zfstat
ZFS monitoring script with logging and email notifications.

# Intro
A monitoring tool for ZFS pool health with logging and email alerts - checks `zpool status` and pool used capacity.

This script relies on the `msmtp` package to function properly. In addition, the default configuration for this script requires its connection to a Gmail account in order to send emails.

# Setup
To get started (and after the aformentioned prerequisites have been installed/updated), the `msmtprc` file should be edited to reflect the credentials to the Gmail account to be used for sending email reports. After editing the file, save and close it and move it to `/etc/msmtprc`.

Next, the `check.sh` file should be opened for editing. The default configurable options are:

* declare -a pools=("tank") = Either a single pool or a list of pools to check on each run. Lists should be seperated by a space, eg. ("tank" "rpool" "otherpool")
* maxcap = The capacity usage level at which to trigger alerts, expressed as a percentage. Default 80%.
* notify = The time to wait between sending alerts for errors. Default 60 minutes - if a pool experiences an error, an alert email will be sent aproximately once every hour until the issue is resolved.
* emailsendnm = The "from" attribute you wish to append to the email. Default is "ZFStat Service".
* emailtoaddr = The email address the script should send email alerts to.
* emailsubject = The "subject" attribute you wish to be appeneded to the alert email.

# Running the Script

To run the script manually (first run, etc.) ensure that `check.sh` is executable.

`chmod +x check.sh`

Then it can be manually executed via `./check.sh`. 

Naturally, the script can be automatically run by cron at set intervals, the `crontab` file contains a example wherein the script is run by cron every 5 minutes. 
