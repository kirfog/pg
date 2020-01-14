#!/bin/bash
while [ ! -f "/root/$base$day.bak" ]
do
	read -p "Database " -r base
	read -p "Day as 20201231 " -r day
	if [ ! -f "/root/$base$day.bak" ] ; then echo "Check check check"; fi
done

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
     done < <(psql -U postgres -c "\l" | head -n-7 | tail -n +4)

    if [ "$exist" == "y" ]
    then
       read -p "database $newbase already exists, rewrite?" -r over
    fi
done

psql -U postgres -c "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = '$newbase' AND pid <> pg_backend_pid();"
dropdb -U postgres $newbase
createdb -U postgres $newbase
pg_restore -j 4 -d $newbase -U postgres /root/$base$day.bak