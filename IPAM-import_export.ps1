########################################################################
# create, add, modify IPs,devices,TAGs,subnets
# usage:
#   A logfile is created <same-name-as-script-name>.log
#   A commands' file is created <same-name-as-script-name>.csv
########################################################################
#
# CONFIGURE first:
# - an API user
# - the database for allowing access ( SSH on Proteus, configure additional, add allowed IP )
#########################################
#creation of inputs' file
#Introduction
# The "#" at the begining means comment. This line will be ignored.
# In datas'file the title line (begining with "TITLE") give the format of the field's name and number of fields.
#    For userfields patient until next version, the names of the fields in the TITEL line will be the same defined in the Proteus
# The field "action" (see Format) allows to do some different actions.
#Format:
#  the format is comma separated, for a list of IP it is separated with ";"
#     action,parameter1,prameter2,parameter3,parameter4,parameterX,...
#  Option "action": always first. If "action" contains "_FORCE" that means deleted if it exists 
#  if action is "TITLE" the line is treated as title (future developement)
#  other actions CONFIG-NAME,ADD_IP, ADD_IP_FORCE, MODIFY_IP, MODIFY_IP, ADD_SUBNET, ADD_SUBNET_FORCE
#  ADD_DEVICE, ADD_DEVICE_FORCE, MODIFY_DEVICE, ADD_TAG
#
#CONFIG-NAME,NetworkConfig1
#possible actions
#    CONFIG-NAME,ADD_IP,ADD_IP_FORCE,MODIFY_IP,DEL_IP,ADD_SUBNET,ADD_SUBNET_FORCE
#    ,MODIFY_SUBNET,ADD_DEVICE,ADD_DEVICE_FORCE,DEL_DEVICE,MODIFY_DEVICE,ADD_TAG,MODIFY_TAG
#    ,SEARCH_SUBNET
#action in developement
#    LIST_IP
#REMARKS: the additional fields must exist ! the name in the TITLE command must be the same as the field
#
#
##example SUBNETs + example own fields description & vlan
#TITLE_SUBNET,CIDR,name,description,vlan
#ADD_SUBNET,10.1.0.0/24,network_10.1.0.0_24,add subnet if not exist,vlan50
#MODIFY_SUBNET,10.1.0.0/24,network_10.1.0.0_24,modified subnet when field not empty,vlan51
#ADD_SUBNET,10.2.0.0/24,net_10.2.0.0_24,add subnet if not exist,VLAN2
##
##example IPs  + example own fields description & virtual
#TITLE_IP,name,ip,description,virtual
#ADD_IP_FORCE,TEST_1,10.1.0.5,rewritten TEST 5,1
#
#DEL_IP,,10.1.0.10,,,,,,
#DEL_IP,,10.1.0.11,,,,,,
#DEL_IP,,10.1.0.12,,,,,,
#DEL_IP,,10.1.0.13,,,,,,
#DEL_IP,,10.1.0.14,,,,,,
#DEL_IP,,10.1.0.15,,,,,,
#DEL_IP,,10.1.0.16,,,,,,
#DEL_IP,,10.1.0.17,,,,,,
#
#DEL_IP,,10.1.0.5,,,,,,
#DEL_IP,,10.1.0.254,,,,,,
#ADD_IP,TEST_10,10.1.0.10,added TEST 10,false
#ADD_IP,TEST_11,10.1.0.11,added TEST 11,true
#ADD_IP,TEST_12,10.1.0.12,added TEST 12,true
#ADD_IP,TEST_13,10.1.0.13,added TEST 13,false
#ADD_IP,TEST_14,10.1.0.14,added TEST 14,false
#ADD_IP,TEST_15,10.1.0.15,added TEST 15,true
#ADD_IP,TEST_16,10.1.0.16,added TEST 16,true
#ADD_IP,TEST_17,10.1.0.17,added TEST 17,false
#ADD_IP_FORCE,TEST_5,10.2.0.5,added TEST 5,true
#ADD_IP_FORCE,TEST_6,10.2.0.6,added TEST 6,true
#MODIFY_IP,TESTNEW_10,10.1.0.17,modified TEST 17,
###
###example for devices
#TITLE_DEVICE,name,DeviceType,DeviceSubtype,ip4Addresses,description
#DEL_DEVICE,test-device1,,,,,
#ADD_DEVICE,test-device1,switch,,10.1.0.10;10.1.0.11,added test-device1,
#MODIFY_DEVICE,test-device1,router,,+10.1.0.15;+10.1.0.12;-10.1.0.17;-10.1.0.11,modified test-device1,
##ADD_DEVICE,test-device2,Switch,,10.1.0.11,added test-device2,other_parameters_in_next_version
##ADD_DEVICE_FORCE,test-device3,Router,,10.1.0.12,delete and replace test-device3,other_parameters_in_next_version
###### add several IPs in device
##ADD_DEVICE,test1,PC,,10.1.0.10;12.1.0.11;12.1.0.12,descr test1,other_parameters_in_next_version
##ADD_DEVICE_FORCE,test1,PC,,10.1.0.13;12.1.0.14;12.1.0.15,descr test1,other_parameters_in_next_version
###next version ... MODIFY_DEVICE,test1,,,10.1.0.16,modified test1 when parameters not empty,other_parameters_in_next_version
###next version ... MODIFY_DEVICE,test1,,,10.1.0.17,modified test1 when parameters not empty,other_parameters_in_next_version
###example for Tags (example for VLANs or other groups' types)
##TITLE_TAG,name,taggroup,descr_tag,parent-object,description,other_parameters_in_next_version
##ADD_TAG,VLANXXX,ListOfVlans,Object1_to_tag,,other_parameters_in_next_version
##ADD_TAG,VLANYYY,ListOfVlans,Object2_to_tag,,other_parameters_in_next_version
###now link a second object to the TAG
##MODIFY_TAG,ADD_TAG,VLANYYY,ListOfVlans,Object3_to_tag,,other_parameters_in_next_version
#
##info subnet
##
#TITLE_SEARCHSUBNET,description,cidr
#SEARCHSUBNET,10.1.0.0/24,all
#SEARCHSUBNET,10.2.0.0/24,all
# END EXAMPLES ############
#
#global inline# global variables
$global:debugging="NO";
$pt= $MyInvocation.MyCommand.path
$pt= $pt.Replace(".ps1","");
$global:INPUT_FILE = $pt+".csv"
$global:OUTPUT_FILE = $pt+".out"
$global:isoutput = "YES";
$global:ERROR_FILE= $pt+".log"
$global:ERROR_LEVEL = "DEBUG"
#$global:wsdlPath = "http://$proteus/Services/API?wsdl"
$global:proteus = "127.0.0.1";
$global:wsdlPath = "https://$proteus/Services/API?wsdl"
$global:Configuration = "Network"
$MAXBLOCKS=1000;
$global:theFields = {action="action";name="name";ip="ip";descr_ip="descr_ip";descr_dev="description";type="DeviceType";subtype="DeviceSubtype"};
#define the minimal fields
$global:aFieldsIP  = @('TITLE_IP','name','ip');
$global:aFieldsSub = @('TITLE_SUBNET','CIDR','name');
$global:aFieldsDev = @('TITLE_DEVICE','name');
$global:aFieldsTag = @('TITLE_IP','name','taggroup');
$global:aFieldsSearchSub = @('TITLE_SEARCHSUBNET','name','cidr');
$global:nFieldsIP  = @{TITLE_IP=0;name=1;ip=2;};
$global:nFieldsSub = @{TITLE_SUBNET=0;name=2;CIDR=1;};
$global:nFieldsDev = @{TITLE_DEVICE=0;name=1;};
$global:nFieldsTag = @{TITLE_IP=0;name=1;taggroup=2;};
$global:nFieldsSearchSub = @{TITLE_SEARCHSUBNET=0;name=1;cidr=2;};
$global:listActions = "CONFIG-NAME","ADD_IP","ADD_IP_FORCE","MODIFY_IP","DEL_IP","ADD_SUBNET","ADD_SUBNET_FORCE","MODIFY_SUBNET","ADD_DEVICE","ADD_DEVICE_FORCE","DEL_DEVICE","MODIFY_DEVICE","ADD_TAG","MODIFY_TAG";
$global:listReadActions = @("SEARCHSUBNET","LIST_IP");
Set-Variable ERRDEV1 -value '1' #-option Constant 
Set-Variable ERRDEVPRO1 -value '2' #-option Constant 
Set-Variable ERRDEVPRO2 -value '3' #-option Constant 
Set-Variable ERRDEVPRO3 -value '4' #-option Constant 
Set-Variable ERRDEVPRO4 -value '5' #-option Constant 
Set-Variable ERRDEVPRO5 -value '6' #-option Constant 
Set-Variable ERRDEVPRO6 -value '7' #-option Constant 
Set-Variable ERRDEVPRO7 -value '8' #-option Constant 
Set-Variable ERRDEVPRO8 -value '9' #-option Constant 
Set-Variable ERRDEVPRO10 -value '10' #-option Constant 
Set-Variable ERRDEVTYP1 -value '20' #-option Constant 
Set-Variable ERRDEVTYP2 -value '21' #-option Constant 
Set-Variable ERRTAG1    -value '22' #-option Constant 
Set-Variable ERRTAG2    -value '23' #-option Constant 
Set-Variable ERRTAG3    -value '24' #-option Constant 
Set-Variable ERRFUNC1   -value '31' #-option Constant 
Set-Variable ERRFUNC2   -value '32' #-option Constant 
Set-Variable ERRFUNC3   -value '33' #-option Constant 
Set-Variable ERRFUNC4   -value '34' #-option Constant 
Set-Variable ERRSUBADDPRO1   -value '41' #-option Constant 
Set-Variable ERRSUBADDPRO2   -value '42' #-option Constant 
Set-Variable ERRSUBADDPRO3   -value '43' #-option Constant 
Set-Variable ERRSUBADDPRO4   -value '44' #-option Constant 

