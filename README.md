#Bluecat network Proteus import export
 create, add, modify IPs,devices,TAGs,subnets

# summary
create a bulk import export script for the Bluecat Network Proteus IPAM (IP address manager) in Powershell Import, export, delete, list of subnets, IP-Addresses, devices, Tags, ...

# Before to use
* create an API user on GUI IPAM Proteus
* Bluecat Network Proteus must allow the API access for the device you are using the script. Configure with SSH 'configure additional'.
* the user defined fields you are using in the csv file must exist ! Example if you want a 'description' in device' object. Ask your administrator if you need new fields for a dedicated object' type like Device, IP4Address, IP4Networks, ...
* Create a csv file and insert your commands. By default the CVS's input file will have the same name as the script file. Otherwise use the options.

# Info
* input file: by default the CVS input file name must have the same name as the script file. ex: import.ps & import.csv. You can change the option with coomand file.
* log file: by default the log file will have the same name as the script file. You can change the option with coomand file.
* output file: by default the log file will have the same name as the script file. You can change the option with coomand file. 

# Usage
` <file>.ps [-level] [-ip <ip>] [-help] [-commands <input file name>] [-output <output file name>] [-user <APIusername>] [-password <password>]`
 If you omit some option a prompt will ask you

## '#' at the begining means comment. This line will be ignored.
So you can fix the order of the fields in the actions. This allow you the create the csv from any Tabulator programs like Excel, open office, ....
Most of the time the names of the fields in the TITEL are the same as defined in the Proteus.
The field 'action' (see Format) allows to do some different actions.
## Format of the csv file:
 the format is comma separated, for a list of IP it is separated with ";" in order to differenciate it from ','
 you need at least a line with CONFIG-NAME,... a line with TITLE.... an line with actions,....
 CONFIG-NAME will set your default configuration you are working for the commands which need it
 action,parameter1,prameter2,parameter3,parameter4,parameterX,...
 Option 'action': always first. If 'action' contains '_FORCE' that means deleted if it exists 
 'TITLE' the line is treated as title and give the order of the actions' fields. So it format the action lines 
### possible actions
    CONFIG-NAME,ADD_IP,ADD_IP_FORCE,MODIFY_IP,DEL_IP,ADD_SUBNET,ADD_SUBNET_FORCE
    ,MODIFY_SUBNET,ADD_DEVICE,ADD_DEVICE_FORCE,DEL_DEVICE,MODIFY_DEVICE,ADD_TAG,MODIFY_TAG
    ,SEARCH_SUBNET,LIST_DEVICES,LIST_IPS,COMMENT_OUTPUT
### action in developement
    DEL_SUBNET,LIST_DEVICE_WITHOUT_IP,LISTTAGS
## Examples
 I added for testing the examples some new fields and device'types like
   in IP4Network  : 'description,vlan'
   in IP4Address  : 'description,virtual'
   in Tags        : 'description,usedby,last-seen,alternative-name'
   in device'types: 'printer,PC'

##example global config
CONFIG-NAME,NetworkConfig1

##example SUBNETs + example own fields description & vlan
# cidr (obligatory fields) for the search
# Obligatory is the name's fields.
# optional the other fields. Ask your Proteus's administrator for having the name of the fields
#TITLE_SUBNET,cidr,name,description,vlan
#ADD_SUBNET,10.1.0.0/24,network_10.1.0.0_24,add subnet if not exist,vlan50
#MODIFY_SUBNET,10.1.0.0/24,network_10.1.0.0_24,modified subnet when field not empty,vlan51
#ADD_SUBNET,10.2.0.0/24,net_10.2.0.0_24,add subnet if not exist,VLAN2
#
##example IPs  + example own fields description & virtual
TITLE_IP,name,ip,description,virtual
ADD_IP_FORCE,TEST_1,10.1.0.5,rewritten 10.1.0.5,1
ADD_IP,TEST_gateway,10.1.0.1,updating gateway 10.1.0.1,1

##example for Delete IP
# Obligatory is the IP's fields which could be ip or IP4Address
# optional the other fields. Ask your Proteus's administrator for having the name of the fields
DEL_IP,,10.1.0.10,,,,,,
DEL_IP,,10.1.0.11,,,,,,
DEL_IP,,10.1.0.12,,,,,,
DEL_IP,,10.1.0.13,,,,,,
DEL_IP,,10.1.0.14,,,,,,
DEL_IP,,10.1.0.15,,,,,,
DEL_IP,,10.1.0.16,,,,,,
DEL_IP,,10.1.0.17,,,,,,

DEL_IP,,10.1.0.5,,,,,,
DEL_IP,,10.1.0.254,,,,,,
ADD_IP,TEST_10,10.1.0.10,added TEST 10,false
ADD_IP,TEST_11,10.1.0.11,added TEST 11,true
ADD_IP,TEST_12,10.1.0.12,added TEST 12,true
ADD_IP,TEST_13,10.1.0.13,added TEST 13,false
ADD_IP,TEST_14,10.1.0.14,added TEST 14,false
ADD_IP,TEST_15,10.1.0.15,added TEST 15,true
ADD_IP,TEST_16,10.1.0.16,added TEST 16,true
ADD_IP,TEST_17,10.1.0.17,added TEST 17,false
ADD_IP_FORCE,TEST_5,10.2.0.5,added TEST 5,true
ADD_IP_FORCE,TEST_6,10.2.0.6,added TEST 6,true
MODIFY_IP,TESTNEW_10,10.1.0.17,modified TEST 17,

