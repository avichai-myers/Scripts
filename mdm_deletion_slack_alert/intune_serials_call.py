#!/usr/bin/env python

import json
import os
import requests
import boto3

# Adjust the script below based on option 1 or 2
# Option 1: Use AWS S3 to store the previous state
# Option 2: Use a local file to store the previous state

# OPTION 1: Set the path to the previous state file in AWS
# Create S3 Client
#s3 = boto3.client('s3')

# Check if the file with the previous state exists
#previous_state_file = "intune_previous_state.json"
#local_directory = "/app/"
# Bucket and Key that we want to check
#bucket_name = 'S3_BUCKET_NAME_HERE'

# Use head_object to check if the key exists in the bucket
#try:
#    resp = s3.head_object(Bucket=bucket_name, Key=previous_state_file)
#    print('Previous Intune state file found, loading previous state...')
#    s3.download_file(bucket_name, previous_state_file, local_directory+previous_state_file)
#except s3.exceptions.ClientError as e:
#    if e.response['Error']['Code'] == '404':
#        print('No previous Intune state file found, starting from scratch...')

# OPTION 2: Load the previous state from the file locally
previous_state = {}
if os.path.exists(local_directory+previous_state_file):
    with open(local_directory+previous_state_file, "r") as f:
        previous_state = json.load(f)

# Check if the file with the previous state exists
previous_state_file = "./intune_previous_state.json"
previous_state = {}
if os.path.exists(previous_state_file):
    with open(previous_state_file, "r") as f:
        previous_state = json.load(f)


# Load the environment variables directly from the shell
with open('./mdm_deletion_config.sh') as f:
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
SLACK_INTUNE_WEBHOOK_URL = os.environ['SLACK_INTUNE_WEBHOOK_URL']

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

data = json.loads(response.content.decode("utf-8"))
current_state = {device["serialNumber"]: device for device in data["value"]}

deleted_devices = []
for serial_number, device in previous_state.items():
    if serial_number not in current_state:
        deleted_devices.append(device)

# Save the current state to a file

# OPTION 1: Save the current state to a file
#with open(local_directory+previous_state_file, "w") as f:
#    json.dump(current_state, f)
# Upload the file to S3
#s3.upload_file(local_directory+previous_state_file, bucket_name, previous_state_file

# OPTION 2: Save the current state to a file
with open(previous_state_file, "w") as f:
    json.dump(current_state, f)

# Slack workflow
if deleted_devices:
    # Prepare the notification message with details of deleted devices
    notification_message = "- Devices have been deleted in Intune:\n"
    for device in deleted_devices:
        notification_message += f"- {device['serialNumber']}\n" 

    # Use the Slack API or the incoming webhook to send the notification
    # Replace the following line with your actual Slack notification logic
    print(notification_message)

# Prepare the payload for the Slack webhook
    payload = {
        "text": notification_message
    }

    try:
        # Send the HTTP POST request to the Slack webhook
        response = requests.post(SLACK_INTUNE_WEBHOOK_URL, json=payload)
        response.raise_for_status()
        print("Notification sent to Slack successfully.")
    except requests.exceptions.RequestException as e:
        print("Error sending notification to Slack:", e)
