#
'''
05/03/2024

Luiz Fernando Mizael Meier - 

Adaptation of code to be used passing parameters. The goal is to be used as a custom script inside your monitoring tool.

You may edit it at your will. There is a lot to be done on this script.

Adapted from:
https://github.com/rbonicenha/PaloAlto

References
https://docs.paloaltonetworks.com/pan-os/9-1/pan-os-panorama-api/get-started-with-the-pan-os-rest-api/access-the-rest-api
https://www.packetswitch.co.uk/getting-started-with-palo-alto-rest-api/
https://live.paloaltonetworks.com/t5/automation-api-discussions/rest-api-parameter-error-for-non-vsys-device/td-p/390273
https://yourFirewall/restapi-doc/
https://realpython.com/api-integration-in-python/

W3Schools
A lot of research on the internet
'''

# Import libraries
import requests
import json
import sys
import xml.etree.ElementTree as ET

# Define the variables that will be used as argument when the script is called
firewall = sys.argv[1]  # Firewall address
action = sys.argv[2]    # Action to be taken (up or down)
group = sys.argv[3]     # Address group name
host = sys.argv[4]      # Host to be added or removed
username = sys.argv[5]  # Username
password = sys.argv[6]  # Password

# Optional - Disables the self-signed certificate warning
requests.packages.urllib3.disable_warnings()

# Generates the base url
api_url = 'https://' + firewall + '/api'

# Authenticating and getting the token
query = {"type": "keygen", "user": username, "password": password}
response = requests.get(api_url, verify=False, params=query)

# Parsing the XML
root = ET.fromstring(response.text)

# Takes the key value and replaces the variable
key_value = root.find(".//key").text

# Generates the authorization header to be used
api_key = {
    "X-PAN-KEY": key_value
}
###

###
# Captures the firewall version
query = {"type": "version"}
response = requests.get(api_url, verify=False, params=query, headers=api_key)

# Parsing the XML
root = ET.fromstring(response.text)

# Get the key value and fills the variable
ver_value = root.find(".//sw-version").text

# PanOs only understands the first two values of the version number. Then splits to be in the expected format
ver_value = ver_value.split(".")[0] + "." + ver_value.split(".")[1]

# Mounts the url that will be used to call the api
restapi_url = 'https://' + firewall + '/restapi' + '/v' + ver_value 

###
# Get the group
query_url = restapi_url + '/Objects/AddressGroups'

# Fill the parameters
location = {
    'location': 'vsys',
    'vsys': 'vsys1',
    'name': group
    }

# Calls the firewall and gets the content of the address grou´p
addr_group_raw = requests.get(query_url, verify=False, headers=api_key, params=location)

# Parses the reponse
addr_group = json.loads(addr_group_raw.text)
###

###
# Evaluates the action sent by the user
# If it is down
if action == "down":

    # Checks if the host to be treaten existe in the address group. If exists, remove it from the array
    if host in addr_group["result"]["entry"][0]["static"].get('member'):
        addr_group["result"]["entry"][0]["static"]["member"].remove(host)

    # If the informed host does not belong to the group, warns and abort
    else:
        print("The host does not belong to the group. Aborting......")
        exit ()

# If the action is up
elif action == "up":

     # Checks if the host to be traten exists in the group. If it does, warn and abort.
    if host in addr_group["result"]["entry"][0]["static"].get('member'):
        print("Host is already on the group. Aborting...")
        exit ()

    # If the host does not belong to the group, add it to the array.
    else:
        addr_group["result"]["entry"][0]["static"]["member"].append(host)

# If not up or down, warns and aborts.
else:
   print("Incorrect action. Aborting")
   exit ()
###

###
# Creates a new body to edit the object (member wil come already with [])
addr_group_updated = {
    "entry": {
        "@name": group,
        "static": {
            "member": addr_group["result"]["entry"][0]["static"]["member"]
        }
    }
}

# Edit the object
requests.put(query_url, params=location, verify=False, headers=api_key, json=addr_group_updated)

# Mount the url to commit
commit_url = 'https://' + firewall + '/api?type=commit&cmd=<commit></commit>'

# Commits the settings
requests.post(commit_url, verify=False, headers=api_key)