#!/bin/bash
apath="/mnt/files/backup/"
alog=$apath$(date +%Y%m%d)"log.txt"

echo "***  $(date +%Y%m%d)  ***" >> $alog
df -ha /pg/data/ >> $alog

psql -U postgres -c "select * from pg_database" | head -n -2 | tail -n +3 | sed '/^ template/d' | sed '/^ postgres/d' | while read -r str ; do
        IFS=' '
        read -ra ADDR <<< "$str"
        echo -e "\n${ADDR[0]}" >> $alog
        /usr/bin/time -p -f %E -o $alog -a pg_dump -U postgres -F c -b -f $apath$(date +%Y%m%d)${ADDR[0]}.bak ${ADDR[0]} 2>>$apath$(date +%Y%m%d)err.txt
        du -sh $apath$(date +%Y%m%d)${ADDR[0]}.bak >> $alog
done
echo "*** *** ***" >> $alog

if  [ ! -s $apath$(date +%Y%m%d)err.txt ]
then
	echo -e "\n*** DELETED FILES ***" >> $alog
	find $apath -type f -mtime +5 -delete -print >> $alog
else
	echo -e "\n***BACKUP ERRORS ***" >> $alog
	cat $apath$(date +%Y%m%d)err.txt >> $alog
fi
echo "*** *** ***" >> $alog

echo -e "\n*** BACKUP FOLDER ***" >> $alog
du -sh /mnt/files/backup/ >> $alog
echo "*** *** ***" >> $alog

echo -e "\n*** BACKUP DISK ***" >> $alog
df -ha /mnt/files/backup/ >> $alog
echo "*** *** ***" >> $alog

echo -e "\n*** VACUUM ***" >> $alog
/usr/bin/time -p -f %E -o $alog -a vacuumdb -U postgres -a -z -F -j 4 >> $alog
echo "*** *** ***" >> $alog

cat $alog | mail -s "PostgreSQL backup $(date +%Y%m%d)" -r 'PostgreSQL Backup <noreplay@mcs-spb.com>' kadmin@mcs-spb.com
