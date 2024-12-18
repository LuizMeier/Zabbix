#!/usr/bin/python
# -*- coding: utf-8 -*-

# Script to monitor Palo Alto's IPSec tunnels

# 05/08/2024 - Created by Luiz Meier / Reristen Souza

# Import libraries
import requests
import json
import sys
import xml.etree.ElementTree as ET

# Define the variables to be used
firewall = sys.argv[1]  # Firewall's address
username = sys.argv[2]  # Username
password = sys.argv[3]  # Password
action = sys.argv[4]    # Action

# As the tunnel name parameter is optional, it is necessary to have this conditional. Otherwise Python will return an error because the variable is missing.
if len(sys.argv) > 5:
    tunnel = sys.argv[5]    # Tunnel name

# Optional - Disable the self-signed certificate warning
requests.packages.urllib3.disable_warnings()

# Generate the base url
api_url = 'https://' + firewall + '/api'

# Authentication
# Authenticating and getting a token
query = {"type": "keygen", "user": username, "password": password}
response = requests.get(api_url, verify=False, params=query)

# Check the response status code
if response.status_code != 200:
    print("Erro! [", response.status_code, "]")
    sys.exit()

# Handling the xml response
root = ET.fromstring(response.text)

# Get the key value and assign to the variable
key_value = root.find(".//key").text

# Generates the authorization header to be used
api_key = {
    "X-PAN-KEY": key_value
}
###

# Validate the parameter 'action'
if action != 'discovery' and action != 'status':
    print('Parâmetro inválido')

# If the action value is 'discovery', perform the LLD. This JSON is used by Zabbix to create the monitoring items.
if action == "discovery":
    

    # Capturing the firewall version
    query = {"type": "version"}
    response = requests.get(api_url, verify=False, params=query, headers=api_key)
   
    # Check the response code
    if response.status_code != 200:
        print("Erro! [", response.status_code, "]")
        sys.exit()
      
    # Handling the XML
    root = ET.fromstring(response.text)

    # Get the sw'version' value and assign it to the variable.
    ver_value = root.find(".//sw-version").text

    # PanOS only accepts the first two numbers of the version number. Splits this value to be in the correct format.
    ver_value = ver_value.split(".")[0] + "." + ver_value.split(".")[1]

    # Generates the url to be used in the rest api call
    restapi_url = 'https://' + firewall + '/restapi' + '/v' + ver_value 
    ###
    
    # Generate the url
    query_url = restapi_url + '/Network/IPSecTunnels'

    # Assign the values
    params = {
        'location': 'panorama-pushed',
    }

    # Call the firewall and capture the IPSec tunnels list.
    ipsec_tunnels_raw = requests.get(query_url, verify=False, headers=api_key, params=params)

    # Checks the response code
    if response.status_code != 200:
        print("Erro! [", response.status_code, "]")
        sys.exit()

    # Handle the group
    ipsec_tunnels = json.loads(ipsec_tunnels_raw.text)
    
    # Print the discovery JSON
    print('{')
    print('"data":[')
    for tunnel in ipsec_tunnels["result"]["entry"]:
        a = '{"{#TUNNELNAME}":"' + tunnel["@name"] + '"},'
        
        if tunnel["@name"] != ipsec_tunnels["result"]["entry"][-1]["@name"]:
            print(a)
        
        else:
            a = '{"{#TUNNELNAME}":"' + tunnel["@name"] + '"}'
            print(a)
    print(']')
    print('}')


# If the action is to get tunnel status, check it.
if action == "status":
    
    # Generate the information place inside the xml
    tunnel_location = '<show><vpn><flow><name>' + tunnel + '</name></flow></vpn></show>'

    # Mount the header
    params = {
        'type': 'op',
        'cmd': tunnel_location
    }

    # Call the api
    status_tunnel_raw = requests.get(api_url, verify=False, headers=api_key, params=params)

    # Check the responde code
    if response.status_code != 200:
        print("Erro! [", response.status_code, "]")
        sys.exit()

    # Handle the XML value
    root = ET.fromstring(status_tunnel_raw.text)

    # Assign the value of "state" to the variable
    status = root.find(".//state").text

    # Print the result value, according to the status
    if status == 'active':
        print('1')
    else:
        print('0')
