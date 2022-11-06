#!/bin/bash

# Luiz Fernando 12/08/2020

# Script para monitoramento de autenticação Duo via RADIUS

# Parâmetros

user=''
password=''
radiusserver=''
radiuspwd=''
port=''

# Gera autenticação
request=`radtest $user $password $radiusserver $port $radiuspwd`

# Se contiver a string "Received Access-Accept", retorna 1. Se não, retorna 0.

if [[ $request == *"Received Access-Accept"* ]]; then
        echo "1"

else
        echo "0"

fi
