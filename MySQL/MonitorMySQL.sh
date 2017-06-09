#!/bin/sh

#Script to discover MySQL databases to monitoring.
#It expects the file /var/lib/zabbix/.my.cnf to be present and configured with an user with read privileges.

#No arguments, runs LLD
if [ $# -eq 0 ] ; then
	databases=`echo "show databases" | HOME=/var/lib/zabbix mysql -N`
	count=`echo "${databases}" | wc -l`
	echo '{'
	echo '"data":['
	for i in `/usr/bin/seq 1 $count`; do
			desc=`echo "${databases}" | sed "${i}!d"`
					line='{"{#DBNAME}":"'${desc}'"}'
					printf "$line"
					if [ $i -ne $count ]; then
							echo ','
					fi
	done
	echo
	echo ']'
	echo '}'
fi

# With 1 argument informed, checks the informed database size.
if [ $# -eq 1 ] ; then
	echo "SELECT SUM(data_length + index_length) FROM information_schema.TABLES WHERE table_schema = '$1' GROUP BY table_schema;" | HOME=/var/lib/zabbix mysql -N
fi

# With 2 arguments, informs the informed table size. $1 to database and $2 to the table.
if [ $# -eq 2 ] ; then
	echo "SELECT SUM(data_length + index_length) FROM information_schema.TABLES WHERE table_schema = '$1' AND table_name = '$2';" | HOME=/var/lib/zabbix mysql -N
fi
