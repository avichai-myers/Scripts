import json
import os
import requests


# Load the environment variables directly from the shell
with open('./falcon_mdm_config.sh') as f:
    for line in f:
        if line.startswith('export'):
            key, value = line.strip().replace('export ', '').split('=')
            os.environ[key] = value.strip('"')

# Set the endpoint URL
token_url = os.environ['INTUNE_TOKEN_URL']

# Set the request parameters
client_id = os.environ['INTUNE_CLIENT_ID']
client_secret = os.environ['INTUNE_CLIENT_SECRET']
scope = "https://graph.microsoft.com/.default"
grant_type = "client_credentials"

print("")

# Send the HTTP POST request to the endpoint
response = requests.post(
    token_url,
    data={
        "client_id": client_id,
        "client_secret": client_secret,
        "scope": scope,
        "grant_type": grant_type
    }
)

# Check if the response contains the access_token key
try:
    access_token = json.loads(response.content.decode("utf-8"))["access_token"]
except KeyError:
    print("Error: Failed to retrieve the access token.")
    exit(1)

# Set the headers for the request to the Microsoft Graph API
headers = {
    "Authorization": f"Bearer {access_token}",
    "Content-Type": "application/json"
}

# Set the URL for the request to the Microsoft Graph API
graph_api_url = "https://graph.microsoft.com/beta/deviceManagement/managedDevices?$select=serialNumber"

# Make the GET request to the Microsoft Graph API
response = requests.get(
    graph_api_url,
    headers=headers
)

# Print the response from the Microsoft Graph API
data = json.loads(response.content.decode("utf-8"))
for device in data["value"]:
    print(device["serialNumber"])