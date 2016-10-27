*Bluecat network Proteus import export*
# summary
create a bulk import export script for the Bluecat Network Proteus IPAM (IP address manager) in Powershell Import, export, delete, list of subnets, IP-Addresses, devices, Tags, ...

# Before to use
*create an API user on GUI IPAM Proteus
*Bluecat Network Proteus must allow the API access for the device you are using the script. Configure with SSH "configure additional".

# Info
* input file: the CVS input file must have the same name as the script file
* log file: the log file will have the same name as the script file

# actions:
## Possible actions:
    CONFIG-NAME
    ADD_IP,ADD_IP_FORCE,MODIFY_IP,DEL_IP,ADD_SUBNET,ADD_SUBNET_FORCE
    ,MODIFY_SUBNET,ADD_DEVICE,ADD_DEVICE_FORCE,DEL_DEVICE,MODIFY_DEVICE,ADD_TAG,MODIFY_TAG
    ,SEARCH_SUBNET,LISTIPS
## action in developement:
    LISTTAGS

# REMARKS
the additional fields must exist ! the name in the TITLE command must be the same as the field