function ArrayToHash($a)
{
    $hash = @{};
    $i=0;foreach ($val in $a) { $hash.Add($val,$i);$i++; }
    return $hash;
}

function stringArray ($a) {
  $val = '';
  foreach ($b in $a) { if ($val -eq '') { $val= $b } else { $val = $val + "," + $b;} }
  return $val;
}
function stringHash ($a) {
  $val = '';
  $a1='';foreach ($i in $a.Keys.GetEnumerator() )  { if ($a1 -eq '') { $a1=$i; } else { $a1="$a1,$i"; }};
  $a2='';foreach ($i in $a.Values.GetEnumerator() ){ if ($a2 -eq '') { $a2=$i; } else { $a2="$a2,$i"; }};
  $val = '{(' + $a1 + ')=(' + $a2 + ')}';
  return $val;
}
##############################################
# read information from console
# input:
#   @name    address from variable name
#   @pass    address from variable password
# return:
#   @none
##############################################
function getInputs([ref]$name,[ref]$pass,[ref]$input1, [ref] $out) {
 $ip = Read-Host 'IP (' $global:proteus ' )? Enter to keep this one'
 if ($ip -ne '') { $global:proteus=$ip };
 $outtxt = 'Output in file ['+$global:isoutput+']?';
 $outtmp = Read-Host $outtxt;
 if ($outtmp.ToUpper() -ne '') {
  if (($outtmp.ToUpper() -eq 'Y') -or ($outtmp.ToUpper() -eq 'YES')) { $out = 'YES'}
 } else {
  $out= $global:isoutput;
 }
 $name.Value = Read-Host 'DB username?'
 $passcypher = Read-Host 'DB password?' -AsSecureString
 $pass.Value=[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($passcypher));
}

##############################################
# output and error messages
# input:
#   @msg    message
#   @typmsg "ERROR","WARNING","INFO","OK"
#   @o      output in file
# return:
#   @none
##############################################
function sendMessages( ${msg}, ${typmsg} ="", $out="") {
    $color = "white";$background='';
    $atypmsg = @{
                 DEBUGGING=@{color="white";background="Red";level=0};
                 DEBUG=@{color="white";background="";level=0};
                 INFO=@{color="yellow";background="";level=10};
                 WARNING=@{color="magenta";background="";level=20};
                 ERROR=@{color="red";background="";level=30};
                 NORMAL=@{color="white";background="";level=40}
                 OK=@{color="green";background="";level=40}
                };
    if (-not $atypmsg.ContainsKey($typmsg)) {
       $typmsg = "INFO";
    }
    if (-not $atypmsg.ContainsKey($ERROR_LEVEL)) {
       $typmsg = "INFO";
    }
    if ($out -eq "YES" ) {
        Write-Output $msg | Out-File $OUTPUT_FILE -Append
    }
    if ($atypmsg[$ERROR_LEVEL].level -le $atypmsg[$typmsg].level ) {
      $date=Get-Date -Format "yyyy-mm-dd,H:mm:ss"
      if ($typmsg -eq "") { $typmsg2= ""} else { $typmsg2="${typmsg}"}
      $message="${date},${typmsg2},${msg}"
      if ($typmsg -ne "" ) {
        Write-Output $message | Out-File $ERROR_FILE -Append
      }
      if ($atypmsg[$typmsg].background -eq '') {
        Write-Host $message  -foregroundcolor $atypmsg[$typmsg].color;
      } else {
        Write-Host $message  -foregroundcolor $atypmsg[$typmsg].color -backgroundcolor $atypmsg[$typmsg].background;
      }
    }
 }

##############################################
# function to split the titles columns (different per type)
# input:
#   @line the line read from file
# return:
#   @atitles array of titles
##############################################
function fillTitleInfo ([string] $line)
{
    $atitles= $line.split(",");
    return ,$atitles;
}

##############################################
# function to split input line into variables
# input:
#   @line the line read from file
# return:
#   @info array of data
##############################################
function fillLineInfo ([string] $line) {
    $fields= $line.split(",");
    $todo= $fields[0].toUpper().trim();
    if ($todo.Contains('TITLE') ) {
      #future dynamic fields
      switch ($todo) {
        'TITLE_IP'     {
           $global:aFieldsIP=$fields;  $global:nFieldsIP=ArrayToHash($fields);
        }
        "TITLE_SUBNET" {
           $global:aFieldsSub=$fields; $global:nFieldsSub=arrayToHash($fields);
#$a= stringHash($nFieldsSub);
#$f= stringArray($fields);
#$msg = 'DEBUG:' + ' fields=' + $f + ' nFieldsSub=' + $a;
#sendMessages -typmsg "DEBUGGING" -msg $msg;
        }
        "TITLE_DEVICE" {
           $global:aFieldsDev=$fields; $global:nFieldsDev=ArrayToHash($fields);
        }
        "TITLE_TAG"    {
           $global:aFieldsTag=$fields; $global:nFieldsTag=ArrayToHash($fields);
        }
        "TITLE_SEARCHSUBNET"    {
           $global:aFieldsSearchSub=$fields.ToLower(); $global:nFieldsSearchSub=ArrayToHash($fields);
           $msg = $line.ToLower();
           $msg = $msg.Replace("title_searchsubnet,","");
           $msg = $msg.Replace("id,","");
           $msg = $msg.Replace("name,","");
           $msg = 'id,name,configuration,' + $msg;
           sendMessages -typmsg "NORMAL" -msg $msg -out $global:isoutput;
        }
        default        {
        }
      }
      $info= @{action=$todo;name=$fields[1].trim()};
    } elseif ($todo -eq "CONFIG-NAME" ) {
      $info= @{action=$todo;name=$fields[1].trim()};
    } elseif ($listReadActions -contains $todo) {
      $info = @{};
      for ($i=0; $i -lt $fields.Count;$i++) {
           $info.Add("$i",$fields[$i]);
      }
      $info.Add("action",$fields[0]);
#$a= stringHash($info);
#$msg = 'DEBUG listReadActions :' + ' info=' + $a;
#sendMessages -typmsg "DEBUGGING" -msg $msg;
    } elseif ($todo.Contains("_IP")) {
      #$info= @{action=$todo;name=$fields[1].trim();ip=$fields[2].trim();};
      $info = @{};
      for ($i=0; $i -lt $aFieldsIP.Count;$i++) {
        if ($i -lt $fields.Count) {
           $info.Add($aFieldsIP[$i],$fields[$i]);
        } else {
           $info.Add($aFieldsIP[$i],'');
        }
      }
      $info.Add("action",$fields[0]);
    } elseif ($todo.Contains("_DEVICE")) {
      $info = @{};
      for ($i=0; $i -lt $aFieldsDev.Count;$i++) {
        if ($i -lt $fields.Count) {
           $info.Add($aFieldsDev[$i],$fields[$i]);
        } else {
           $info.Add($aFieldsDev[$i],'');
        }
      }
      $info.Add("action",$fields[0]);
    } elseif ($todo.Contains("_TAG")) {
      $info = @{};
      for ($i=0; $i -lt $aFieldsTag.Count;$i++) {
        if ($i -lt $fields.Count) {
           $info.Add($aFieldsTag[$i],$fields[$i]);
        } else {
           $info.Add($aFieldsTag[$i],'');
        }
      }
      $info.Add("action",$fields[0]);
    } elseif ($todo.Contains("SEARCHSUBNET")) {
      $info = @{};
      for ($i=0; $i -lt $aFieldsSub.Count;$i++) {
        if ($i -lt $fields.Count) {
           $info.Add($aFieldsSub[$i],$fields[$i]);
        } else {
           $info.Add($aFieldsSub[$i],'');
        }
      }
      $info.Add("action",$fields[0]);
    } elseif ($todo.Contains("_SUBNET")) {
      $info = @{};
      for ($i=0; $i -lt $aFieldsSub.Count;$i++) {
        if ($i -lt $fields.Count) {
           $info.Add($aFieldsSub[$i],$fields[$i]);
        } else {
           $info.Add($aFieldsSub[$i],'');
        }
      }
      $info.Add("action",$fields[0]);
#$a= stringHash($info);
#$f= stringArray($fields);
#$msg = 'DEBUG:' + ' fields=' + $f + ' info=' + $a + ' CIDR=' + $info["CIDR"];
#sendMessages -typmsg "DEBUGGING" -msg $msg;
	} else {
      $info= @{action=$todo;name=$fields[1].trim();ip=$fields[2].trim();descr_ip=$fields[3].trim();};
    }
    return ,$info;
}

