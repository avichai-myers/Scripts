Slack alert script for hosts that are removed from MDMs

Compares previous states and then sends a message to a Slack channel's webhook if a host's serial number is missing from the respective MDM's API response.


BEFORE RUNNING:
    
    Update the main mdm_device_deletion_workflow.sh and intune_serials.py to work either locally or with AWS S3
    Also update any endpoints that require adjustments (for e.g. the Kandji endpoint in mdm_device_deletion_workflow.sh)

    Update the mdm_deletion_config.sh with the relevant secrets

    Create a .gitignore file and add the updated mdm_deletion_config.sh to it so it doesn't commit those secrets

CLI TO RUN:

    ./mdm_device_deletion_workflow.sh