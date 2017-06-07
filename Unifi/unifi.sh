#!/bin/sh

## Prereq: include the API library
. /usr/lib/unifi/bin/unifi_sh_api

unifi_login

if [ $# -eq 0 ] ; then
	sites=`unifi_list_sites`
	descs=`unifi_list_sites desc`
	count=`echo "${sites}" | wc -l`
	echo '{'
	echo '"data":['
	for i in `/usr/bin/seq 1 $count`; do
		site=`echo "${sites}" | sed "${i}!d"`
		desc=`echo "${descs}" | sed "${i}!d"`
		if [ "$site" != "super" ] ; then
			line='{"{#SITENAME}":"'$site'", "{#SITEDESC}":"'${desc}'"}'
			printf "$line"
			if [ $i -ne $count ]; then
				echo ','
			fi
		fi
	done
	echo 
	echo ']'
	echo '}'
fi

# Total of site's AP's
if [ "$2" = "total" ] ; then
	site=$1
	unifi_list_device $site | wc -l
fi

# Total of online site's AP's
if [ "$2" = "online" ] ; then
        site=$1
        unifi_list_device_state $site | grep ': 1$' | wc -l
fi

# Total of offline site's AP's
if [ "$2" = "offline" ] ; then
        site=$1
        unifi_list_device_state $site | grep -v ': 1$' | wc -l
fi

unifi_logout