###example for devices
##info:
## Obligatory is the name's fields.
## optional the other fields. Ask your Proteus's administrator for having the name of the fields
##
TITLE_DEVICE,name,DeviceType,DeviceSubtype,ip4Addresses,description
DEL_DEVICE,test-device1,,,,,
ADD_DEVICE,test-device1,PC,,10.1.0.10;10.1.0.11,added test-device1,
MODIFY_DEVICE,test-device1,printer,,+10.1.0.15;+10.2.0.6;-10.1.0.17;-10.1.0.11,modified test-device1,
ADD_DEVICE,test-device2,PC,,10.1.0.11,added test-device2
ADD_DEVICE_FORCE,test-device3,printer,,10.1.0.12,delete and replace test-device3


##example for Tags (example for VLANs or other tags'groups)
#info:
# Obligatory is the taggroup's and name's fields.
# optional the other fields. Ask your Proteus's administrator for having the name of the fields
# special is the parent-object-field because some overlapping with different parent's type.
#   parent-object-field is:
#     . 'IP4Address' for binding an IP address,
#     . 'cidr' or 'IP4Network:cidr' for a IP4Network,
#     . IP4Block:cidr for an IP Block, other possibilities will follow when requested
# special is CONFIG-NAME for linking object of an other configuration
#
TITLE_TAG,taggroup,name,description,cidr,usedby,last-seen,alternative-name
ADD_TAG_FORCE,ListOfVlans,VLANXXXtest,test tag 1,10.2.0.0/24;10.0.2.0/24,devicexxx,Friday,myvlan
ADD_TAG,ListOfVlans,VLANYYYtest,test tag 2,10.1.0.0/24,deviceyyy,lasttime,yourvlan
TITLE_TAG,taggroup,name,description,IP4Block:cidr,usedby
ADD_TAG,MygroupTest1,test-block-tag1,test block tag 1,10.0.0.0/8,a-lot-of
#now link a second object to the TAG
TITLE_TAG,CONFIG-NAME,taggroup,name,description,IP4Address,usedby
ADD_TAG,NetworkConfig3,ListOfVlans,VLANYYY,test tag YYY,10.1.0.16,deviceyyy,lasttime,yourvlan
MODIFY_TAG,NetworkConfig1,ListOfVlans,VLANYYY,modified by someone,10.1.0.17,super user

##search subnet
# info:
#  cidr (obligatory fields) for the search
#  configuration (optional field) for searching in a specific configuration or all
#  other fields will be show in the output
#  at least -> TITLE_SEARCHSUBNET,cidr
#  or example TITLE_SEARCHSUBNET,name,yourownfield,cidr,id,configuration,description
##
COMMENT_OUTPUT,#
COMMENT_OUTPUT,SEARCHING OF SUBNETS
TITLE_SEARCHSUBNET,name,cidr,id,configuration,description
SEARCHSUBNET,,10.1.0.0/24,,all
SEARCHSUBNET,,10.2.0.0/24,,all
TITLE_SEARCHSUBNET,cidr,name,configuration,description
SEARCHSUBNET,10.1.0.0/24,,NetworkConfig2,

##list IPs of subnet
# info:
#  cidr (obligatory fields) for the search
#  configuration (optional field) for searching in a specific configuration or all
#  adding other fields will be show in the output
#  in the output you will see the fields you have added
#  at least -> TITLE_LISTIPS,cidr
#  or example TITLE_LISTIPS,name,yourownfield,cidr,id,configurationX,description
##
COMMENT_OUTPUT,#
COMMENT_OUTPUT,LIST of all devices
TITLE_LISTIPS,cidr,configuration,name,address,state,type
LISTIPS,10.1.0.0/24,all
LISTIPS,10.2.0.0/24

##list Devices
# info:
#  filter (special fields) for the search. If filter is empty it will search all devices.
#    filter could be a RegEX
#  configuration (optional field) for searching in a specific configuration or all
#  deviceType (special field) for seeing the Device type name
#  adding other fields will be show in the output
#  in the output you will see the fields you have added
#  at least -> TITLE_LISTDEVICES,name
#  or example TITLE_LISTDEVICES,name,yourownfields,id,configurationX,deviceTypeId,deviceType
##Example
COMMENT_OUTPUT,#
COMMENT_OUTPUT,LIST of all devices
TITLE_LISTDEVICES,name,configuration,IP4Addresses,state,type,deviceType,description
LISTDEVICES,,all
COMMENT_OUTPUT,#
COMMENT_OUTPUT,LIST of devices with first 'te' then any char and 't'
TITLE_LISTDEVICES,filter,configuration,name,IP4Addresses,type,deviceTypeId,deviceType,description
LISTDEVICES,te.*t,all

