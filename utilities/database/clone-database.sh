#!/bin/bash
#########################
# Brent Peterson support@wagento.com
# ** WARNING ** DO NOT USE THIS ON PRODUCTION
# DO NOT USE THIS UNLESS YOU HAVE TESTED IT ON YOUR LOCAL SYSTEM
# DO NOT USE THIS IF YOU HAVE NO IDEA WHAT YOU ARE DOING
# Ask for the app location
#########################
function createDatabase ()
{
    MYSQL=`which mysql`

    Q1="CREATE DATABASE IF NOT EXISTS $3;"
    Q2="GRANT USAGE on $3.* to '$1'@'%' IDENTIFIED BY '$2';"
    Q3="GRANT ALL PRIVILEGES ON $3.* TO '$1'@'%' IDENTIFIED BY '$2';"
    Q4="FLUSH PRIVILEGES;"
    SQL="${Q1}${Q2}${Q3}${Q4}"
    echo $SQL
    echo $MYSQL -u $1 -p${2} -h $4 -e "$SQL"
    #$MYSQL -e "$SQL"
    echo "Database Created" 
}


##This is still a work in progress
path="$1/app/etc/local.xml"
if [ -e "$path" ]
then
echo "Name of file (clone-db.sh is default, followed by [ENTER]:"
read file
#########################
# The path from ~/your_directory
#########################
echo "Do you want to change the name of your main backup directory? (mysql_backup is default), followed by [ENTER]:"
read backdir
backdir=${backdir:-mysql_backup}
file=${file:-clone-db.sh}
#########################
# Collect data on Local.xml
#########################
dbs=($(cat $path | grep -oP '(?<=<dbname><!\[CDATA\[)[^\]]+'))
host=($(cat $path | grep -oP '(?<=<host><!\[CDATA\[)[^\]]+'))
password=($(cat $path | grep -oP '(?<=<password><!\[CDATA\[)[^\]]+'))
user=($(cat $path | grep -oP '(?<=<username><!\[CDATA\[)[^\]]+'))
prefix=($(cat $path | grep -oP '(?<=<table_prefix><!\[CDATA\[)[^\]]+'))
echo $path
#########################
# Check if path exists
#########################
if [ ! -d "$HOME/$backdir/update" ]; then
mkdir -p $HOME/$backdir/update
fi
checkfile="$HOME/$backdir/$file"
if [ -e "$checkfile" ]; then
mv $HOME/$backdir/$file $HOME/$backdir/$file-bak-$(date +%d%m%Y_%H%M).bak
else
echo $ile ' was created'
fi
dbx=$(date +%s | sha256sum | base64 | head -c 10)
ndb=${dbs}${dbx}
echo "Starting Database creation and DB user"
createDatabase $user $password $ndb $host
touch $HOME/$backdir/$file
touch $HOME/$backdir/update/clean-log.sql
echo "MAGEFILE=\"$dbs-\$(date +%d%m%Y_%H%M).sql.gz\"" >> $HOME/$backdir/$file
echo "mysql -p'$password' -u $user -h $host $dbs < update/clean-log.sql" >> $HOME/$backdir/$file
echo "mysqldump -p'$password' -u$user -h$host --single-transaction --quick $dbs | gzip > \$MAGEFILE" >> $HOME/$backdir/$file
echo "truncate "$prefix"dataflow_batch_export;truncate "$prefix"dataflow_batch_import;truncate "$prefix"log_customer;truncate "$prefix"log_quote;truncate "$prefix"log_summary;truncate "$prefix"log_summary_type;truncate "$prefix"log_url;truncate "$prefix"log_url_info;truncate "$prefix"log_visitor;truncate "$prefix"log_visitor_info;truncate "$prefix"log_visitor_online;truncate "$prefix"report_viewed_product_index;truncate "$prefix"report_compared_product_index;truncate "$prefix"report_event;truncate "$prefix"sendfriend_log;" > $HOME/$backdir/update/clean-log.sql
else
 echo "You really screwed up on the path, dude try this again. Did you screw up on the path? -->  $path"
fi
