#!/bin/bash
apath="/mnt/files/backup/"
if [ $# -eq 0 ]
then
    echo "No archive database file supplied"
    while [ ! -f "$apath$day$base.bak" ]
    do
        read -p "Archive database name " -r base
        read -p "Archive database name date as 20201231 " -r day
        if [ ! -f "$apath$day$base.bak" ] ; then echo "Check backup file"; fi
    done
fi
while [ "$exist" != "n" ] && [ "$over" != "y" ]
do
    read -p "New database " -r newbase
    while read -r str
    do
        IFS=' '
        read -ra ADDR <<< "$str"
        if [[ " ${ADDR[0]} " == " $newbase " ]]
        then
            exist=y
            break
        else
                exist=n
        fi
    done < <(psql -U postgres -c "select * from pg_database" | head -n -2 | tail -n +3 | sed '/^ template/d' | sed '/^ postgres/d')
    if [ "$exist" == "y" ]
    then
       read -p "database $newbase already exists, rewrite? y/n" -r over
    fi
done
if [ "$over" == "y" ]
then
    #psql -U postgres -c "ALTER DATABASE $newbase CONNECTION LIMIT 0;"    
    #psql -U postgres -c "ALTER DATABASE $newbase WITH ALLOW_CONNECTIONS false;"
    psql -U postgres -c "UPDATE pg_database SET datallowconn = 'false' WHERE datname = '$newbase';"
    psql -U postgres -c "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = '$newbase' AND pid <> pg_backend_pid();"
    dropdb -U postgres $newbase
fi
createdb -U postgres $newbase
if [ $# -eq 0 ]
then
    pg_restore -j 4 -d $newbase -U postgres $apath$day$base.bak
else
    if [ ! -f "$1" ]
    then
        echo "Check backup file"
    else
        pg_restore -j 4 -d $newbase -U postgres $1
    fi
fi