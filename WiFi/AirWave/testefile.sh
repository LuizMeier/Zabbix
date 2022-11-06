#!/bin/bash

if test -f cookie; then

    if test `find cookie -cmin +1`; then
        echo "existe e mais velho que 230"
    else
    	echo "existe e mais novo que 230"
    fi

else
       echo "não existe"

fi

