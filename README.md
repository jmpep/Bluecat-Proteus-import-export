*Bluecat network Proteus import export*
# summary
create a bulk import export script for the Bluecat Network Proteus IPAM (IP address manager) in Powershell Import, export, delete, list of subnets, IP-Addresses, devices, Tags, ...

# Before to use
*create an API user on GUI IPAM Proteus
*Bluecat Network Proteus must allow the API access for the device you are using the script. Configure with SSH "configure additional".

# Info
* input file: the CVS input file must have the same name as the script file
* log file: the log file will have the same name as the script file

# Usage
Insert you commands in the csv file.
"#" at the begining means comment. This line will be ignored.
In csv's file the title line (begining with "TITLE") give the format of the next actions. So you can fix the order of the fields in the actions. This allow you the create the csv from any Tabulator programs like Excel, open office, ....
Most of the time the names of the fields in the TITEL are the same as defined in the Proteus.
The field "action" (see Format) allows to do some different actions.
##Format:
the format is comma separated, for a list of IP it is separated with ";" in order to differenciate it from ','
 action,parameter1,prameter2,parameter3,parameter4,parameterX,...
 Option "action": always first. If "action" contains "_FORCE" that means deleted if it exists 
 if action is "TITLE" the line is treated as title and give the order of the actions' fields.
### Possible actions:
    CONFIG-NAME
    ADD_IP,ADD_IP_FORCE,MODIFY_IP,DEL_IP,ADD_SUBNET,ADD_SUBNET_FORCE
    ,MODIFY_SUBNET,ADD_DEVICE,ADD_DEVICE_FORCE,DEL_DEVICE,MODIFY_DEVICE,ADD_TAG,MODIFY_TAG
    ,SEARCH_SUBNET,LISTIPS
### action in developement:
    LISTTAGS

## Remarks
the additional fields must exist ! the name in the TITLE command must be the same as the field
