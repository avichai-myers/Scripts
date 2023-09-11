#!/bin/bash

source falcon_mdm_config.sh 
source falcon_exclusions.sh
source intune_exclusions.sh
source kandji_exclusions.sh

echo ""
echo \
"             ------------------------------------
      :.                                                
       ==.    ::                                        
        :*+:   :+:                                      
        . :+*-.  -+-                                    
        .=. .=*+-  :++-.                                
          -+-  :+#+-  -**+-:                            
            :++-  :=*+- :+###*+-:.                      
              .-++=: .-+= :*#######*+=-:.               
                  :=++- .=: +############*+-:           
                      :==:.. =###############*=         
                         .-.  -################:        
                  ..           :*#############+         
                   .---::==:     -*###########+-:.      
                      .:=+*##+: .: :=+**##****####*+-.  
                            .:-=:.=*+====++******++*++. 
                                   .=############*+=-=*-
                                    :=#####*+=-:       -
                                      -*####+=-::       
                                       .:::**.  ::      
              
              Falcon - MDM - Host Comparison V1.3

             -------------------------------------
          "                                 

echo \

#source falcon devices from API
echo Initialising...
echo Calling Falcon API...
falcon=()

while IFS= read -r line; do
    falcon+=("${line}")
done < <(python3.9 ./falcon_api_call_serial.py -k $API_KEY_ID_FALCON -s $API_KEY_SECRET_FALCON)

#echo ${falcon[@]}

#source intune devices from API
echo "Calling Microsoft Graph API..."

intune=()

while IFS= read -r line; do
    intune+=("${line}")
done < <(python3.9 ./intune_api_call_serials.py)

#source kandji devices from API
echo "Calling Kandji API...

"

kandji=()
kandji_hostnames=()

# Function to fetch devices and populate the arrays
fetch_devices() {
    local offset="$1"
    local limit=300

    # Fetch devices' serial numbers and append to kandji array (Update the URL with your Kandji client name and region)
    while IFS= read -r line; do
        kandji+=("$line")
    done < <(curl --location --request GET "https://CLIENT-NAME.clients.REGION.kandji.io/api/v1/devices?limit=$limit&offset=$offset" \
    --header "Authorization: Bearer $API_KEY_KANDJI" | jq -r '.[] | .serial_number')

    # Fetch devices' serial numbers and device names and append to kandji_hostnames array (Update the URL with your Kandji client name and region)
    while IFS= read -r line; do
        kandji_hostnames+=("$line")
    done < <(curl --location --request GET "https://CLIENT-NAME.clients.REGION.kandji.io/api/v1/devices?limit=$limit&offset=$offset" \
    --header "Authorization: Bearer $API_KEY_KANDJI" | jq -r 'unique_by(.serial_number) | .[] | "\(.serial_number) - \(.device_name)"')
}

# Fetch devices with offset 0
fetch_devices 0

# Fetch devices with offset 300
fetch_devices 300

# Define empty arrays to store the unique items
unique_falcon=()
unique_intune=()
unique_kandji=()


# Loop through each array and check for unique items
for array in "${falcon[@]}" "${intune[@]}" "${kandji[@]}"; do
    # Count how many times the current item appears in all three arrays
    count=0
    for a in "${falcon[@]}" "${intune[@]}" "${kandji[@]}"; do
        if [[ "$a" == "$array" ]]; then
            ((count++))
        fi
    done
    # If the item appears only once, add it to the appropriate unique list
    if [[ $count -eq 1 ]]; then
        if [[ " ${falcon[@]} " =~ " $array " ]]; then
            unique_falcon+=("$array")
        elif [[ " ${intune[@]} " =~ " $array " ]]; then
            unique_intune+=("$array")
        elif [[ " ${kandji[@]} " =~ " $array " ]]; then
            unique_kandji+=("$array")
        fi
    fi
done

