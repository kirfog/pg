#!/bin/bash
psql -U postgres -c "\l" | head -n-7 | tail -n +4 | while read -r str ; do
		IFS=' '
		read -ra ADDR <<< "$str"
    	echo "${ADDR[0]}"
    	pg_dump -U postgres -F c -b -f /root/${ADDR[0]}$(date +%Y%m%d) ${ADDR[0]}
done