##############################################
# initialisation of the DB
# input:
#   @name    API user
#   @pass    API password
# return:
#   @wsdlinit
##############################################
function initAPI([string] $name, [string] $pass) {
 $ok=0;
 # initiate
 [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
 $CookieContainer = New-Object System.Net.CookieContainer
 try {
    $wsdlProxy = New-WebServiceProxy -uri $($wsdlPath)
                 #System.Management.Automation.ActionPreference SilentlyContinue | Continue | Inquire | Ignore
    $wsdlProxy.url = $wsdlPath
    $wsdlProxy.CookieContainer = $CookieContainer
    $result= 1;
 } catch {
   $result= 0;
   $msg= "Wrong WSDL URI ${$wsdlPath} !";
   sendMessages -typmsg "ERROR" -msg $msg;
   if ($debugging -ne 'YES') {
     exit;
   } else {
     $msg= "DEBUGGING: Wrong WSDL URI ! Continue for debugging.";
     sendMessages -typmsg "DEBUGGING" -msg $msg;
   }
 }
 try {
   $wsdlProxy.login($name, $pass);
 } catch {
   $result= 0;
 }
 if ($result) {
   $wsdlinit= @{proxy=$wsdlProxy;cfgid=0}
 } else {
     $msg= "Wrong user or password !";
     sendMessages -typmsg "ERROR" -msg $msg;
     $wsdlinit= $null;
     if ($debugging -ne 'YES') { exit; }
     else {
       $msg= "DEBUGGING: Continue for debugging.";
       sendMessages -typmsg "DEBUGGING" -msg $msg;
       $wsdlinit= @{cfgid=0};
     }
  }
 return $wsdlinit;
}

##############################################
# initialisation of the View
# input:
#   @wsdl   WSDL proxyobject
#   @cfgid  ID of configuration
#   @range  found block ornull
#   @data   data to add
# return:
#   @configid 
##############################################
function initConfiguration([ref] $wsdl, [string] $configname) {
   $ok=0;
   # get the ID of configruation
   try {
     $ConfigFound = $wsdl.value["proxy"].getEntityByName("0",$configname,"Configuration");
   } catch {
     if ($debugging -ne 'YES') {
       $msg ="Error on WSDL searching configuration $configname.";
       sendMessages -typmsg "ERROR" -msg $msg
     } else {
       $msg ="DEBUGING step initConfiguration non WSDL answer for $configname. Continuing with config id -1.";
       sendMessages -typmsg "DEBUGGING" -msg $msg;
       $wsdl.value["cfgid"]=-1;
       $wsdl.value["proxy"]='DEBUGGING';
       return -1;
     }
   }
   if (($ConfigFound -ne $null) -and ($ConfigFound.id -ne 0)) {
     $msg ="Configuration $configname found, Configuration ID = "+$ConfigFound.id;
     sendMessages -typmsg "OK" -msg $msg
     $wsdl.value["cfgid"]= $ConfigFound.id;
   } else {
     $ErrorMessage = $_.Exception.Message;
     $msg= "Configuration '"+$configname+"' not found! "+$ErrorMessage;
     sendMessages -typmsg "ERROR" -msg $msg;
     $wsdl.value["cfgid"]= $ConfigFound.id;
   }
   return $ConfigFound.id;
}

##############################################
# read the datas
# input:
#   @varfile    file's content giveng by reference 
# return:
#   @none
##############################################
function readInputs([ref] $varfile) {
  # start reading input
  sendMessages -typmsg "DEBUG" -msg "Begin of import"
  sendMessages -typmsg "DEBUG" -msg "----- reading $INPUT_FILE file with title  ---------"
  $varfile.Value = Get-Content $INPUT_FILE
}

##############################################
# add IP
# input:
#   @wsdl   WSDL proxyobject
#   @cfgid  ID of configuration
#   @range  found block ornull
#   @data   data to add
# return:
#   @none
##############################################
function addIP($wsdl, $cfgid, $range,$data) {
   if ($data["action"].Contains("_FORCE")) {
       $IfExistDelete =1;
   } else {
       $IfExistDelete =0;
   }
   $tmpip = $wsdl.getIP4Address($cfgid, $data["ip"]); 
   if ( $tmpip.id -ne 0 ) {
      if ([string]::IsNullOrEmpty($tmpip.name)) {
        modifyIP -wsdl $wsdl -cfgid $cfgid -range $range -data $data
      } else {
          $msg = "The IP "+$data["ip"]+" exist already! actual object is id="+$tmpip.id+" name="+$tmpip.Name+" properties="+$tmpip.properties;
          sendMessages -typmsg "ERROR" -msg $msg;
      }
   } else {
     $subnetFound = $wsdl.getIPRangedByIP($cfgid, "IP4Network",$data["ip"])
    if (($subnetFound.Type -eq $null) -or ($subnetFound.Id -eq 0) ) {
       $msg = "No subnet found for this IP "+$data["ip"]+" !";
       sendMessages -typmsg "ERROR" -msg $msg;
    } else {
       # assign the IP / "MAKE_DHCP_RESERVED", "MAKE_STATIC", "MAKE_RESERVED" 
       $msg = "Trying to insert IP "+$data["ip"]+" in subnet id="+$subnetFound.id+" subnet name="+$subnetFound.Name+" properties="+$subnetFound.properties;
       sendMessages -typmsg "DEBUG" -msg $msg;
       $mac="";
       $action="MAKE_STATIC";#
       $hostInfo=$data["name"];
       #$properties="address="+$data["ip"]+'|'+"vip_ip4="+$data["vip_ip4"]+'|'+"nat_ip4="+$data["nat_ip4"]+'|'+"ilo_ip4="+$data["ilo_ip4"]+'|'+"is_management="+$data["is_management"]+'|'+"name="+$data["name"]+'|'+"descr_ip="+$data["descr_ip"]+'|';
       $properties = "";
       foreach ($fieldn in $global:aFieldsIP) {              
         $ti = $fieldn.ToLower();
         switch -wildcard ($ti) {
                 "ip"   { }
                 "title*" { }
                 default {
                    if ($data.containsKey($ti)) { $val = $data[$ti]; }
                    else { $val=""; }
                    $properties = $properties+ $fieldn +"="+ $val + '|';
                 }
         }
       }
#$a= stringArray($global:aFieldsIP);
#$f= stringHash($data);
#$msg = 'DEBUG:' + ' aFieldsIP=' + $a + ' data=' + $f + ' properties=' + $properties;
#sendMessages -typmsg "DEBUGGING" -msg $msg;
       $ErrorMessage="";
       try {
             $ipFound = $wsdl.assignIP4Address($cfgid, $data["ip"],$mac,$hostInfo,$action,$properties);
           } catch {
             $ErrorMessage = $_.Exception.Message;
             $ipFound = $null;
           }
           if ( $ipFound -eq $null -or $ipFound -eq 0 ) {
             $msg = "Could not assign the IP "+$data["ip"]+" with properties="+$properties+"! $ErrorMessage";
             sendMessages -typmsg "ERROR" -msg $msg;
           } else {
             $ipCheck = $wsdl.getIP4Address($cfgid, $data["ip"]); 
             #$ipCheck = $wsdl.getEntityByName($cfgid,$ipFound,"IP4Address");
             $msg = "Achieved assignation of the IP "+$data["ip"]+". Saved id="+$ipCheck.id+" name="+$ipCheck.name+" with properties="+$ipCheck.properties;
             sendMessages -typmsg "OK" -msg $msg;
           }
       }
   }
}

##############################################
# modify IP
# input:
#   @wsdl   WSDL proxyobject
#   @cfgid  ID of configuration
#   @range  found block ornull
#   @data   data to add
# return:
#   @none
##############################################
function modifyIP($wsdl, $cfgid, $range,$data) {
   $error=0;
   $tmpip = $wsdl.getIP4Address($cfgid, $data["ip"]);
   if ( $tmpip -eq $null ) {
          $msg = "The IP "+$data['ip']+" doesn`'t exist! No changes are possible";
          sendMessages -typmsg "ERROR" -msg $msg;
   } else {
     $subnetFound = $wsdl.getIPRangedByIP($cfgid, "IP4Network",$data["ip"])
     if (($subnetFound.Type -eq $null) -or ($subnetFound.Id -eq 0) ) {
            $msg = "No subnet found for this IP "+$data["ip"]+" !";
            sendMessages -typmsg "ERROR" -msg $msg;
     } else {
       # modify the IP
       $msg = "Trying to modify IP id="+$tmpip.id+" name="+$tmpip.name+" properties="+$tmpip.properties+" in subnet id="+$subnetFound.id+" subnet name="+$subnetFound.Name;
       sendMessages -typmsg "DEBUG" -msg $msg;
       $mac="";
       $action="MAKE_STATIC";
       $hostInfo=$data["name"];
       $propertiesnb = 0;
       if (($data["name"] -ne "") -and ($data["name"] -ne $tmpip.name)) {
          $properties=1;
          $tmpip.name=$data["name"];
       }
       $properties = "";
       foreach ($fieldn in $global:aFieldsIP) {
         $ti = $fieldn.ToLower();
         switch -wildcard ($ti) {
           "ip"   { }
           "title*" { }
           default {
             if ($data.containsKey($ti)) { $new = $data[$ti]; }
             else { $new=""; }
             #$properties = $properties+ $fieldn +"="+ $val + '|';
             if ($new -ne "") {
               $tmpprop= $subnetFound.properties;
               if (!$tmpprop.Contains($fieldn + '='+$new+'|')) {
                 $propertiesnb=1;
                 if ( $tmpprop.contains($fieldn+"=")) {
                    $a= $fieldn + "="+$new;
                    $deb=$tmpprop.IndexOf($fieldn+"=");
                    $lg=$tmpprop.IndexOf('|',$deb)-$deb; 
                    $b=$tmpprop.Substring($deb,$lg);
                    $tmpprop = $tmpprop.replace($b,$a);
                    $subnetFound.properties= $tmpprop;
                } else {
                 $tmpprop = $tmpprop + $fieldn + '='+$new+'|';
                 $subnetFound.properties= $tmpprop;
                }
              }
             }
           }
         }
       }
       if ($propertiesnb -eq 0) {
           $msg = "No properties changes for id="+$tmpip.id+" name="+$tmpip.name+" because empty changes or same value. properties="+$tmpip.properties;
           sendMessages -typmsg "OK" -msg $msg;
            $error=1;
       } else {
         try {
           $wsdl.update($tmpip);
           # $tmpip2 = $wsdl.getIP4Address($cfgid, $tmpip.id); 
           $tmpip2= $wsdl.getEntityById($tmpip.id);
           $msg="Verifying IP changes ID="+$tmpip2.id+" name="+$tmpip2.name+" properties="+$tmpip2.properties;
           sendMessages -typmsg "DEBUG" -msg $msg;
         } catch {
           $ErrorMessage = $_.Exception.Message;
           $msg= "Update not possible! id="+$tmpip.id+" name="+$tmpip.name+" properties="+$tmpip.properties+" err_msg="+$ErrorMessage;
           sendMessages -typmsg "ERROR" -msg $msg;
           $error=1;
         }
       }
       if ($error -eq 0) {
         $msg= "Update of IP="+$tmpip2.name+" done with properties="+$tmpip2.properties+".";
         sendMessages -typmsg "OK" -msg $msg;
       }
     }
   }
}

##############################################
# find a Block
# input:
#   @name    API user
#   @pass    API password
# return:
#   @none
##############################################
function findBlock($wsdl, [int] $cfgid, [string] $CIDR) {
 $range = $null;
 # initiate
 try {
   #$rangeFound = $wsdlProxy.getIPRangedByIP($cfgid, "IP4Block",$CIDR);
   $range = $wsdl.getEntityByCIDR($cfgid,$CIDR, "IP4Block");
   $found= @{value=$range;error=$msg};
   if ($range -eq 0) { 
     $msg="No block not found for "+$CIDR+"!";
     $found= @{value=$null;error=$msg};
   }
 } catch {
   $msg= "Error by searching block "+$CIDR+"! err_msg="+$_.Exception.Message;
   $found= @{value=$null;error=$msg};
 }
 return $found;
}

##############################################
# add Subnet
# input:
#   @wsdl   WSDL proxyobject
#   @cfgid  ID of configuration
#   @range  found block ornull
#   @data   data to add
# return:
#   @none
##############################################
function addSubnet($wsdl, $cfgid, $range,$data) {
   try {
     $subnetFound = $wsdl.getEntityByCIDR($range.id,$data["CIDR"],"IP4Network");
     $msgerror= "";
   } catch {
     $msgerror= $_.Exception.Message;
   }
   if ($subnetFound.id -ne 0 ) {
          $msg = "The Subnet "+$data["CIDR"]+" exist already! Cannot add it. Actual object is id="+$subnetFound.id+" name="+$subnetFound.Name+" properties="+$subnetFound.properties+" error="+$msgerror;
          sendMessages -typmsg "ERROR" -msg $msg;
   } else {
     if ($range -ne $null) {
         # check properties
#         $listOfSubnetsFields= $wsdl.getUserDefinedFields("IPv4AddressRange",0);
#         $fieldsname="type";
#         $index = ($listOfSubnetsFields.name.indexof($fieldsname));
#         if (($index -gt -1)  -and ($listOfSubnetsFields.predefinedValues[$index] -ne $null)) {
#           $aValues = $listOfSubnetsFields.predefinedValues[$index].split('|');
#           if (-not $aValues.contains($data[$fieldsname])) {
#             $errmsgno=$ERRSUBADDPRO1;
#             $msg = "Wrong type's value ("+$fieldsname+") of device. "+$data[$fieldsname]+" doesn't exist for device "+$data["name"]+" ! Cannot add it."+"Allowed are :"+$aValues;
#             sendMessages -typmsg "ERROR" -msg $msg;           
#           }
#         } else{
#           $errmsgno=$ERRSUBADDPRO2;
#           $msg = "Wrong property's name "+$fieldsname+" of device. "+$fieldsname+" doesn't exist for any device! Cannot add it.";
#           sendMessages -typmsg "ERROR" -msg $msg;           
#         }
#         $fieldsname="location";
#         $index = ($listOfSubnetsFields.name.indexof($fieldsname));
#         if (($index -gt -1)  -and ($listOfSubnetsFields.predefinedValues[$index] -ne $null)) {
#           $aValues = $listOfSubnetsFields.predefinedValues[$index].split('|');
#           if (-not $aValues.contains($data[$fieldsname])) {
#           $errmsgno=$ERRSUBADDPRO4;
#             $msg = "Wrong type's value ("+$fieldsname+") of device. "+$data[$fieldsname]+" doesn't exist for device "+$data["name"]+" ! Cannot add it."+"Allowed are :"+$aValues;
#             sendMessages -typmsg "ERROR" -msg $msg;
#           }
#         } else{
#           $errmsgno=$ERRSUBADDPRO5;
#           $msg = "Wrong property's name "+$fieldsname+" of device. "+$fieldsname+" doesn't exist for any device! Cannot add it.";
#           sendMessages -typmsg "ERROR" -msg $msg;           
#         }
         if ( $errmsgno-eq 0 ) {
            $properties = "";
            $listexcludedfields= 'name,cidr,title';
            foreach ($fieldn in $global:aFieldsSub) {              
              $ti = $fieldn.ToLower();
              if  ( -not ($listexcludedfields.Contains($ti) -or $ti.Contains('title')) ) {
                #properties fields
                if ($data.containsKey($ti)) { $val = $data[$ti]; }
                else { $val=""; }
                $properties = $properties+ $fieldn +"="+ $val + '|';
              }
            }
            $msg = "Trying to insert Subnet "+$data["CIDR"]+" properties="+$properties+" in the Block id="+$range.id;
            sendMessages -typmsg "DEBUG" -msg $msg;
            $ErrorMessage="";
            try {
             $subnet = $wsdl.addIP4Network($range.id, $data["CIDR"],$properties);
            } catch {
             $ErrorMessage = $_.Exception.Message;
             $subnet = $null;
            }
            if ( $subnet-eq $null -or $subnet.id -eq 0 ) {
              $msg = "Could not assign the subnet "+$data["CIDR"]+" with properties="+$properties+" in the Block id="+$range.id+"! $ErrorMessage";
              sendMessages -typmsg "ERROR" -msg $msg;
            } else {
              $subnetCheck = $wsdl.getEntityByCIDR($range.id,$data["CIDR"],"IP4Network");
              $msg = "Achieved assignation of the subnet "+$data["CIDR"]+". Saved id="+$subnetCheck.id+" name="+$subnetCheck.name+" with properties="+$subnetCheck.properties;
              sendMessages -typmsg "OK" -msg $msg;
            }
         }
       }
     }
}

##############################################
# modify Subnet
# input:
#   @wsdl   WSDL proxyobject
#   @cfgid  ID of configuration
#   @range  found block ornull
#   @data   data to add
# return:
#   @none
##############################################
function modifySubnet($wsdl, $cfgid, $range,$data) {
   $error=0;
   try {
     $subnetFound = $wsdl.getEntityByCIDR($range.id,$data["CIDR"],"IP4Network");
     $msgerror= "";
   } catch {
     $msgerror= $_.Exception.Message;
   }
   if ($subnetFound.id -eq 0 ) {
          $msg = "The Subnet "+$data["CIDR"]+' does not exist ! Cannot modify it. Actual object is id='+$subnetFound.id+" name="+$subnetFound.Name+" properties="+$subnetFound.properties+" error="+$msgerror;
          sendMessages -typmsg "ERROR" -msg $msg;
   } else {
     if ($range -ne $null) {
       $propertiesnb = 0;
       if (($data["name"] -ne "") -and ($data["name"] -ne $tmpip.name)) {
          $propertiesnb=1;
          $subnetFound.name=$data["name"];
       }
       $properties = "";
       foreach ($fieldn in $global:aFieldsSub) {              
         $ti = $fieldn.ToLower();
         switch -wildcard ($ti) {
           "name"   { }
           "CIDR"   { }
           "title*" { }
           default {
             if ($data.containsKey($ti)) { $new = $data[$ti]; }
             else { $new=""; }
             #$properties = $properties+ $fieldn +"="+ $val + '|';
             if ($new -ne "") {
               $tmpprop= $subnetFound.properties;
               if (!$tmpprop.Contains($fieldn + '='+$new+'|')) {
                 $propertiesnb=1;
                 if ( $tmpprop.contains($fieldn+"=")) {
                    $a= $fieldn + "="+$new;
                    $deb=$tmpprop.IndexOf($fieldn+"=");
                    $lg=$tmpprop.IndexOf('|',$deb)-$deb; 
                    $b=$tmpprop.Substring($deb,$lg);
                    $tmpprop = $tmpprop.replace($b,$a);
                    $subnetFound.properties= $tmpprop;
                } else {
                 $tmpprop = $tmpprop + $fieldn + '='+ $new + '|';
                 $subnetFound.properties= $tmpprop;
                }
              }
             }
           }
         }
       }
       if ($propertiesnb -eq 0) {
           $msg = "No properties changes for id="+$subnetFound.id+" name="+$subnetFound.name+" because empty changes or same value. properties="+$subnetFound.properties;
           sendMessages -typmsg "OK" -msg $msg;
           $error=1;
       } else {
         try {
           $wsdl.update($subnetFound);
           $subnetFound2= $wsdl.getEntityById($subnetFound.id);
           $msg="Verifying SUBNET changes ID="+$subnetFound2.id+" name="+$subnetFound2.name+" properties="+$subnetFound2.properties;
           sendMessages -typmsg "DEBUG" -msg $msg;
         } catch {
           $ErrorMessage = $_.Exception.Message;
           $msg= "Update not possible! id="+$subnetFound.id+" name="+$subnetFound.name+" properties="+$subnetFound.properties+" err_msg="+$ErrorMessage;
           sendMessages -typmsg "ERROR" -msg $msg;
           $error=1;
         }
       }
       if ($error -eq 0) {
         $msg= "Update of IP="+$subnetFound2.name+" done with properties="+$subnetFound2.properties+".";
         sendMessages -typmsg "OK" -msg $msg;
       }
     }
   }
}

##############################################
# check user defined fields
# input:
#   @wsdl   WSDL proxyobject
#   @objectType   type of object to test
#   @fieldsname   field's name to check
# return:
#   @errmsgno error number. 0 for no error
##############################################
function checkUserDefinedFields ($wsdl, $objectType, $fieldsname) {
  $errno = 0; 
  $listOfDevicesFields= $wsdl.getUserDefinedFields($objectType,0);
  if ($listOfDevicesFields.count -eq 0) {
    if ($fieldlsname -eq '') {
      $errno=$ERRDEVPRO2;
      $msg = "Wrong property's name "+$fieldsname+" of device. "+$fieldsname+" doesn't exist for any device! Cannot add it.";
      sendMessages -typmsg "WARNING" -msg $msg;           
    }
  } else {
    $index = ($listOfDevicesFields.name.indexof($fieldsname));
    if ($index -le -1)  {
      $aValues = $listOfDevicesFields.name[$index];
      $errno=$ERRDEVPRO1;
      $msg = "Wrong fields value "+$fieldsname+' ! Cannot add it.';
      sendMessages -typmsg "WARNING" -msg $msg;           
     }
  }
  return $errno;
}

##############################################
# add Device
# input:
#   @wsdl   WSDL proxyobject
#   @cfgid  ID of configuration
#   @data   data to add
# return:
#   @none
##############################################
function addDevice($wsdl, $cfgid,$data,$fields) {
   $noterror=1;
   $errmsgno=0;
   if ($data["action"].Contains("_FORCE")) {
       $IfExistDelete =1;
   } else {
       $IfExistDelete =0;
   }
   try {
     $deviceTypeFound = $wsdl.getEntityByName(0,$data["DeviceType"],"DeviceType");
     $msgerror= "";
   } catch {
     $deviceTypeFound=$null;
     $msgerror= $_.Exception.Message;
   }
   if (($deviceTypeFound -eq $null) -or ($deviceTypeFound.id -eq 0) ) {
      $errmsgno=$ERRDEVTYP1;
      $msg = "The device's type '"+$data["DeviceType"]+"' does`'nt exist ! Cannot add objet "+$data["name"]+". error="+$msgerror;
      sendMessages -typmsg "ERROR" -msg $msg;
   }
   $subtypid=0;
   if ($data["DeviceSubtype"] -ne "") {
       $deviceSubtypeFound = $wsdl.getEntityByName($deviceTypeFound.id,$data["DeviceSubtype"],"DeviceSubtype");
       if (($deviceSubTypeFound -eq $null) -or ($deviceSubTypeFound.id -eq 0 )) {
         $errmsgno=$ERRDEVTYP2;
         $msg = "The device's subtype '"+$data["DeviceSubtype"]+"' does not exist ! Cannot add objet "+$data["name"]+". error="+$msgerror;
         sendMessages -typmsg "ERROR" -msg $msg
       }
       $subtypid=$deviceSubTypeFound.id;
   }
   if ($errmsgno -eq 0) {
     $deviceFound = $wsdl.getEntityByName($cfgid,$data["name"],"Device");
     $msgerror= "";
     if ((($deviceFound -ne $null ) -and ($deviceFound.id -ne 0 )) -and ( -not $IfExistDelete )) {
          $errmsgno=$ERRDEV1;
          $msg = "The device "+$data["name"]+" exist already! Cannot add it. Actual object is id="+$deviceFound.id+" name="+$deviceFound.Name+" devicetype="+$deviceFound.devicetype+" properties="+$deviceFound.properties+" error="+$msgerror;
          sendMessages -typmsg "ERROR" -msg $msg;
     } else {
	   if ( ($errmsgno -eq 0) -and ($deviceFound.id -ne 0 ) -and ( $IfExistDelete -eq 1)) {
           try {
			 $resultDelete = $wsdl.delete($deviceFound.id);
             $msg = "Device already exists. Option FORCE. Removing first of device id="+$deviceFound.id+" name="+$deviceFound.Name+" properties="+$deviceFound.properties;
             sendMessages -typmsg "INFO" -msg $msg;
           } catch {
             $errmsgno=$ERRDEVPRO7;
             $msgerror= $_.Exception.Message;
             $msg = "Error by deleting of the device id="+$deviceFound.id+" name="+$deviceFound.Name+" properties="+$deviceFound.properties+" error="+$msgerror;
             sendMessages -typmsg "ERROR" -msg $msg;
           }
       }
       if ( $errmsgno-eq 0 ) {
            if ($data["ip4Addresses"] -ne $null) { $theIPs = $data["ip4Addresses"].replace(';',',').replace(' ',''); }
            else { $theIPs = '';}
            $properties = "";
            $listexcludedfields= 'name,devicetype,devicesubtype,ip4addresses,title';
            foreach ($fieldn in $global:aFieldsDev) {              
              $ti = $fieldn.ToLower();
              if  ( -not ($listexcludedfields.Contains($ti) -or $ti.Contains('title')) ) {
                # check properties
                $errmsgno = checkUserDefinedFields -wsdl $wsdl -objectType 'Device' -fieldsname $fieldn;
                #properties fields
                if ($data.containsKey($ti)) {
                  $val = $data[$ti];
                }
                else { $val=""; }
                $properties = $properties+ $fieldn +"="+ $val + '|';
              }
            }
            $msg = "Adding Device "+$data["name"]+" type="+$data["DeviceType"]+" subtype="+$data["DeviceSubtype"]+" ip="+$theIPs+" with properties="+$properties;
            sendMessages -typmsg "INFO" -msg $msg;
            $ErrorMessage="";
            try {
              $deviceAdded = $wsdl.addDevice($cfgid,$data["name"],$deviceTypeFound.id,$subtypid,$theIPs,"",$properties)
            } catch {
              $ErrorMessage = $_.Exception.Message;
              $deviceAdded = $null;
            }
            if ( $deviceAdded -eq $null -or $deviceAdded.id -eq 0 ) {
              $errmsgno=$ERRDEVPRO8;
              $msg = "Could not assign the device "+$data["name"]+" type="+$data["DeviceType"]+" with properties="+$properties+"! $ErrorMessage";
              sendMessages -typmsg "ERROR" -msg $msg;
            } else {
              $msg = "Added device "+$data["name"]+" type="+$data["DeviceType"]+" subtype="+$data["DeviceSubtype"]+" ip="+$theIPs+" with properties="+$properties;
              sendMessages -typmsg "OK" -msg $msg;
           }
     }
    }
   }
}

##############################################
# delete Device
# input:
#   @wsdl   WSDL proxyobject
#   @cfgid  ID of configuration
#   @data   data to add
# return:
#   @none
##############################################
function deleteDevice($wsdl, $cfgid,$data,$fields) {
   $noterror=1;
   $errmsgno=0;
   if ($errmsgno -eq 0) {
       $subtypid=$deviceSubTypeFound.id;
       $deviceFound = $wsdl.getEntityByName($cfgid,$data["name"],"Device");
       $msgerror= "";
       if (($deviceFound -eq $null ) -or ($deviceFound.id -eq 0 ))  {
          $errmsgno=$ERRDEV1;
          $msg = 'The device '+$data["name"]+' does not exist already! '+' error='+$msgerror;
          sendMessages -typmsg "ERROR" -msg $msg;
       } else {
         # extract IPs
         $tmpprop=$deviceFound.properties;
         $ip4Addresses="";
         if ( $tmpprop.contains("ip4Addresses=")) {
              $a="ip4Addresses="+$new;
              $deb=$tmpprop.IndexOf("ip4Addresses=");
              $lg=$tmpprop.IndexOf('|',$deb)-$deb; 
              $b=$tmpprop.Substring($deb,$lg);
              $ip4Addresses = $b;
         }
         $aValues = $tmpprop.split(",");
         foreach ($ip in $aValues) {
         }
         $msg = "Searching IPs of device ="+$data["name"]+" IPs="+$ip4Addresses;
         sendMessages -typmsg "INFO" -msg $msg;
         try {
			 $resultDelete = $wsdl.delete($deviceFound.id);
             $msg = "Searching devices, device id="+$deviceFound.id+" name="+$deviceFound.Name+" properties="+$deviceFound.properties;
             sendMessages -typmsg "OK" -msg $msg;
         } catch {
             $errmsgno=$ERRDEVPRO7;
             $msgerror= $_.Exception.Message;
             $msg = "Error by deleting of the device id="+$deviceFound.id+" name="+$deviceFound.Name+" properties="+$deviceFound.properties+" error="+$msgerror;
             sendMessages -typmsg "ERROR" -msg $msg;
         }
         if ( $errmsgno -ne 0 ) {
              $errmsgno=$ERRDEVPRO10;
              $msg = "Could not remove the device or these IPs"+$data["name"]+" type="+$data["DeviceType"]+" with properties="+$properties+"! $ErrorMessage";
              sendMessages -typmsg "ERROR" -msg $msg;
         } else {
              $msg = "Removed device "+$deviceFound.Name+" type="+$deviceFound.deviceType+" id="+$deviceFound.id+" properties="+$deviceFound.properties;
              sendMessages -typmsg "OK" -msg $msg;
         }
      }
   }
}

##############################################
# modify Device
# input:
#   @wsdl   WSDL proxyobject
#   @cfgid  ID of configuration
#   @data   data to add
# return:
#   @none
##############################################
function modifyDevice($wsdl, $cfgid,$data,$fields) {
   $noterror=1;
   $errmsgno=0;
   try {
     $deviceFound = $wsdl.getEntityByName($cfgid,$data["name"],"Device");
     $msgerror= "";
   } catch {
     $deviceFound=$null;
     $msgerror= $_.Exception.Message;
   }
   if (($deviceFound -eq $null) -or ($deviceFound.id -eq 0) ) {
      $errmsgno=$ERRDEV1;
      $msg = 'The device '+$data["name"]+' does not exist! '+' error='+$msgerror;
      sendMessages -typmsg "ERROR" -msg $msg;
   }
   if ($errmsgno -eq 0) {
     $msg="Device found ID="+$deviceFound.id+" name="+$deviceFound.name+" properties="+$deviceFound.properties;
     sendMessages -typmsg "DEBUG" -msg $msg;
     $propertiesnb = 0;
     $msgerror= "";
     $properties = "";
     $listexcludedfields= 'name,devicesubtype,title';
     foreach ($fieldn in $global:aFieldsDev) {              
        $ti = $fieldn.ToLower();
        $new ="";
        if  ( -not ($listexcludedfields.Contains($ti) -or $ti.Contains('title')) ) {
           #properties fields
           if (($data.containsKey($ti)) -and ($data[$ti] -ne '')) {
             if ($ti -eq 'devicetype') {
               $fieldn='deviceTypeId';
               try {
                 $deviceTypFound = $wsdl.getEntityByName(0,$data[$ti],"DeviceType");
               } catch {
                 $deviceTypFound=$null;
                 $msgerror= $_.Exception.Message;
               }
               if (($deviceTypFound -eq $null) -or ($deviceTypFound.id -eq 0) ) {
                   $errmsgno=$ERRDEVTYP1;
               } else {
                 $new  = $deviceTypFound.id;
               }
             } else {
               $new  = $data[$ti];
             }
           }
        }
        if (($new -ne "") -and ($errmsgno -eq 0)) {
           $tmpprop= $deviceFound.properties;
           if (!$tmpprop.Contains($fieldn + '='+$new+'|')) {
              $propertiesnb=1;
              if ( $tmpprop.contains($fieldn+"=")) {
                    $a= $fieldn + "="+$new;
                    $deb=$tmpprop.IndexOf($fieldn+"=");
                    $lg=$tmpprop.IndexOf('|',$deb)-$deb; 
                    $b=$tmpprop.Substring($deb,$lg);
                    if ($fieldn -eq 'ip4Addresses') {
                      if ($new.contains('+') -or $new.contains('-') )  {
                        $newlist = $new.split(';');
                        foreach ($nip in $newlist) {
                          if ($nip.contains('-')) {
                             $ip= $nip.replace('-','');
                             $newb= $b.replace($ip+',','').replace(','+$ip,'').replace($ip,'');
                             $tmpprop = $tmpprop.replace($b,$newb);
                          } else {
                             $ip= $nip.replace('+','');
                             if ($b -eq 'ip4Addresses=') {
                               $newb= $b.replace('=','='+$ip);
                             } else {
                               $b2=$b+',';
                               if (-not $b2.contains($ip+',') ) {
                                 $newb= $b +','+$ip;
                               }
                             }
                             $tmpprop = $tmpprop.replace($b,$newb);
                             $b = $newb;
                          }
                        }
                      } else {
                        $theIPs = $a.replace(';',',').replace(' ','');
                        $tmpprop = $tmpprop.replace($b,$theIPs);
                      }
                    } else {
                      $tmpprop = $tmpprop.replace($b,$a);
                    }
                    $deviceFound.properties= $tmpprop;
               } else {
                 $tmpprop = $tmpprop + $fieldn + '='+ $new + '|';
                 $deviceFound.properties= $tmpprop;
               }
           }
        }
     }
     if ($propertiesnb -eq 0) {
           $msg = "No properties changes for id="+$deviceFound.id+" name="+$deviceFound.name+" because empty changes or same value. properties="+$deviceFound.properties;
           sendMessages -typmsg "OK" -msg $msg;
           $noterror=0;
     } else {
         try {
           $wsdl.update($deviceFound);
           $deviceFound2= $wsdl.getEntityById($deviceFound.id);
           $msg="Verifying device changes ID="+$deviceFound2.id+" name="+$deviceFound2.name+" properties="+$deviceFound2.properties+' ID='+$deviceFound.id+' OLD name='+$deviceFound.name+' OLD properties='+$deviceFound.properties;
           sendMessages -typmsg "DEBUG" -msg $msg;
         } catch {
           $ErrorMessage = $_.Exception.Message;
           $msg= "Update not possible! id="+$deviceFound.id+" name="+$deviceFound.name+" properties="+$deviceFound.properties+" err_msg="+$ErrorMessage;
           sendMessages -typmsg "ERROR" -msg $msg;
           $noterror=0;
         }
     }
     if ($noterror -eq 1) {
         $msg= "Update of device="+$deviceFound2.name+" done with properties="+$deviceFound2.properties+".";
         sendMessages -typmsg "OK" -msg $msg;
     }
   }
}

##############################################
# add Tags
# input:
#   @wsdl   WSDL proxyobject
#   @cfgid  ID of configuration
#   @range  found block ornull
#   @data   data to add
# return:
#   @none
##############################################
function addTags($wsdl, $cfgid, $data, $fields) {
   $errmsgno=0;
   $TaggroupFoundId = 0;
   try {
     $taggroupFound = $wsdl.getEntityByName(0,$data["taggroup"],"TagGroup");
     $TaggroupFoundId= $TaggroupFound.id;
     $msgerror= "";
   } catch {
     $errmsgno=$ERRTAG1;
     $msgerror= $_.Exception.Message;
   }
   if (($errmsgno -eq 0) -and ($taggroupFound -ne $null) -and ($taggroupFoundId -ne 0) -and ($data["taggroup"] -eq $taggroupFound.name) ) {
      $msg='Tag group '+$data['taggroup']+' exists (id='+$taggroupFound.id+')';
      sendMessages -typmsg "DEBUG" -msg $msg;
      $properties = ""
	  if ($data["description"] -ne "") {
         $properties = $properties+ "description" + "=" + $data["description"]+'|';
      } else {
         $properties = $properties+ "description" + "=" + "VLAN" + $data["name"] +'|';
      }
	  if ($data["descr_tag"] -ne "") {
         $properties = $properties+ "descr_tag" + "=" + $data["descr_tag"]+'|';
      } else {
         $properties = $properties+ "descr_tag" + "=" + "VLAN" + $data["name"] +'|';
      }
      $TagFound = $wsdl.getEntityByName($TaggroupFoundId,$data["name"],"Tag")
      if ( $data["name"] -eq $TagFound.name ) {
        $msg= "Tag " + $data["name"] + " exists (id=" +$TagFound.id + "). Not needed to create it.";
        if ($msgerror -ne "") {
           $msg= $msg + ' ('+$msgerror+')';
        }
        sendMessages -typmsg "DEBUG" -msg $msg;
      } else {
        $msg = "Needed creation of tag "+$data["name"]+" in the group "+$data["taggroup"]+" with properties=$properties";
		sendMessages -typmsg "DEBUG" -msg $msg
        try {
            $TagFoundId = $wsdl.addTag($taggroupFoundId,$data["name"],$properties)
        } catch {
            $msgerror = $_.Exception.Message;
            $errmsgno=$ERRTAG2;
            $msg="Cannot create a new tag "+$data["name"]+". error="+$msgerror;
            sendMessages -typmsg "ERROR" -msg $msg;
        }
        if ($errmsgno -eq 0) {
           $msg = "Creation of tag done. TAG="+$TagFound.name+" in the group "+$data["taggroup"]+" with properties=$properties";
		   sendMessages -typmsg "OK" -msg $msg
           $TagFound = $wsdl.getEntityByID($TagFoundId)
        }
      }
      if ($errmsgno -eq 0) {
        # link the object
        if ($data["parentobject"] -ne "") {
          $msg ="Begin of tagging the object "+$data["parentobject"]+" to "+$data["name"];
	      sendMessages -typmsg "INFO" -msg $msg
          #search object in the Blocks and networks
          $Allblocks = $wsdl.getEntities($cfgid,"IP4Block",0,1000)
          $Thenet=$null
          foreach ($Block in $Allblocks) {
            if ( $Block.id -ne 0) {
                $net=$wsdl.getEntityByCIDR($Block.id,$data["parentobject"],"IP4Network");
                if ($net.id -ne 0) {
                  $Thenet=$net;
                  break;
                }
            }
          }
	      if ( $Thenet -ne $null ) {
           #object found ... possible to link
           $ltags = $wsdl.getlinkedEntities($Thenet.id,"Tag",0,1000);
           if ($ltags.id -contains $TagFound.id) {
                $msg ="The object "+$Thenet.name+' ('+$Thenet.id+') [searched='+$data['parentobject']+'] has already '+$TagFound.name+' ('+$TagFound.id+') [searched '+$data["name"]+'] as TAG.'
                sendMessages -typmsg "INFO" -msg $msg
           } else {
                try {
                   $wsdl.linkEntities($TagFound.id,$Thenet.id,"")
                } catch {
                   $msgerror = $_.Exception.Message;
                   $errmsgno=$ERRTAG3;
                   $msg="Cannot link "+$data["parentobject"]+" to the TAG "+$data["name"]+". error="+$msgerror;
                   sendMessages -typmsg "ERROR" -msg $msg;
                }
  	            if ( $errmsgno -eq 0 ) {
                   $msg = "Tagging the object "+ $Thenet.name+" with tag "+$data["name"]+" done."
                   sendMessages -typmsg "OK" -msg $msg
                }
            }
          } else {
            #impossible to link if not exist
            $msg = "Cannot find the object="+$data["parentobject"]+" for the tag "+$data["name"]+". Nothing will be linked.";
            sendMessages -typmsg "ERROR" -msg $msg
          }
        }
      }
   } else {
      $errmsgno=$ERRTAG1;
      $msg='Tag group '+$data["taggroup"]+' does not exist. Cannot add objet '+$data["name"]+'. error='+$msgerror;
      sendMessages -typmsg "ERROR" -msg $msg;
   }
}


##############################################
# modify Tag
# input:
#   @wsdl   WSDL proxyobject
#   @cfgid  ID of configuration
#   @range  found block ornull
#   @data   data to add
# return:
#   @none
##############################################
function modifyTags($wsdl, $cfgid, $range,$data,$fields) {
   $errmsgno=0;
   $TaggroupFoundId = 0;
   try {
     $taggroupFound = $wsdl.getEntityByName(0,$data["taggroup"],"TagGroup");
     $TaggroupFoundId= $TaggroupFound.id;
     $msgerror= "";
   } catch {
     $errmsgno=$ERRTAG1;
     $msgerror= $_.Exception.Message;
   }
   if (($errmsgno -eq 0) -and ($taggroupFound -ne $null) -and ($taggroupFoundId -ne 0) -and ($data["taggroup"] -eq $taggroupFound.name) ) {
      $msg="Tag group "+$data["taggroup"]+" exists (id="+$taggroupFound.id+")";
      sendMessages -typmsg "DEBUG" -msg $msg;
      $properties = 0
      $TagFound = $wsdl.getEntityByName($TaggroupFoundId,$data["name"],"Tag")
      if ( $data["name"] -ne $TagFound.name ) {
        $ErrorMessage = $_.Exception.Message;
        $msg= 'Tag ' + $data["name"] + ' does not exist! Create it before.';
        if ($ErrorMessage -ne "") {
           $msg= $msg + " ("+$ErrorMessage+")";
        }
        sendMessages -typmsg "DEBUG" -msg $msg;
      } else {
        # change porperties
        $properties=0;
        if ($data["descr_tag"] -ne "") {
          $tmpprop= $TagFound.properties;
          $new=$data["descr_tag"]; if ($data["descr_tag"] -eq "''") { $new="";}
          if (!$tmpprop.contains("descr_tag="+$new+'|') ) {
             $properties=1;
             if ( $tmpprop.contains("descr_tag=")) {
              $a="descr_tag="+$new;
              $deb=$tmpprop.IndexOf("descr_tag=");
              $lg=$tmpprop.IndexOf('|',$deb)-$deb; 
              $b=$tmpprop.Substring($deb,$lg);
              $tmpprop = $tmpprop.replace($b,$a);
              $TagFound.properties= $tmpprop;
             } else {
                 $tmpprop = $tmpprop + "descr_tag="+$new+'|';
                 $TagFound.properties= $tmpprop;
             }
          }
        }
        if ($data["description"] -ne "") {
          $tmpprop= $TagFound.properties;
          $new=$data["description"]; if ($data["description"] -eq "''") { $new="";}
          if (!$tmpprop.contains("description="+$new+'|')) {
             $properties=1;
             if ( $tmpprop.contains("description=")) {
              $a="description="+$new;
              $deb=$tmpprop.IndexOf("description=");
              $lg=$tmpprop.IndexOf('|',$deb)-$deb; 
              $b=$tmpprop.Substring($deb,$lg);
              $tmpprop = $tmpprop.replace($b,$a);
              $TagFound.properties= $tmpprop;
             } else {
                 $tmpprop = $tmpprop + "description="+$new+'|';
                 $TagFound.properties= $tmpprop;
             }
          }
        }
        #begin to modify
        $errmsgno=0;
        if ($properties -eq 0) {
           $msg = "No properties to change for id="+$TagFound.id+" name="+$TagFound.name+" because empty changes or same value. properties="+$TagFound.properties;
           sendMessages -typmsg "DEBUG" -msg $msg;
           if ($data["parentobject"] -eq "") {
              $errmsgno=1;
           }
        } else {
        try {
           $wsdl.update($TagFound);
           $TagFound2= $wsdl.getEntityById($TagFound.id);
           $msg="Verifying tag`'s changes ID="+$TagFound2.id+" name="+$TagFound2.name+" properties="+$TagFound2.properties;
           sendMessages -typmsg "DEBUG" -msg $msg;
         } catch {
           $ErrorMessage = $_.Exception.Message;
           $msg= "Update not possible! id="+$TagFound.id+" name="+$TagFound.name+" properties="+$TagFound.properties+" err_msg="+$TagFound;
           sendMessages -typmsg "ERROR" -msg $msg;
           $errmsgno=1;
         }
       }
       if ($errmsgno -eq 0) {
         $msg= "Update of TAG="+$TagFound2.name+" done with properties="+$TagFound2.properties+".";
         sendMessages -typmsg "OK" -msg $msg;
       }
       #begin to link
       if ($errmsgno -eq 0) {
        # link the object
        if ($data["parentobject"] -ne "") {
          $msg ="Begin of tagging the object "+$data["parentobject"]+" to "+$data["name"];
	      sendMessages -typmsg "INFO" -msg $msg
          #search object in the Blocks and networks
          $Allblocks = $wsdl.getEntities($cfgid,"IP4Block",0,1000)
          $Thenet=$null
          foreach ($Block in $Allblocks) {
            if ( $Block.id -ne 0) {
                $net=$wsdl.getEntityByCIDR($Block.id,$data["parentobject"],"IP4Network");
                if ($net.id -ne 0) {
                  $Thenet=$net;
                  break;
                }
            }
          }
	      if ( $Thenet -ne $null ) {
           #object found ... possible to link
           $ltags = $wsdl.getlinkedEntities($Thenet.id,"Tag",0,1000);
           if ($ltags.id -contains $TagFound.id) {
                $msg ="The object "+$Thenet.name+" ("+$Thenet.id+") [searched="+$data["parentobject"]+"] has already "+$TagFound.name+" ("+$TagFound.id+") [searched "+$data["name"]+"] as TAG."
                sendMessages -typmsg "INFO" -msg $msg
           } else {
                try {
                   $wsdl.linkEntities($TagFound.id,$Thenet.id,"")
                } catch {
                   $msgerror = $_.Exception.Message;
                   $errmsgno=$ERRTAG3;
                   $msg="Cannot link "+$data["parentobject"]+" to the TAG "+$data["name"]+". error="+$msgerror;
                   sendMessages -typmsg "ERROR" -msg $msg;
                }
  	            if ( $errmsgno -eq 0 ) {
                   $msg = "Tagging the object "+ $Thenet.name+" with tag "+$data["name"]+" done."
                   sendMessages -typmsg "OK" -msg $msg
                }
            }
          } else {
            #impossible to link if not exist
            $msg = "Cannot find the object="+$data["parentobject"]+" for the tag "+$data["name"]+". Nothing will be linked.";
            sendMessages -typmsg "ERROR" -msg $msg
          }
        }
       }
      }
   } else {
      $errmsgno=$ERRTAG1;
      $msg="Tag group "+$data["taggroup"]+" doesn`'t exist. Cannot add objet "+$data["name"]+". error="+$msgerror;
      sendMessages -typmsg "ERROR" -msg $msg;
   }
}

##############################################
# delete IP
# input:
#   @wsdl   WSDL proxyobject
#   @cfgid  ID of configuration
#   @range  found block ornull
#   @data   data to add
# return:
#   @none
##############################################
function deleteIP($wsdl, $cfgid, $range,$data,$fields) {
   $noterror=1;
   $errmsgno=0;
   if ($errmsgno -eq 0) {
       $subtypid=$deviceSubTypeFound.id;
       $IPFound = $wsdl.getIP4Address($cfgid, $data["ip"]); 
       $cfg = $wsdl.getEntityById($cfgid);
       $msgerror= "";
       if (($IPFound -eq $null ) -or ($IPFound.id -eq 0 ))  {
          $errmsgno=$ERRDEV1;
          $msg = "Delete not needed. The IP "+$data["ip"]+" doesn`'t exist already in this configuration (" + $cfg.name + ")! "+" error="+$msgerror;
          sendMessages -typmsg "INFO" -msg $msg;
       } else {
         try {
			 $resultDelete = $wsdl.delete($IPFound.id);
             $msg = "Deleting IP id="+$IPFound.id+" name="+$IPFound.Name+" properties="+$IPFound.properties;
             sendMessages -typmsg "OK" -msg $msg;
         } catch {
             $errmsgno=$ERRDEVPRO7;
             $msgerror= $_.Exception.Message;
             $msg = "Error by deleting IP id="+$IPFound.id+" name="+$IPFound.Name+" properties="+$IPFound.properties+" error="+$msgerror;
             sendMessages -typmsg "ERROR" -msg $msg;
         }
      }
   }
}


##############################################
# find subnet by CIDR
# input:
#   @wsdl   WSDL proxyobject
#   @cfgid  ID of configuration
#   @data   data to search
# return:
#   @none
##############################################
function searchSubnet($wsdl, $cfgid, $data) {
   $cfgname= $data["2"];
   [string] $subn   = $data["1"];
   $ipa = $subn.split('/');
   $ip = $ipa[0];
   $msg= 'search subnet ' + $subn + ' for configuration ' + $cfgname + ' where ip=' + $ip;
   sendMessages -typmsg "OK" -msg $msg;
   #$blocks= $wsdl.getEntities(20,"IP4Block",0,1000).id;
   #foreach ($block in $blocks) { $net=$wsdl.getEntityByCIDR($block,"146.109.19.0/24","IP4Network");
   #if ($net.id -ne 0) { write-Host "FOUND=" $net.name `n; } }
   $msgerror= "";
   $cfglist = @();
   if ($cfgname -eq 'all') {
     try {
       $cfglist = $wsdl.getEntities(0,"Configuration",0,50);
     } catch {
#$cfglist=@( @{id=1;Name="DEBUGGING";}, @{id=2;Name="DEBUGGING-2";}, @{id=3;Name="DEBUGGING-3";});
       $msgerror= $_.Exception.Message;
     }
   } else {
     try {
       $configFound = $wsdl.getEntityByName("0",$cfgname,"Configuration");
#$configFound=@{id=1;Name="DEBUGGING";};
       $cfglist += $configFound;
     } catch {
       $msgerror= $_.Exception.Message;
     }
   }
   if (($debugging -ne 'YES') -and ($msgerror -ne '' )) {
       if ($cfgname -eq 'all') { $msg1= ' no configuration found.';}
       else { $msg1 = $cfgname + ' not found.'; }
       $msg = "Error " + $msg1 + " Error="+$msgerror;
       sendMessages -typmsg "ERROR" -msg $msg;
       return;
   }
   $nosubfound = 1;
   foreach ($configFound in $cfglist) {
     try {
       $subnetFound = $wsdl.getIPRangedByIP($configFound.id,"IP4Network",$ip);
     } catch {
       $msg = 'Error in searching subnet '+$subn+'. ' + $_.Exception.Message;
       sendMessages -typmsg "ERROR" -msg $msg;
#if ($debugging -eq 'YES') {
#$subnetDebug=@(
#@{id=0;Name="DebugName0";properties=''}
#,@{id=1;Name="DebugName1";properties='VLAN=myvlandebug|descr_subnet=testing&Debugging|CIDR=10.1.0.0/24|allowDuplicateHost=disable|TESTED=|inheritAllowDuplicateHost=true';}
#,@{id=2;Name="DebugName2";properties='VLAN=myvlandebug|descr_subnet=testing&Debugging|CIDR=10.1.0.0/24|allowDuplicateHost=disable|TESTED=|inheritAllowDuplicateHost=true';}
#,@{id=3;Name="DebugName3";properties='VLAN=myvlandebug|descr_subnet=testing&Debugging|CIDR=10.1.0.0/24|allowDuplicateHost=disable|TESTED=|inheritAllowDuplicateHost=true';}
#);
#$subnetFound=$subnetDebug[$configFound.id];
#}
     }
     if (($subnetFound -eq $null) -or ($subnetFound.id -eq 0 )) {
        continue;
     } else {
       $nosubfound = 0;
       $properties= $subnetFound.properties;
       $tprop=$properties.split('|');
       $data = @{};
       foreach ($a in $tprop) {
          $b=$a.split('=');
          $data.Add($b[0],$b[1]);
       }
       $msgtitle = 'id,name,configuration';
       $msgvalues = '' + $subnetFound.id + ',' + $subnetFound.Name + ',' + $configFound.Name;
       $listexcludedfields= 'id,name';
       foreach ($fieldn in $global:aFieldsSearchSub) {
          $ti = $fieldn.ToLower();
          if  (-not (($listexcludedfields.Contains($ti) -or $ti.Contains('title'))) ) {
              #properties fields
              if ($data.containsKey($ti)) {
                  $val = $data[$ti];
                }
                else { $val=""; }
                $msgtitle = $msgtitle+','+ $fieldn;
                $msgvalues = $msgvalues+','+ $val;
              }
       }
       #$msg = $msgtitle + "`n" + $msgvalues; 
       $msg = $msgvalues; 
#       $tprop=$tmpprop.split('|');
#       foreach ($a in $tprop) { $b=$a.split('='); $msg = $msg + ',' + $b[0]; };
#       $msg= $msg + "`n"; 
#       $msg = $msg + $subnetFound.id + ',' + $subnetFound.name + ',' + $configFound.Name;
#       foreach ($a in $tprop) { $b=$a.split('='); $msg = $msg + ',' + $b[1]; };
       sendMessages -typmsg "NORMAL" -msg $msg -out $global:isoutput;
#       $msg = "The Subnet "+$subn+' exist in configuration ' + $configFound.Name + '. Actual object is id='+$subnetFound.id+" cfg="+$configFound.Name + " properties=" + $tmpprop; 
#       sendMessages -typmsg "OK" -msg $msg;
     }
   }
   if ($nosubfound -eq 1) {
       $msg = 'The Subnet '+$subn+' not found.';
       sendMessages -typmsg "ERROR" -msg $msg;
   }
}

##############################################
# Main function
# input: none
# return: none
##############################################
function main() {
 sendMessages -typmsg "DEBUG" -msg "---------- BEGIN -------------"
 $step= 0;
 $errmsgno= 0;
 $userAPI=$pwAPI="";
 $theInput="";
 $containerFile="";
 $error=@{}
 $error[$ERRFUNC1]= 'cannot be read or doesnt exist!';
 $lista= ""; foreach ($a in $listActions) { $lista= $lista+","+$a; }
 $error[$ERRFUNC2]= "No configuration found! Cannot apply other changes";
 $error[$ERRFUNC3]= "Wrong action! Should be one of these values $lista !";
 $error[$ERRFUNC4]= "No IP-subnetfound.";
 getInputs -name ([ref]$userAPI) -pass ([ref]$pwAPI) -input ([ref]$theInput) -out ([ref] $isoutput);

 if (-not( Test-Path $INPUT_FILE) ) {
    $errmsgno=$ERRFUNC1;
    $msg= $INPUT_FILE+" " +$error[$errmsgno];
	sendMessages -typmsg "ERROR" -msg $msg;
	exit;
 }
 $pingnb=0;
 do {
	$ping = new-object system.net.networkinformation.ping;
    try {
      $pingreturns = $ping.send(“$proteus");
      $status = $pingreturns.Status;
    } catch {
      if ($debugging -eq 'YES') { $status = "Success"; }
      else {
       $msg ="Error system: Check your IP ${proteus} ... ${status}";
      }
    }
    $pingnb++;
 } until (($Status -eq 'Success') -or ($pingnb -ge 4));
 if ($pingreturns.Status -ne 'Success') {
    if ($debugging -ne 'YES') {
       $msg ="Cannot ping ${proteus} ... ${status}";
       sendMessages -typmsg "DEBUG" -msg $msg;
       exit;
     } else {
       $msg ="Cannot ping ${proteus} ... Continuing for debugging mode ... ";
       sendMessages -typmsg "DEBUGGING" -msg $msg
    }
 } else {
   sendMessages -typmsg 'DEBUG' -msg 'Proteus reachable';
 }
 sendMessages -typmsg 'DEBUG' -msg "initialize .Net";
 $wsdl= initAPI -name $userAPI -pass $pwAPI;
 if (($debugging -eq 'YES') -or (($wsdl -ne $null) -and ($wsdl -ne 0)) ) {
  #begin of the treatment
  readInputs -varfile ([ref] $containerfile);
  foreach ($line in $containerfile) {
    $ligne=$line.trim();
    if (($ligne -ne "") -and ($ligne[0] -ne "#")) {
      $msg= "Analyzing line ... $line"
      sendMessages -typmsg "INFO" -msg $msg;
      $thedata= fillLineInfo -line $line;
      $theAction= $thedata["action"].toUpper();
      $theAction= $theAction.replace("_FORCE","");
      if ($theAction.Contains("TITLE")) {
	    # later for more parameters
        $theTitles= fillTitleInfo -line $line;
        continue;
      } elseif ($theAction.Contains("CONFIG-NAME")) {
        $cfgid= initConfiguration -wsdl ([ref] $wsdl) -configname $thedata["name"];
        if($wsdl["cfgid"] -ne 0) {
           $step =1;
        } else {
           $step =2;
        }
        continue;
      }
      if (($listReadActions -contains $theAction)) {
        switch ($theAction) {
           "SEARCHSUBNET" {
             searchSubnet -wsdl $wsdl["proxy"] -cfgid $wsdl["cfgid"] -data $thedata
             break;
           }
           default { break; }
        } #end switch
        $step =2;
        continue;
      }
      if ($step -eq 1) {
       if (($listActions -contains $theAction)) {
        if ( ($theAction.Contains("_DEVICE")) -or ($theAction.Contains("_TAG")) ) {
          switch ($theAction) {
            "DEL_DEVICE" {
              deleteDevice -wsdl $wsdl["proxy"] -cfgid $wsdl["cfgid"] -data $thedata -fields $theFields
              break;
            }
            "ADD_DEVICE" {
              addDevice -wsdl $wsdl["proxy"] -cfgid $wsdl["cfgid"] -data $thedata -fields $theFields
              break;
            }
            "MODIFY_DEVICE" {
              modifyDevice -wsdl $wsdl["proxy"] -cfgid $wsdl["cfgid"] -data $thedata -fields $theFields
              break;
            }
            "ADD_TAG" {
              addTags -wsdl $wsdl["proxy"] -cfgid $wsdl["cfgid"] -data $thedata -fields $theFields
              break;
            }
            "MODIFY_TAG" {
              modifyTags -wsdl $wsdl["proxy"] -cfgid $wsdl["cfgid"] -data $thedata -fields $theFields
              break;
            }
            default {
              $errmsgno=$ERRFUNC2;
              $msg= $error[$errmsgno]+" "+$thedata["action"];
              sendMessages -typmsg "ERROR" -msg $msg;
            }
          } #end switch
        } else {
           if ($theAction.contains("_IP")) {
             $tmp= $thedata["ip"];
           } else {
             $tmp= $thedata["CIDR"];
           } 
           $lg=$tmp.IndexOf("/");
           if($lg -ge 0) {
             $b=$tmp.Substring($deb,$lg);
             $value= $tmp.Substring(0,$lg);
           } else {
            $value= $tmp;
           }
           try {
             $rangeFound = $wsdl["proxy"].getIPRangedByIP($wsdl["cfgid"], "IP4Block",$value)
             $msg= $tmp + " belongs to block name="+$rangeFound.name + "("+$rangeFound.id+") properties="+$rangeFound.properties;
             sendMessages -typmsg "INFO" -msg $msg;
           } catch {
             $msg = 'Error by searching range '+$value+'. ' + $_.Exception.Message;
             sendMessages -typmsg "ERROR" -msg $msg;
             if ($debugging -eq 'YES') {
             }
           }
           if (($rangeFound.Type -ne $null) -and ($rangeFound.Id -ne 0) ) {
              switch ($theAction) {
               "MODIFY_IP" {
                 modifyIP -wsdl $wsdl["proxy"] -cfgid $wsdl["cfgid"] -range $rangeFound -data $thedata
                 break;
               }
               "ADD_IP" {
                 addIP -wsdl $wsdl["proxy"] -cfgid $wsdl["cfgid"] -range $rangeFound -data $thedata
                 break;
               }
               "DEL_IP" {
                 deleteIP -wsdl $wsdl["proxy"] -cfgid $wsdl["cfgid"] -range $rangeFound -data $thedata
                 break;
               }
               "ADD_SUBNET" {
                 addSubnet -wsdl $wsdl["proxy"] -cfgid $wsdl["cfgid"] -range $rangeFound -data $thedata
                 break;
               }
               "MODIFY_SUBNET" {
                 modifySubnet -wsdl $wsdl["proxy"] -cfgid $wsdl["cfgid"] -range $rangeFound -data $thedata
                 break;
               }
               default {
                 $errmsgno=$ERRFUNC3;
                 $msg= $error[$errmsgno]+' '+$thedata['action'];
                 sendMessages -typmsg 'ERROR' -msg $msg;
               }
              } #end switch
           } else {
             $errmsgno=$ERRFUNC4;
             $msg= $error[$errmsgno]+' '+$theAction;
             sendMessages -typmsg 'ERROR' -msg $msg;
          }
        }
       } else {
         $errmsgno=$ERRFUNC3;
         $msg= $error[$errmsgno]+' '+$theAction;
         sendMessages -typmsg 'ERROR' -msg $msg;
       }
      }
    } 
  }
  if ( $step -eq 0 ) {
     $errmsgno=$ERRFUNC2;
     $msg= $error[$errmsgno];
     sendMessages -typmsg 'ERROR' -msg $msg;
  }
   try {
     $wsdl['proxy'].logout();
   } catch {
     $msg ="Error on logout ${proteus}.";
     sendMessages -typmsg "ERROR" -msg $msg
   }

 }
 sendMessages -typmsg 'DEBUG' -msg '------------- END ------------';
}


main ;
exit;