# Remove exclusions from arrays
for f in "${falcon_exceptions[@]}"; do
         unique_falcon=(${unique_falcon[@]//*$f*})
done

for k in "${kandji_exceptions[@]}"; do
         unique_kandji=(${unique_kandji[@]//*$k*})
done

for i in "${intune_exceptions[@]}"; do
         unique_intune=(${unique_intune[@]//*$i*})
done

echo "
|Access authorised|"

# Print out the unique items for each array
echo  "  
    
  //    /                               
    ///   //                            
   //  ///   ///                        
      ///  ///  //////                  
          ///  // ////////////          
               /,  //////////////       
                     ////////////       
             ////// /  /////////////    
                    // ////////////*/// 
                        ///////////    ¶
                           ////////     
                               / |        

Devices unique to CrowdStrike Falcon: "
# Call for serial's matching hostnames
while IFS= read -r falcon_hostnames; do
    falcon_tuples+=("${falcon_hostnames}")
done < <(python3.9 ./falcon_api_call_hostname.py -k $API_KEY_ID_FALCON -s $API_KEY_SECRET_FALCON)



# Loop through each unique item
for item in "${unique_falcon[@]}"; do
    # Use grep to search for tuples containing the current item
    matching_tuples=($(printf '%s\n' "${falcon_tuples[@]}" | grep -F "('$item',"))

    # Check if any matching tuples were found
    if [ ${#matching_tuples[@]} -gt 0 ]; then
        # If matching tuples are found, format and print them on a single line
        formatted_tuples=""
        for tuple in "${matching_tuples[@]}"; do
            # Format the tuple using awk to remove parentheses and single quotes
            formatted_tuple=$(echo "$tuple" | awk -F"'" '{print $2 " - " $4}')

            # Append the formatted tuple to the existing formatted_tuples string
            if [ -z "$formatted_tuples" ]; then
                formatted_tuples="$formatted_tuple"
            else
                formatted_tuples+=" $formatted_tuple"
            fi
        done

        # Use sed to remove the trailing hyphen and space at the end of the formatted tuples, if they exist
        formatted_tuples=$(echo "$formatted_tuples" | sed 's/\(.*\) - $/\1/')

        # Print the formatted tuples on a single line
        echo "$formatted_tuples"
    fi
done

echo "
-------
"

echo "
                             ..╓╔╦Mφφ▒╠▒
              ..  ╔φφ▒▒╠╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠
╓╔ε≥φφ▒▒╠▒▒▒▒▒▒▒  ╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒  ╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒  ╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒  ╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠
╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒  ╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠
╩╩╩╩╩╚╚╚╚╚╚╚╚╚╙╙  ²╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙└
╔╔╔╔╔╔╔╔╔╔╔╔╔╔╔╔  ╓╓╓╓╓╓╓╓╓╓╓╓╓╓╓╓╓╓╓╓╓-
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒  ╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╡
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒  ╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╡
╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒  ╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠
╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒  ╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠
╙╚╩╩╠▒▒▒▒▒▒▒▒▒▒▒  ╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠
             ***  ╙╩╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠
                                ╙╚╩╩╠▒▒╠

Devices unique to Intune: "
intune=()

while IFS= read -r line; do
    intune_tuples+=("${line}")
done < <(python3.9 ./intune_api_call_hostnames.py)

# Loop through each element in intune_tuples
for item in "${intune_tuples[@]}"; do
    # Extract the first part of the element (before the first space) to compare with unique_intune
    key="${item%% *}"
    
    # Check if the extracted key is present in unique_intune array
    if [[ " ${unique_intune[*]} " == *" $key "* ]]; then
        # If found, print the entire element
        echo "$item"
    fi
done

echo "
-------
"

echo " .....             ..             ..... 
.........         ....         .........
...........      ______      ...........
  ...........    ......    ...........  
   ............  ......  ............   
      ............................      
     ........... ...... ...........     
      ........ .......... ........      
               __________               
                             
               ..........               
                ________                
                  ....       

Devices unique to Kandji: "

# Loop through each element in kandji_hostnames
for item in "${kandji_hostnames[@]}"; do
    # Extract the first part of the element (before the first space) to compare with unique_intune
    key="${item%% *}"
    
    # Check if the extracted key is present in unique_intune array
    if [[ " ${unique_kandji[*]} " == *" $key "* ]]; then
        # If found, print the entire element
        echo "$item"
    fi
done

echo "
-------
"
