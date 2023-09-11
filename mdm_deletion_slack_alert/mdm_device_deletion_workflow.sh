#!/bin/bash
set -xe

# Adjust the script below based on option 1 or 2
# Option 1: Use AWS S3 to store the previous state
# Option 2: Use a local file to store the previous state

# Source Kandji devices from API
echo "Calling Kandji API...
"

kandji=()

# Function to fetch devices and populate the arrays
fetch_devices() {
    local offset="$1"
    local limit=300

    # Fetch devices' serial numbers and append to kandji array (Update the URL with your Kandji client name and region)
    while IFS= read -r line; do
        kandji+=("$line")
    done < <(curl --location --request GET "https://CLIENT-NAME.clients.REGION.kandji.io/api/v1/devices?limit=$limit&offset=$offset" \
    --header "Authorization: Bearer $API_KEY_KANDJI" | jq -r '.[] | .serial_number')
}

# Fetch devices with offset 0
fetch_devices 0

# Fetch devices with offset 300
fetch_devices 300

# Send Slack notification function
send_slack_notification() {
    local serial_number="$1"

    # Prepare the notification message with the missing serial number
    local notification_message=""
    notification_message+="\n- $serial_number"

    # Prepare the payload for the Slack webhook
    local payload='{"text": "'"$notification_message"'"}'

    # Send the HTTP POST request to the Slack webhook
    curl -X POST -H "Content-type: application/json" --data "$payload" "$SLACK_KANDJI_WEBHOOK_URL"
}

# Load the previous state from the file

# OPTION 1: Load the previous state from the file if it exists in AWS S3
#previous_state_file="kandji_previous_state.json"
#if [[ $(aws s3 ls s3://BUCKET_NAME/$previous_state_file) ]]; then
#    echo "Previous Kandji state file found, loading previous state..."
#    aws s3 cp s3://BUCKET_NAME/$previous_state_file $previous_state_file
#else
#    echo "No previous Kandji state file found, starting from scratch..."
#fi

# OPTION 2: Load the previous state from the file if it exists locally
previous_state_file="kandji_previous_state.json"
previous_devices=()
if [[ -f "$previous_state_file" ]]; then
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue  # Skip empty lines
        previous_devices+=("$line")
    done < "$previous_state_file"
fi

# OPTION 1: Save the current state to the file as a JSON array and write to S3
#printf "%s\n" "${kandji[@]}" > "$previous_state_file"
#aws s3 cp $previous_state_file s3://BUCKET_NAME/$previous_state_file

# OPTION 2: Save the current state to the file as a JSON array locally
printf "%s\n" "${kandji[@]}" > "$previous_state_file"

# Compare the current devices with the previous run and send notifications for missing devices
notification_message=""
deleted_device_count=0

for device in "${previous_devices[@]}"; do
    if [[ ! " ${kandji[@]} " =~ " $device " ]]; then
        # Device is missing, add to the notification message
        if [[ $deleted_device_count -eq 0 ]]; then
            notification_message="Devices have been deleted in Kandji:"
        fi
        notification_message+="\n- $device"
        ((deleted_device_count++))
    fi
done

# Send the notification to Slack if there are deleted devices
if [[ $deleted_device_count -gt 0 ]]; then
    send_slack_notification "$notification_message"
fi

# Source Intune devices from API
echo "Calling Microsoft Graph API...
"

intune=()

while IFS= read -r line; do
    intune+=("${line}")
done < <(python3.9 ./intune_serials_call.py)