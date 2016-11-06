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
  
 '#' at the begining means comment. This line will be ignored.
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
Before to use I added some new fields and device'types like  
* in IP4Network  : 'description,vlan'
* in IP4Address  : 'description,virtual'
* in Tags        : 'description,usedby,last-seen,alternative-name'
* in device'types: 'printer,PC'
   
Look at the csv example *IPAM-import_export.csv*
