param([string]$level,[string]$ip,[switch]$help=$false,[string]$commands,[string]$output,[string]$user,[string]$password)
#
# project https://github.com/jmpep/Bluecat-Proteus-import-export
# Copyright MIT License. For details look at https://github.com/jmpep/Bluecat-Proteus-import-export/blob/master/LICENSE
#

##############################################
# show help
#   
# input:
#   @none
# return:
#   @none
##############################################
function showHelp($path) {
  $read = [System.IO.File]::OpenText($PSScriptRoot+"\readme.md");
  while($null -ne ($line = $read.ReadLine())) {
    sendMessages -typmsg "HELP" -msg $line;
  }
  $read.close();
}

#global inline# global variables
$pt= $MyInvocation.MyCommand.path
$pt= $pt.Replace(".ps1","");
$global:INPUT_FILE = $pt+".csv"
$global:OUTPUT_FILE = $pt+".out"
$global:isoutput = "YES";
$global:LOG_FILE= $pt+".log"
$global:ERROR_LEVEL = "DEBUG"  # DEBUGGING < DEBUG < INFO < WARNING < ERROR < NORMAL < OK
$global:logoverwrite="YES";
$global:outputoverwrite="YES";
#$global:wsdlPath = "http://$proteus/Services/API?wsdl"
$global:proteus = "127.0.0.1";
$global:wsdlPath = "https://$proteus/Services/API?wsdl"
$global:Configuration = "Network"
$MAXBLOCKS=1000;
#define the minimal fields
$global:aFieldsIP  = @('TITLE_IP','name','ip');
$global:aFieldsSub = @('TITLE_SUBNET','CIDR','name');
$global:aFieldsDev = @('TITLE_DEVICE','name');
$global:aFieldsTag = @('TITLE_IP','name','taggroup');
$global:aFieldsSearchSub = @('TITLE_SEARCHSUBNET','name','cidr');
$global:aFieldsListIPs = @('TITLE_SEARCHSUBNET','name','cidr');
$global:aFieldsListDevices = @('TITLE_LISTDEVICES','name','IP4Addresses');
$global:nFieldsIP  = @{TITLE_IP=0;name=1;ip=2;};
$global:nFieldsSub = @{TITLE_SUBNET=0;name=2;CIDR=1;};
$global:nFieldsDev = @{TITLE_DEVICE=0;name=1;};
$global:nFieldsTag = @{TITLE_IP=0;name=1;taggroup=2;};
$global:nFieldsSearchSub = @{TITLE_SEARCHSUBNET=0;name=1;cidr=2;};
$global:nFieldsListIPs = @{TITLE_SEARCHSUBNET=0;name=1;cidr=2;};
$global:nFieldsListDevices = @{TITLE_LISTDEVICES=0;name=1;IP4Addresses=2;};
$global:listActions = "CONFIG-NAME","ADD_IP","ADD_IP_FORCE","MODIFY_IP","DEL_IP","ADD_SUBNET","ADD_SUBNET_FORCE","MODIFY_SUBNET","ADD_DEVICE","ADD_DEVICE_FORCE","DEL_DEVICE","MODIFY_DEVICE","ADD_TAG","MODIFY_TAG";
$global:listReadActions = @('SEARCHSUBNET','LISTIPS','LISTDEVICES','COMMENT_OUTPUT');

##############################################
# read information from console
# input:
#   @name    address from variable name
#   @pass    address from variable password
# return:
#   @none
##############################################
function getInputs([ref]$name,[ref]$pass,[ref]$ip, [ref] $out) {
 if ($ip.value -eq '') {
   $ip.value = Read-Host 'IP (' $global:proteus ' )? Enter to keep this one'
   if ($ip.Value -ne '') { $global:proteus=$ip };
 }
 if ($out.Value -eq '') {
   $outtxt = 'Output in file "'+$global:OUTPUT_FILE +'" ['+$global:isoutput+']?';
   $outtmp = Read-Host $outtxt;
   if ($outtmp.ToUpper() -ne '') {
    if (($outtmp.ToUpper() -eq 'Y') -or ($outtmp.ToUpper() -eq 'YES')) { $out = 'YES'}
   } else {
    $out= $global:isoutput;
   }
 }
 if ($name.Value -eq '') { $name.Value = Read-Host 'DB username?' }
 if ($pass.Value -eq '') {
   $passcypher = Read-Host 'DB password?' -AsSecureString
   $pass.Value=[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($passcypher));
 }
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
function getLevelParam( ) {
  $typmsg = @{
                 DEBUGGING=@{color="white";background="Red";level=0};
                 DEBUG=@{color="white";background="";level=20};
                 INFO=@{color="yellow";background="";level=40};
                 WARNING=@{color="magenta";background="";level=50};
                 NORMAL=@{color="white";background="";level=60}
                 ERROR=@{color="red";background="";level=70};
                 OK=@{color="green";background="";level=70}
                 HELP=@{color="white";background="green";level=70}
                };
  return ,$typmsg;
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
    $typmsg= $typmsg.ToUpper();
    $color = "white";$background='';
    $atypmsg = getLevelParam;
    if (-not $atypmsg.ContainsKey($typmsg)) {
       $typmsg = "INFO";
    }
    if (-not $atypmsg.ContainsKey($ERROR_LEVEL)) {
       $typmsg = "INFO";
    }
    if ($out -eq "YES" ) {
        Write-Output $msg | Out-File $OUTPUT_FILE -Append
    }
    if ($typmsg -eq 'HELP') {
          Write-Host $msg  -foregroundcolor $atypmsg[$typmsg].color -backgroundcolor $atypmsg[$typmsg].background;
    } else {
      if ($atypmsg[$ERROR_LEVEL].level -le $atypmsg[$typmsg].level ) {
        $date=Get-Date -Format "yyyy-mm-dd,H:mm:ss"
        if ($typmsg -eq "") { $typmsg2= ""} else { $typmsg2="${typmsg}"}
        $message="${date},${typmsg2},${msg}"
        if ($typmsg -ne "" ) {
          Write-Output $message | Out-File $LOG_FILE -Append
        }
        if ($atypmsg[$typmsg].background -eq '') {
          Write-Host $message  -foregroundcolor $atypmsg[$typmsg].color;
        } else {
          Write-Host $message  -foregroundcolor $atypmsg[$typmsg].color -backgroundcolor $atypmsg[$typmsg].background;
        }
      }
    }
 }

##############################################
# function for DEBUG
##############################################
function ArrayToHash($a)
{
    $hash = @{};
    $i=0;foreach ($val in $a) { $hash.Add($val,$i);$i++; }
    return $hash;
}

##############################################
# function for DEBUG
##############################################
function stringArray ($a) {
  $val = '';
  foreach ($b in $a) { if ($val -eq '') { $val= $b } else { $val = $val + "," + $b;} }
  return $val;
}
##############################################
# function for DEBUG
##############################################
function stringHash ($a) {
  $val = '';
  $a1='';foreach ($i in $a.Keys.GetEnumerator() )  { if ($a1 -eq '') { $a1=$i; } else { $a1="$a1,$i"; }};
  $a2='';foreach ($i in $a.Values.GetEnumerator() ){ if ($a2 -eq '') { $a2=$i; } else { $a2="$a2,$i"; }};
  $val = '{(' + $a1 + ')=(' + $a2 + ')}';
  return $val;
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
           #$global:aFieldsSearchSub=$fields.ToLower(); $global:nFieldsSearchSub=ArrayToHash($fields);
           $global:aFieldsSearchSub=$fields; $global:nFieldsSearchSub=ArrayToHash($fields);
           $msg= $line;
           $i1= $msg.ToUpper().indexOf('TITLE_SEARCHSUBNET');
           if ($i1 -ge 0) {
              $i2=$msg.indexOf(',',$i1);
              $msg= $msg.Substring($i2+1);
           }
           sendMessages -typmsg "NORMAL" -msg $msg -out $global:isoutput;
        }
        "TITLE_LISTIPS"    {
           $global:aFieldsListIPs=$fields; $global:nFieldsListIPs=ArrayToHash($fields);
           $msg= $line;
           $i1= $msg.ToUpper().indexOf('TITLE_LISTIPS');
           if ($i1 -ge 0) {
              $i2=$msg.indexOf(',',$i1);
              $msg= $msg.Substring($i2+1);
           }
           sendMessages -typmsg "NORMAL" -msg $msg -out $global:isoutput;
        }
        "TITLE_LISTDEVICES"    {
           $global:aFieldsListDevices=$fields; $global:nFieldsListDevices=ArrayToHash($fields);
           $msg= $line;
           $i1= $msg.ToUpper().indexOf('TITLE_LISTDEVICES');
           if ($i1 -ge 0) {
              $i2=$msg.indexOf(',',$i1);
              $msg= $msg.Substring($i2+1);
           }
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
    } elseif ($todo.Contains("_IP")) {
#below WILL BE simplified later
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
    } elseif ($todo.Contains("LISTIPS")) {
      $info = @{};
      for ($i=0; $i -lt $aFieldsListIPs.Count;$i++) {
        if ($i -lt $fields.Count) {
           $info.Add($aFieldsListIPs[$i],$fields[$i]);
        } else {
           $info.Add($aFieldsListIPs[$i],'');
        }
      }
      $info.Add("action",$fields[0]);
    } elseif ($todo.Contains("LISTDEVICES")) {
      $info = @{};
      for ($i=0; $i -lt $aFieldsListDevices.Count;$i++) {
        if ($i -lt $fields.Count) {
           $info.Add($aFieldsListDevices[$i],$fields[$i]);
        } else {
           $info.Add($aFieldsListDevices[$i],'');
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
   exit;
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
     exit;
  }
 return $wsdlinit;
}

##############################################
# initialisation of the View
# input:
#   @wsdl   WSDL proxyobject
#   @configname  ID of configuration
# return:
#   @configid 
##############################################
function initConfiguration([ref] $wsdl, [string] $configname) {
   $ok=0;
   $ErrorMessage = ''
   # get the ID of configruation
   try {
     $ConfigFound = $wsdl.value["proxy"].getEntityByName("0",$configname,"Configuration");
   } catch {
     $ErrorMessage = $_.Exception.Message;
   }
   if (($ErrorMessage -eq '') -and ($ConfigFound.id -ne 0)) {
     $para = $configname+';'+$ConfigFound.id;
     $msg= getMessage -code $INIT3 -field $para;
     sendMessages -typmsg "OK" -msg $msg;
     $wsdl.value["cfgid"]= $ConfigFound.id;
   } else {
     $para = $configname+';'+$ErrorMessage;
     $e = showError -code $ERRINIT3 -fields $para;
     $wsdl.value["cfgid"]= 0;
   }
   return $ConfigFound.id;
}

##############################################
# serch configuration
# input:
#   @wsdl   WSDL proxyobject
#   @configname  ID of configuration
# return:
#   @configid 
##############################################
function searchConfiguration($wsdl, [string] $configname) {
   $cfgid=0;
   $ErrorMessage = ''
   # get the ID of configruation
   try {
     $ConfigFound = $wsdl.getEntityByName("0",$configname,"Configuration");
   } catch {
     $ErrorMessage = $_.Exception.Message;
   }
   if (($ErrorMessage -ne '') -or (!$ConfigFound) -or ($ConfigFound.id -eq 0)) {
     $e = showError -code $ERRINIT3 -fields $configname+';'+ $ErrorMessage;
   } else {
     $cfgid = $ConfigFound.id;
   }
   return $Cfgid;
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
# simple delete object
# input:
#   @wsdl   WSDL proxyobject
#   @object object
#   @type   string
# return:
#   @none
##############################################
function deleteObject($wsdl, $object) {
   $err=0;
   if ($object.id -ne 0 ) {
     try {
       $resultDelete = $wsdl.delete($object.id);
       $msg = 'This object already exists. Option FORCE. Removing object id='+$object.id+" name="+$object.Name+" properties="+$object.properties;
       sendMessages -typmsg "INFO" -msg $msg;
     } catch {
       $err=1;
       $msgerror= $_.Exception.Message;
       $msg = "Error by deleting of the object id="+$object.id+" name="+$object.Name+" properties="+$object.properties+" error="+$msgerror;
       sendMessages -typmsg "ERROR" -msg $msg;
     }
   }
   return $err;
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
function deleteIP($wsdl, $cfgid, $data,$verbose=1) {
   $noterror=1;
   $errmsgno=0;
   if ($data.containsKey('ip') -or $data.containsKey('IP') ) {
     $ip = $data['ip'];
   } elseif ($data.containsKey('IP4Address')) {
     $ip = $data['IP4Address'];
   }
   if ($errmsgno -eq 0) {
       $IPFound = $wsdl.getIP4Address($cfgid, $ip); 
       $cfg = $wsdl.getEntityById($cfgid);
       $msgerror= "";
       if ((!$IPFound) -or ($IPFound.id -eq 0 ))  {
         if ($verbose -eq 1) {
           $errmsgno=$ERRIPDEL1;
           if ($msgerror -ne '') { $msg2= ' Error:'+$msgerror; } else { $msg2 ='' }
           $msg = "Delete not needed. The IP "+$ip+" doesn't exist already in this configuration (" + $cfg.name + ')!'+$msg2;
           sendMessages -typmsg "INFO" -msg $msg;
         }
       } else {
         try {
			 $resultDelete = $wsdl.delete($IPFound.id);
             $msg = "Deleting IP id="+$IPFound.id+" name="+$IPFound.Name+" properties="+$IPFound.properties;
             sendMessages -typmsg "OK" -msg $msg;
         } catch {
             $errmsgno=$ERRIPDEL2;
             $msgerror= $_.Exception.Message;
             if ($msgerror -ne '') { $msg2= ' Error:'+$msgerror; } else { $msg2 ='' }
             $msg = "Error by deleting IP id="+$IPFound.id+" name="+$IPFound.Name+" properties="+$IPFound.properties+'.'+$msg2;
             sendMessages -typmsg "ERROR" -msg $msg;
         }
      }
   }
   return $errmsgno;
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
function addIP($wsdl, $cfgid, $range, $data) {
   $errmsgno = 0;
   if ($data.containsKey('ip') -or $data.containsKey('IP') ) {
     $ip = $data['ip'];
   } elseif ($data.containsKey('IP4Address')) {
     $ip = $data['IP4Address'];
   }
   $Ifspecialgateway = 0;
   if ($data["action"].Contains("_FORCE")) {
      $IfExistDelete =1;
      $errmsgno = deleteIP -wsdl $wsdl -cfgid $cfgid -data $thedata -verbose 1;
      if ($errmsgno -eq 0) {
          $msg = 'Option FORCE. The IP '+$ip+' has been deleted!';
          sendMessages -typmsg "NORMAL" -msg $msg;
      }
      $errmsgno =0;
   } else {
      #check if it is a default gateway created without values
      $IPFound = $wsdl.getIP4Address($cfgid, $ip); 
      if ($IPFound -and $IPFound.id -ne 0 ) {
        if ([string]::IsNullOrEmpty($IPFound.name) -and $IPFound.properties.Contains('state=GATEWAY|') ) {
          # only a update is needed
          $Ifspecialgateway =1;
        } else {
          $errmsgno = $ERRIP1;
          $msg = "The IP "+$ip+" exist already! actual object is id="+$IPFound.id+" name="+$IPFound.Name+" properties="+$IPFound.properties;
          sendMessages -typmsg "ERROR" -msg $msg;
          $msgerror= $msg;
        }
      }
   }
   if ($errmsgno -eq 0) {
    $subnetFound = $wsdl.getIPRangedByIP($cfgid, "IP4Network",$ip)
    if ((!$subnetFound) -or ($subnetFound.Id -eq 0) ) {
       $msg = "No subnet found for this IP "+$ip+' in this configuration ID '+$cfgid+' !';
       sendMessages -typmsg "ERROR" -msg $msg;
       $errmsgno = $ERRIP2;
    } else {
       # assign the IP / "MAKE_DHCP_RESERVED", "MAKE_STATIC", "MAKE_RESERVED" 
       $msg = "Trying to insert IP "+$ip+" in subnet id="+$subnetFound.id+" subnet name="+$subnetFound.Name+" properties="+$subnetFound.properties;
       sendMessages -typmsg "DEBUG" -msg $msg;
       $mac="";
       $action="MAKE_STATIC";
       $hostInfo=$data["name"];
       $properties = "";
       $listexcludedfields= 'ip,name,title';
       foreach ($fieldn in $global:aFieldsIP) {              
         $ti = $fieldn.ToLower();
         if  ( -not ($listexcludedfields.Contains($ti) -or $ti.Contains('title')) ) {
             if ($data.containsKey($ti)) { $val = $data[$ti]; }
             else { $val=""; }
             $properties = $properties+ $fieldn +"="+ $val + '|';
         }
       }
       try {
          $msgerror= '';
          if ($Ifspecialgateway -eq 1) {
            $IPFound.name = $hostInfo;
            $IPFound.properties = $properties;
            $wsdl.update($ipFound);
            $msg = "Special case gateway of subnet "+$ip+" with properties="+$properties+'!';
            sendMessages -typmsg "NORMAL" -msg $msg;
          } else {
            $ipFound = $wsdl.assignIP4Address($cfgid, $ip,$mac,$hostInfo,$action,$properties);
          }
       } catch {
          $ipFound = $null;
          $errmsgno = $ERRIP3;
          $msgerror=$_.Exception.Message;
       }
       if ( !$ipFound -or $ipFound.id -eq 0 ) {
          if ($msgerror -ne '') { $msg2 = ' Error '+$msgerror; }
          else { $msg2 = ''; }
          $msg = "Could not assign the IP "+$ip+" with properties="+$properties+'!'+ $msg2;
          sendMessages -typmsg "ERROR" -msg $msg;
       } else {
          $ipCheck = $wsdl.getIP4Address($cfgid, $ip); 
          #$ipCheck = $wsdl.getEntityByName($cfgid,$ipFound,"IP4Address");
          $msg = "Achieved assignation of the IP "+$ip+". Saved id="+$ipCheck.id+" name="+$ipCheck.name+" with properties="+$ipCheck.properties;
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
   if ($data.containsKey('ip') -or $data.containsKey('IP') ) {
     $ip = $data['ip'];
   } elseif ($data.containsKey('IP4Address')) {
     $ip = $data['IP4Address'];
   }
   try {
     $tmpip = $wsdl.getIP4Address($cfgid, $ip);
   } catch {
     $ErrorMessage = $_.Exception.Message;
     if ($ErrorMessage -ne '') { $msg2= ' Error: '+$ErrorMessage; }
     else  { $msg2= ''; }
     $msg= "Update not possible! id="+$tmpip.id+" name="+$tmpip.name+" properties="+$tmpip.properties+$msg2;
     sendMessages -typmsg "ERROR" -msg $msg;
     $error=1;
   }
   if ( $tmpip -eq $null ) {
          $msg = "The IP "+$ip+" doesn't exist! No changes are possible";
          sendMessages -typmsg "ERROR" -msg $msg;
   } else {
     $subnetFound = $wsdl.getIPRangedByIP($cfgid, "IP4Network",$ip)
     if (($subnetFound.Type -eq $null) -or ($subnetFound.Id -eq 0) ) {
            $msg = "No subnet found for this IP "+$ip+" !";
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


       $listexcludedfields= 'ip,name,title';
         if  ( -not ($listexcludedfields.Contains($ti) -or $ti.Contains('title')) ) {
             if ($data.containsKey($ti)) { $val = $data[$ti]; }
             else { $val=""; }
             $properties = $properties+ $fieldn +"="+ $val + '|';
         }
       foreach ($fieldn in $global:aFieldsIP) {
         $ti = $fieldn.ToLower();
         if  ( -not ($listexcludedfields.Contains($ti) -or $ti.Contains('title')) ) {
             if ($data.containsKey($ti)) { $new = $data[$ti]; }
             else { $new=""; }
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
           if ($ErrorMessage -ne '') { $msg2= ' err_msg='+$ErrorMessage; }
           else  { $msg2= ''; }
           $msg= "Update not possible! id="+$tmpip.id+" name="+$tmpip.name+" properties="+$tmpip.properties+$msg2;
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
   if ($data["action"].Contains("_FORCE")) { $IfExistDelete =1; } else { $IfExistDelete =0;   }
   try {
     $subnetFound = $wsdl.getEntityByCIDR($range.id,$data["CIDR"],"IP4Network");
     $msgerror= "";
   } catch {
     $msgerror= $_.Exception.Message;
   }
   if ($subnetFound.id -ne 0 ) {
      if ($msgerror -ne '') { $msg2 = ' Error:'+$msgerror; } else { $msg2= ''}
      $msg = "The Subnet "+$data["CIDR"]+" exist already! Cannot add it. Actual object is id="+$subnetFound.id+" name="+$subnetFound.Name+" properties="+$subnetFound.properties+'.'+$msg2;
      sendMessages -typmsg "ERROR" -msg $msg;
   } else {
     if ($range -ne $null) {
         # check properties
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
      if ($msgerror -ne '') { $msg2 = ' Error:'+$msgerror; } else { $msg2= ''}
      $msg = "The Subnet "+$data["CIDR"]+' does not exist ! Cannot modify it. Actual object is id='+$subnetFound.id+" name="+$subnetFound.Name+" properties="+$subnetFound.properties+'.'+$msg2;
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
      $list='';
      foreach ($udf in $listOfDevicesFields) { if ($list -eq '') { $list=$udf.name;} else {$list = $list+','+$udf.name;} }
      $errno=$ERRDEVPRO2;
      $msg = "Wrong property's name or user defined field "+$fieldsname+" of device. "+$fieldsname+" doesn't exist for any !";
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
#   @errmsgno error id
##############################################
function addDevice($wsdl, $cfgid,$data) {
  if($cfgid -eq 0) {
      $errmsgno=$ERRCFG1;
      $msg = 'Missing configuration or configuration invalid.';
      sendMessages -typmsg "ERROR" -msg $msg;
      return $errmsgno;
  } else {
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
      if ($msgerror -ne '') { $msg2 = ' Error:'+$msgerror; } else { $msg2= ''}
      $msg = "The device's type '"+$data["DeviceType"]+"' does'nt exist ! Cannot add objet "+$data["name"]+'.'+$msg2;
      sendMessages -typmsg "ERROR" -msg $msg;
   }
   $subtypid=0;
   if ($data["DeviceSubtype"] -ne '') {
       $deviceSubtypeFound = $wsdl.getEntityByName($deviceTypeFound.id,$data["DeviceSubtype"],"DeviceSubtype");
       if (($deviceSubTypeFound -eq $null) -or ($deviceSubTypeFound.id -eq 0 )) {
         $errmsgno=$ERRDEVTYP2;
         if ($_.Exception.Message -ne '') { $msg2 = ' Error:'+$_.Exception.Message; } else { $msg2= ''}
         $msg = "The device's subtype '"+$data["DeviceSubtype"]+"' does not exist ! Cannot add objet "+$data["name"]+'.'+$msg2;
         sendMessages -typmsg "ERROR" -msg $msg
       }
       $subtypid=$deviceSubTypeFound.id;
   }
   if ($errmsgno -eq 0) {
     $deviceFound = $wsdl.getEntityByName($cfgid,$data["name"],"Device");
     $msgerror= "";
     if ((($deviceFound -ne $null ) -and ($deviceFound.id -ne 0 )) -and ( -not $IfExistDelete )) {
          $errmsgno=$ERRDEV1;
          if ($msgerror -ne '') { $msg2 = ' Error:'+$msgerror; } else { $msg2= ''}
          $msg = "The device "+$data["name"]+" exist already! Cannot add it. Actual object is id="+$deviceFound.id+" name="+$deviceFound.Name+" devicetype="+$deviceFound.devicetype+" properties="+$deviceFound.properties+'.'+$msg2;
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
             if ($msgerror -ne '') { $msg2 = ' Error:'+$msgerror; } else { $msg2= ''}
             $msg = "Error by deleting of the device id="+$deviceFound.id+" name="+$deviceFound.Name+" properties="+$deviceFound.properties+'.'+$msg2;
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
   return $errmsgno;
  }
}

##############################################
# delete Device
# input:
#   @wsdl   WSDL proxyobject
#   @cfgid  ID of configuration
#   @data   data to add
# return:
#   @errmsgno error id
##############################################
function deleteDevice($wsdl, $cfgid,$data,$fields) {
  if($cfgid -eq 0) {
      $errmsgno=$ERRCFG1;
      $msg = 'Missing configuration or configuration invalid.';
      sendMessages -typmsg "ERROR" -msg $msg;
      return $errmsgno;
  } else {
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
   return $errmsgno;
 }
}

##############################################
# modify Device
# input:
#   @wsdl   WSDL proxyobject
#   @cfgid  ID of configuration
#   @data   data to add
# return:
#   @errmsgno error id
##############################################
function modifyDevice($wsdl, $cfgid,$data,$fields) {
  if($cfgid -eq 0) {
      $errmsgno=$ERRCFG1;
      $msg = 'Missing configuration or configuration invalid.';
      sendMessages -typmsg "ERROR" -msg $msg;
      return $errmsgno;
  } else {
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
                               $tmpprop = $tmpprop.replace($b,$newb);
                               $b = $newb;
                             } else {
                               $b2=$b+',';
                               if (-not $b2.contains($ip+',') ) {
                                 $newb= $b +','+$ip;
                                 $tmpprop = $tmpprop.replace($b,$newb);
                                 $b = $newb;
                               }
                             }
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
   return $errmsgno;
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
   $cfgname = $cfgid;
   $errmsgno=0;
   if ($data["action"].Contains("_FORCE")) {
       $IfExistDelete =1;
   } else {
       $IfExistDelete =0;
   }
   try {
     $taggroupFound = $wsdl.getEntityByName(0,$data["taggroup"],"TagGroup");
     $msgerror= "";
   } catch {
     $errmsgno=$ERRTAG1;
     $msgerror= $_.Exception.Message;
   }
   if (($errmsgno -eq 0) -and ($taggroupFound -ne $null) -and ($taggroupFound.id -ne 0) -and ($data["taggroup"] -eq $taggroupFound.name) ) {
      # search the parent object
      $parentobject ="";
      $parenttag = "";
      $parenttype= 'IP4Network';
      $listpossibleparent = 'cidr,ip4network:cidr,ip4address,ip4address:ip,ip4block:cidr';
      foreach ($fieldn in $global:aFieldsTag) {              
           $ti = $fieldn.ToLower();
           if  ($listpossibleparent.Contains($ti) ) {
              $parentobject = $fieldn;
              switch ($ti) {
                 "cidr"              { $parenttag = 'cidr'; $parenttype= 'IP4Network';}
                 "ip4network:cidr"   { $parenttag ='cidr'; $parenttype= 'IP4Network';}
                 "ip4address"        { $parenttag = 'IP4Address';  $parenttype= 'IP4Address';}
                 "ip4address:ip"     { $parenttag = 'IP4Address';  $parenttype= 'IP4Address';}
                 "ip4block:cidr"     { $parenttag = 'cidr';$parenttype= 'IP4Block';}
                 default { }
              }
           }
      }
      # does exist the tag
      $msg='OK. Tag group '+$data['taggroup']+' exists (id='+$taggroupFound.id+')';
      sendMessages -typmsg "DEBUG" -msg $msg;
      $properties = ""
      if ($parentobject -eq '' ) { $listexcludedfields= 'id,name,taggroup,config-name'; }
      else { $listexcludedfields= 'id,name,taggroup,config-name'+','+$parentobject.ToLower(); }
      foreach ($fieldn in $global:aFieldsTag) {
        $ti = $fieldn.ToLower();
        if  ( -not ($listexcludedfields.Contains($ti) ) ) {
          switch -wildcard ($ti) {
             "title*" { }
             default {
                if ($data.containsKey($ti)) { $val = $data[$ti]; }
                else { $val=""; }
                  $properties = $properties+ $fieldn +"="+ $val + '|';
               }
          }
        }
      }
      $TagFound = $wsdl.getEntityByName($taggroupFound.id,$data["name"],"Tag");
      $msgadditional = '';
      if ((($TagFound -ne $null ) -and ($TagFound.id -ne 0 )) ) {
        $msg= "Tag " + $data["name"] + " exists already (id=" +$TagFound.id + ").";
        $msgadditional = 'Already exists.';
        if ($msgerror -ne "") { $msg= $msg + ' ('+$msgerror+')'; }
        sendMessages -typmsg "DEBUG" -msg $msg;
        if ( -not $IfExistDelete ) {
          # no FORCE option
          $errmsgno=$ERRTAG2;
        } else {
          if ( ($errmsgno -eq 0) -and ( $IfExistDelete -eq 1)) {
            if (deleteObject -wsdl $wsdl -object $TagFound ) {
               $errmsgno=- $ERRDEVPRO7;
            }
          }
        }
      }
      if ($errmsgno -eq 0) {
        $msg = "Preparing creation of tag "+$data["name"]+" in the group "+$data["taggroup"]+" with properties=$properties";
        sendMessages -typmsg "DEBUG" -msg $msg
        try {
          $TagFoundID = $wsdl.addTag($taggroupFound.id,$data["name"],$properties);
          if ($TagFoundID -eq 0) { $errmsgno=$ERRTAG2; }
          else {
            $TagFound = $wsdl.getEntityByID($TagFoundID);
            $msg = 'Creation of tag done. TAG=' + $TagFound.name + ' in the group ' + $data["taggroup"] + ' with properties=' + $TagFound.properties;
            sendMessages -typmsg "OK" -msg $msg;
          }
          $msgerror = 0;
        } catch {
          $msgerror = $_.Exception.Message;
          $errmsgno=$ERRTAG2;
        }
      }
      if ($errmsgno -ne 0) {
          $msg='Cannot create a new tag '+$data["name"]+'.' + $msgadditional;
          if ($msgerror -ne "") { $msg= $msg + ' ('+$msgerror+')'; }
          sendMessages -typmsg "ERROR" -msg $msg;
      }
      # LINK the TAG to objects
      if ($errmsgno -eq 0) {
        # link the object
        if ($data.containsKey('CONFIG-NAME')) {
          $cfgname = $data['CONFIG-NAME'];
          $cfgid= searchConfiguration -wsdl $wsdl -configname $data['CONFIG-NAME'];
        }
        if ($cfgid -eq 0) {
          $e = showError -code $ERRTAG4 -fields $parent+';'+$cfgname+';'+$cfgname;
        } else {
         #search if parent exists
         if (($data.containsKey($parentobject) -eq 1) -and ($data[$parentobject] -ne "")) {
          $parentstring = $data[$parentobject];
          $parentlist = $parentstring.split(';');
          foreach ($parent in $parentlist) {
            $parentObjectFound = @{id=0;};
            try {
              switch ($parenttype.toLower()) {
                 "ip4network"   { $a=$parent.split('/'); $parentObjectFound =$wsdl.getIPRangedByIP($cfgid,'IP4Network',$a[0]); }
                 "ip4address"   { $parentObjectFound = $wsdl.getIP4address($cfgid,$parent);}
                 "ip4block"     { $a=$parent.split('/'); $parentObjectFound = $wsdl.getIPRangedByIP($cfgid,'IP4Block',$a[0]); }
                 default { }
              }
            } catch {
              $msgerror = $_.Exception.Message;
              $errmsgno=$ERRTAG3;
            }
            if ($errmsgno -eq 0) {
              $msg ='Parent ' + $parent + ' of typ ' + $parenttype + ' found in configuration ' + $cfgid + '. ID=' + $parentObjectFound.id + ' NAME=' + $parentObjectFound.name + ' properties=' + $parentObjectFound.properties;
	          sendMessages -typmsg "DEBUG" -msg $msg;
            } else {
              $msg ='Not found parent ' + $parent + ' of typ ' + $parenttype +' in configuration ' + $cfgid +'. error='+$msgerror;
              sendMessages -typmsg "ERROR" -msg $msg;
            }
	        if ( ($errmsgno -eq 0) -and ($parentObjectFound.id -ne 0))  {
              #object found ... possible to link
              $ltags = $wsdl.getlinkedEntities($parentObjectFound.id,"Tag",0,1000);
              if ($ltags.id -contains $TagFound.id) {
                $msg ="The object "+$parentObjectFound.name+' ('+$parentObjectFound.id+') [searched='+$parent+'] has already '+$TagFound.name+' ('+$TagFound.id+') [searched '+$data["name"]+'] as TAG.'
                sendMessages -typmsg "INFO" -msg $msg
              } else {
                try {
                   $result = $wsdl.linkEntities($TagFound.id,$parentObjectFound.id,"")
                } catch {
                   $msgerror = $_.Exception.Message;
                   $errmsgno=$ERRTAG3;
                }
  	            if ( $errmsgno -eq 0 ) {
                   $msg = "Tagging the object "+ $parentObjectFound.name+" with tag "+$data["name"]+" done."
                   sendMessages -typmsg "OK" -msg $msg
                } else {
                   $msg="Cannot link "+$parent+" to the TAG "+$data["name"]+". error="+$msgerror;
                   sendMessages -typmsg "ERROR" -msg $msg;
                }
              }
            } else {
              #impossible to link if not exist
              $e = showError -code $ERRTAG4 -fields $parent+';'+$cfgname+';'+$data["name"];
            }
           }
        }
       }
      }
   } else {
      $para = $data["taggroup"]+';'+$data["name"]+';'+$msgerror;
      $e = showError -code $ERRTAG1 -fields $para;
   }
}

##############################################
# modify Tag
# input:
#   @wsdl   WSDL proxyobject
#   @cfgid  ID of configuration
#   @data   data to add
# return:
#   @none
##############################################
function modifyTags($wsdl, $cfgid,$data,$fields) {
   $cfgname = $cfgid;
   $errmsgno=0;
   try {
     $taggroupFound = $wsdl.getEntityByName(0,$data["taggroup"],"TagGroup");
     $msgerror= "";
   } catch {
     $errmsgno=$ERRTAG1;
     $msgerror= $_.Exception.Message;
   }
   if (($errmsgno -eq 0) -and ($taggroupFound -ne $null) -and ($taggroupFound.id -ne 0) -and ($data["taggroup"] -eq $taggroupFound.name) ) {
      # search the parent object
      $parentobject ="";
      $parenttag = "";
      $parenttype= 'IP4Network';
      $listpossibleparent = 'cidr,ip4network:cidr,ip4address,ip4address:ip,ip4block:cidr';
      foreach ($fieldn in $global:aFieldsTag) {              
           $ti = $fieldn.ToLower();
           if  ($listpossibleparent.Contains($ti) ) {
              $parentobject = $fieldn;
              switch ($ti) {
                 "cidr"              { $parenttag = 'cidr'; $parenttype= 'IP4Network';}
                 "ip4network:cidr"   { $parenttag ='cidr'; $parenttype= 'IP4Network';}
                 "ip4address"        { $parenttag = 'IP4Address';  $parenttype= 'IP4Address';}
                 "ip4address:ip"     { $parenttag = 'IP4Address';  $parenttype= 'IP4Address';}
                 "ip4block:cidr"     { $parenttag = 'cidr';$parenttype= 'IP4Block';}
                 default { }
              }
           }
      }
      # does exist the tag
      $msg="Tag group "+$data["taggroup"]+" exists (id="+$taggroupFound.id+")";
      sendMessages -typmsg "DEBUG" -msg $msg;
      try {
        $TagFound = $wsdl.getEntityByName($taggroupFound.id,$data["name"],"Tag");
        $msgerror= "";
      } catch {
        $errmsgno=$ERRTAG1;
        $msgerror= $_.Exception.Message;
      }
      if ( $data["name"] -ne $TagFound.name ) {
        $msg= 'Tag ' + $data["name"] + ' does not exist! Create it before.';
        if ($msgerror -ne "") {
           $msg= $msg + " ("+$msgerror+")";
        }
        sendMessages -typmsg "DEBUG" -msg $msg;
      } else {
        # change porperties
        $propertiesnb = 0;
        $properties = "";
        $tmpprop= $TagFound.properties;
        if ($parentobject -eq '' ) { $listexcludedfields= 'id,name,taggroup,config-name'; }
        else { $listexcludedfields= 'id,name,taggroup,config-name'+','+$parentobject.ToLower(); }
        foreach ($fieldn in $global:aFieldsTag) {
          $ti = $fieldn.ToLower();
          if  ( -not ($listexcludedfields.Contains($ti) ) ) {
            switch -wildcard ($ti) {
               "title*" { }
               default {
                  if ($data.containsKey($ti)) { $new = $data[$ti]; }
                  else { $new=""; }
                  if ($new -ne "") {
                    $tmpprop= $TagFound.properties;
                    if (!$tmpprop.Contains($fieldn + '='+$new+'|')) {
                       $propertiesnb=1;
                       if ( $tmpprop.contains($fieldn+"=")) {
                         $a= $fieldn + "="+$new;
                         $deb=$tmpprop.IndexOf($fieldn+"=");
                         $lg=$tmpprop.IndexOf('|',$deb)-$deb; 
                         $b=$tmpprop.Substring($deb,$lg);
                         $tmpprop = $tmpprop.replace($b,$a);
                         $TagFound.properties= $tmpprop;
                       } else {
                        $tmpprop = $tmpprop + $fieldn + '='+ $new + '|';
                        $TagFound.properties= $tmpprop;
                       }
                    }
                  }
                }
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
           $msg="Verifying tag's changes ID="+$TagFound2.id+" name="+$TagFound2.name+" properties="+$TagFound2.properties;
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
        # LINK the TAG to objects
       if ($errmsgno -eq 0) {
        # link the object
        if (($data.containsKey($parentobject) -eq 1) -and ($data[$parentobject] -ne "")) {
          $parentstring = $data[$parentobject];
          $parentlist = $parentstring.split(';');
          foreach ($parent in $parentlist) {
            $parentObjectFound = @{id=0;};
            try {
              switch ($parenttype.ToLower()) {
                 "ip4network"        { $a=$parent.split('/'); $parentObjectFound =$wsdl.getIPRangedByIP($cfgid,'IP4Network',$a[0]); }
                 "ip4address"        { $parentObjectFound = $wsdl.getIP4address($cfgid,$parent);}
                 "ip4block"     { $a=$parent.split('/');$parentObjectFound = $wsdl.getIPRangedByIP($cfgid,'IP4Block',$a[0]); }
                 default { }
              }
            } catch {
              $msgerror = $_.Exception.Message;
              $errmsgno=$ERRTAG3;
            }
            if ($errmsgno -eq 0) {
              $msg ='Parent ' + $parent + ' of typ ' + $parenttype + ' found in config=' + $cfgid + '. ID=' + $parentObjectFound.id + ' NAME=' + $parentObjectFound.name + ' properties=' + $parentObjectFound.properties;
	          sendMessages -typmsg "DEBUG" -msg $msg;
            } else {
              $msg ='Not found parent ' + $parent + ' of typ ' + $parenttype +". error="+$msgerror;
              sendMessages -typmsg "ERROR" -msg $msg;
            }
	        if ( ($errmsgno -eq 0) -and ($parentObjectFound.id -ne 0))  {
              #object found ... possible to link
              $ltags = $wsdl.getlinkedEntities($parentObjectFound.id,"Tag",0,1000);
              if ($ltags.id -contains $TagFound.id) {
                $msg ="The object "+$parentObjectFound.name+' ('+$parentObjectFound.id+') [searched='+$parent+'] has already '+$TagFound.name+' ('+$TagFound.id+') [searched '+$data["name"]+'] as TAG.'
                sendMessages -typmsg "INFO" -msg $msg
              } else {
                try {
                   $result = $wsdl.linkEntities($TagFound.id,$parentObjectFound.id,"")
                } catch {
                   $msgerror = $_.Exception.Message;
                   $errmsgno=$ERRTAG3;
                }
  	            if ( $errmsgno -eq 0 ) {
                   $msg = "Tagging the object "+ $parentObjectFound.name+" with tag "+$data["name"]+" done."
                   sendMessages -typmsg "OK" -msg $msg
                } else {
                   $msg="Cannot link "+$parent+" to the TAG "+$data["name"]+". error="+$msgerror;
                   sendMessages -typmsg "ERROR" -msg $msg;
                }
              }
            } else {
              #impossible to link if not exist
              $msg = "Cannot find the object="+$parent+" for the tag "+$data["name"]+". Cannot be linked.";
              sendMessages -typmsg "ERROR" -msg $msg
            }
          }
        }
       }
      }
   } else {
      $errmsgno=$ERRTAG1;
      $msg="Tag group "+$data["taggroup"]+" doesn't exist. Cannot add objet "+$data["name"]+". error="+$msgerror;
      sendMessages -typmsg "ERROR" -msg $msg;
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
function searchSubnet($wsdl, $data) {
   if ($global:nFieldsSearchSub.containsKey('cidr')) {
     $idx= ''+$global:nFieldsSearchSub['cidr']
     $subn= $data[$idx];
   } else {
     $subn = 'missing';
   }
   if ($global:nFieldsSearchSub.containsKey('configuration')) {
     $idx= ''+$global:nFieldsSearchSub['configuration'];
     $cfgname= $data[$idx];
     if (-not ($data.containsKey($idx))) { $cfgname ='all';}
     else { $cfgname= $data[$idx]; }
   } else {
     $cfgname = 'all';
   }
   $ipa = $subn.split('/');
   $ip = $ipa[0];
   $msg= 'search subnet ' + $subn + ' for configuration ' + $cfgname + ' where ip=' + $ip;
   sendMessages -typmsg "INFO" -msg $msg;
   $msgerror= "";
   $cfglist = @();
   if ($cfgname -eq 'all') {
     try {
       $cfglist = $wsdl.getEntities(0,"Configuration",0,50);
     } catch {
       $msgerror= $_.Exception.Message;
     }
   } else {
     try {
       $configFound = $wsdl.getEntityByName("0",$cfgname,"Configuration");
       if ($configFound.id -eq 0) {
         $msgerror= 'config not found';
       } else {
         $cfglist += $configFound;
       }
     } catch {
       $msgerror= $_.Exception.Message;
     }
   }
   if ($msgerror -ne '' ) {
       if ($cfgname -eq 'all') { $msg1= ' no configuration found.';}
       else { $msg1 = $cfgname + ' not found.'; }
       $msg = "Error " + $msg1 + " Error="+$msgerror;
       sendMessages -typmsg "ERROR" -msg $msg;
   }
   $nosubfound = 1;
   foreach ($configFound in $cfglist) {
     try {
       $subnetFound = $wsdl.getIPRangedByIP($configFound.id,"IP4Network",$ip);
       $msg = 'found subnet NAME='+$subnetFound.name+' ID='+$subnetFound.id+' properties='+$subnetFound.properties;
       sendMessages -typmsg "DEBUG" -msg $msg;
     } catch {
       $msg = 'Error in searching subnet '+$subn+' in configuration '+$configFound.Name+'. ' + $_.Exception.Message;
       sendMessages -typmsg "ERROR" -msg $msg;
     }
     if (($subnetFound -eq $null) -or ($subnetFound.id -eq 0 )) {
        continue;
     } else {
       $nosubfound = 0;
       $properties= $subnetFound.properties;
       $tprop=$properties.split('|');
       $result = @{};
       foreach ($a in $tprop) {
          $b=$a.split('=');
          $result.Add($b[0],$b[1]);
       }
       $result.Add('id',$subnetFound.id);
       $result.Add('name',$subnetFound.Name);
       $result.Add('configuration',$configFound.Name);
       $msgtitle = '';
       $msgvalues = '';
       $listexcludedfields= '';
       foreach ($fieldn in $global:aFieldsSearchSub) {
          $ti = $fieldn.ToLower();
          if  (-not (($listexcludedfields.Contains($ti) -or $ti.Contains('title'))) ) {
              #properties fields
              if ($result.containsKey($ti)) {
                  $val = $result[$ti];
                }
                else { $val=""; }
                if ($msgtitle -eq '') {
                  $msgtitle = $ti;
                } else {
                  $msgtitle = $msgtitle+','+ $ti;
                }
                if ($msgvalues -eq '') {
                  $msgvalues = $val;
                } else {
                  $msgvalues = $msgvalues+','+ $val;
                }
              }
       }
       $msg = $msgvalues; 
       sendMessages -typmsg "NORMAL" -msg $msg -out $global:isoutput;
     }
   }
   if ($nosubfound -eq 1) {
       if ($cfgname -eq 'all') {  $msg1= 'none of the configurations'; }
       else { $msg1 = 'configuration '+$cfgname; }
       $msg = 'The Subnet '+$subn+' not found in '+$msg1+'.';
       sendMessages -typmsg "ERROR" -msg $msg;
   }
}

##############################################
# simple get n objects
# input:
#   @wsdl     WSDL proxyobject
#   @cfgname  name configuration
#   @parentid ID of parent
#   @type     object's type
#   @objects  objects'list 
# return:
#   @err  error
##############################################
function getObjects($wsdl, $filter, $cfgname, $parentid, $type, [ref] $objects ) {
   $lobjects = @();
   $err =0;
   $maxpersession  =2;
   $beg=0;$nbr=0;
   if ($parentid -gt 0) {
     for ($still=1;$still -eq 1;) {
      try {
        $listObjectsFound = $wsdl.getEntities($parentid,$type,$beg,$maxpersession);
        if ($listObjectsFound) {
          $nbr = $listObjectsFound.count;
          $nbr2= $nbr;
          if ($filter -ne '') {
            $filter1 = $filter.replace('/','');
            foreach ($obj in $listObjectsFound) {
              if ($obj.name -match $filter1) {
                $lobjects += $obj;
                $nbr2 = $nbr2 +1;
              }
            }
          } else {
            $lobjects += $listObjectsFound;
          }
        } else { $nbr = 0; }
        if ($filter -ne '') { $msg1 = 'like '+$filter+' '; }
        else { $msg1 = ''; }
        $msg = 'searching the objects '+$msg1+'of type '+$type+ ' in configuration '+$cfgname + ' for parent id '+ $parentid +'. Getting from '+$beg+'.'+' Found '+$nbr2+'.';
        sendMessages -typmsg "DEBUG" -msg $msg;
      } catch {
        $err=1;
        $msgerror= $_.Exception.Message;
        if ($msgerror -ne '' ) { $msg2 = ' Error='+$msgerror; }
        else { $msg2 =''; }
        $msg = 'Error by ' + 'searching the objects of type '+$type+ ' in configuration '+$cfgname + ' for parent id '+ $parentid +'. Getting from '+$beg +'.'+$msg2;
        sendMessages -typmsg "ERROR" -msg $msg;
        $still = 0;
      }
      $beg = $beg +$nbr;
      if ( (!$listObjectsFound) -or ($nbr -lt $maxpersession)) {
        $still = 0;
      }
     }
   }
   $objects.value = $lobjects;
   return $err;
}

##############################################
# list Devices if name empty means all devices
# input:
#   @wsdl   WSDL proxyobject
#   @cfgid  ID of configuration
#   @data   data to search
# return:
#   @none
##############################################
function listDevices($wsdl, $cfgid, $data) {
   if ($global:nFieldsListDevices.containsKey('filter')) {
     $idx= ''+$global:nFieldsListDevices['filter']
     $filter= $data[$idx];
   } else {
     $filter = '';
   }
   if ($global:nFieldsListDevices.containsKey('configuration')) {
     $idx= ''+$global:nFieldsListDevices['configuration'];
     if (-not ($data.containsKey($idx))) { $cfgname ='all';}
     else { $cfgname= $data[$idx]; }
     if ($cfgname -eq '') { $cfgname ='all';}
   } else {
     $cfgname = 'all';
   }
   if ($name -eq '') { $msg1= 'any devices';}
   else { $msg1 = 'device "'+$name + '"'; }
   if ($cfgname -eq 'all') { $msg2= ' in all configuration';}
   else { $msg2 = ' in configuration "'+$cfgname + '"'; }
   $msg= 'searching '+ $msg1 +$msg2;
   sendMessages -typmsg "INFO" -msg $msg;
   $msgerror= "";
   $cfglist = @();
   if ($cfgname -eq 'all') {
     try {
       $cfglist = $wsdl.getEntities(0,"Configuration",0,50);
     } catch {
       $msgerror= $_.Exception.Message;
     }
   } else {
     try {
       $configFound = $wsdl.getEntityByName("0",$cfgname,"Configuration");
       if ($configFound.id -eq 0) {
         $msgerror= 'config not found';
       } else {
         $cfglist += $configFound;
       }
     } catch {
       $msgerror= $_.Exception.Message;
     }
   }
   if ($msgerror -ne '' ) {
       if ($cfgname -eq 'all') { $msg1= ' no configuration found.';}
       else { $msg1 = $cfgname + ' not found.'; }
       $msg = "Error " + $msg1 + " Error="+$msgerror;
       sendMessages -typmsg "ERROR" -msg $msg;
   }
   $nodevicefound = 1;
   foreach ($configFound in $cfglist) {
     $listObjFound = @();
     $err = getObjects -wsdl $wsdl -filter $filter -cfgname $configFound.name -parentid $configFound.id -type 'Device' -objects ([ref] $listObjFound);
     if (($listObjFound -ne $null) -or ($listObjFound.count -gt 0 )) {
       foreach ($obj in $listObjFound) {
          $result = @{};
          $result.Add('configuration',$configFound.Name);
          $properties = $obj.properties;
          $tprop=$properties.split('|');
          foreach ($a in $tprop) {
             $b=$a.split('=');
             $result.Add($b[0],$b[1]);
          }
          $result.Add('id',$obj.id);
          $result.Add('name',$obj.name);
          $result.Add('filter',$filter);
          $result.Add('type',$obj.type);
          $msgtitle = '';
          $msgvalues = '';
          $listexcludedfields= '';
          foreach ($fieldn in $global:aFieldsListDevices) {
            $ti = $fieldn.ToLower();
            if  (-not (($listexcludedfields.Contains($ti) -or $ti.Contains('title'))) ) {
              #properties fields
              if (($result.containsKey($ti)) -or ($ti -eq 'devicetype' -and $result.containsKey('devicetypeid'))) {
                  if ($ti -eq 'devicetype' -and $result.containsKey('devicetypeid')) {
                    $typeFound = $wsdl.getEntityById($result['devicetypeid']);
                    $val = $typeFound.name;
                  } else { 
                    $val = $result[$ti];
                  }
                  $val = $val.replace(',',';');
                }
                else { $val=""; }
                #if ($msgtitle -eq '') { $msgtitle = $ti; }
                #else { $msgtitle = $msgtitle+','+ $ti;}
                if ($msgvalues -eq '') {
                  $msgvalues = $val;
                } else {
                  $msgvalues = $msgvalues+','+ $val;
                }
              }
          }
          $msg = $msgvalues; 
          sendMessages -typmsg "NORMAL" -msg $msg -out $global:isoutput;
       }
     }
   }
}

##############################################
# list IPs by CIDR
# input:
#   @wsdl   WSDL proxyobject
#   @cfgid  ID of configuration
#   @data   data to search
# return:
#   @listIP in output
##############################################
function listIPs($wsdl, $cfgid, $data) {
   if ($global:nFieldsListIPs.containsKey('cidr')) {
     $idx= ''+$global:nFieldsListIPs['cidr']
     $subn= $data[$idx];
   } else {
     $subn = 'missing';
   }
   if ($global:nFieldsListIPs.containsKey('configuration')) {
     $idx= ''+$global:nFieldsListIPs['configuration'];
     if (-not ($data.containsKey($idx))) { $cfgname ='all';}
     else { $cfgname= $data[$idx]; }
     if ($cfgname -eq '') { $cfgname ='all';}
   } else {
     $cfgname = 'all';
   }
   $ipa = $subn.split('/');
   $ip = $ipa[0];
   if ($cfgname -eq 'all') { $msg1= ' in all configuration';}
   else { $msg1 = 'in configuration "'+$cfgname + '"'; }
   $msg= 'searching IPs in subnet ' + $subn + ' ' +$msg1+ ' where ip=' + $ip;
   sendMessages -typmsg "INFO" -msg $msg;
   $msgerror= "";
   $cfglist = @();
   if ($cfgname -eq 'all') {
     try {
       $cfglist = $wsdl.getEntities(0,"Configuration",0,50);
     } catch {
       $msgerror= $_.Exception.Message;
     }
   } else {
     try {
       $configFound = $wsdl.getEntityByName("0",$cfgname,"Configuration");
       if ($configFound.id -eq 0) {
         $msgerror= 'config not found';
       } else {
         $cfglist += $configFound;
       }
     } catch {
       $msgerror= $_.Exception.Message;
     }
   }
   if ($msgerror -ne '' ) {
       if ($cfgname -eq 'all') { $msg1= ' no configuration found.';}
       else { $msg1 = $cfgname + ' not found.'; }
       $msg = "Error " + $msg1 + " Error="+$msgerror;
       sendMessages -typmsg "ERROR" -msg $msg;
   }
   $nosubfound = 1;
   foreach ($configFound in $cfglist) {
     try {
       $subnetFound = $wsdl.getIPRangedByIP($configFound.id,"IP4Network",$ip);
       $msg = 'found subnet NAME='+$subnetFound.name+' ID='+$subnetFound.id+' properties='+$subnetFound.properties;
       sendMessages -typmsg "DEBUG" -msg $msg;
     } catch {
       $msg = 'Error in searching subnet '+$subn+'. ' + $_.Exception.Message;
       sendMessages -typmsg "ERROR" -msg $msg;
     }
     if (($subnetFound -eq $null) -or ($subnetFound.id -eq 0 )) {
        continue;
     } else {
       $nosubfound = 0;
       $properties= $subnetFound.properties;
       $listIPFound = $wsdl.getNetworklinkedProperties($subnetFound.id);
       foreach ($oneip in $listIPFound) {
          $result = @{};
          $result.Add('cidr',$subn);
          $result.Add('configuration',$configFound.Name);
          $properties = $oneip.properties;
          $tprop=$properties.split('|');
          foreach ($a in $tprop) {
             $b=$a.split('=');
             $result.Add($b[0],$b[1]);
          }
          $result.Add('id',$oneip.id);
          $result.Add('name',$oneip.name);
          $result.Add('type',$oneip.type);
          if ($result.containsKey('address')) {
             $result.Add('ip',$result['address']);
             $result.Add('ipv4address',$result['address']);
          }
          $msgtitle = '';
          $msgvalues = '';
          $listexcludedfields= '';
          foreach ($fieldn in $global:aFieldsListIPs) {
            $ti = $fieldn.ToLower();
            if  (-not (($listexcludedfields.Contains($ti) -or $ti.Contains('title'))) ) {
              #properties fields
              if ($result.containsKey($ti)) {
                  $val = $result[$ti];
                }
                else { $val=""; }
                #if ($msgtitle -eq '') { $msgtitle = $ti; }
                #else { $msgtitle = $msgtitle+','+ $ti;}
                if ($msgvalues -eq '') {
                  $msgvalues = $val;
                } else {
                  $msgvalues = $msgvalues+','+ $val;
                }
              }
          }
          $msg = $msgvalues; 
          sendMessages -typmsg "NORMAL" -msg $msg -out $global:isoutput;
       }
     }
   }
   if ($nosubfound -eq 1) {
       $msg = 'The Subnet '+$subn+' not found.';
       sendMessages -typmsg "ERROR" -msg $msg;
   }
}

##############################################
# add comment in output
# input:
#   @wsdl   WSDL proxyobject
#   @cfgid  ID of configuration
#   @data   data with comment
# return:
#   @comment in output
##############################################
function addCommentOutput($wsdl, $cfgid, $data) {
  $msg='';
  foreach ($c in $data.Keys) {
   if (($c -ne '0') -and ($c -ne 'action')) {
     if ($msg -eq '') { $msg= $data[$c]; } else { $msg = $msg + ',' + $data[$c]; }
   }
  }
  if ($msg -ne '') { sendMessages -typmsg "NORMAL" -msg $msg -out $global:isoutput; }
}

Set-Variable INIT1   -value '-1' #-option Constant 
Set-Variable INIT2   -value '-2' #-option Constant 
Set-Variable INIT3   -value '-3' #-option Constant 
Set-Variable ERRDEV1    -value '1' #-option Constant 
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
Set-Variable ERRTAG4    -value '24' #-option Constant 
Set-Variable ERRTAG5    -value '25' #-option Constant 
Set-Variable ERRFUNC1   -value '31' #-option Constant 
Set-Variable ERRFUNC2   -value '32' #-option Constant 
Set-Variable ERRFUNC3   -value '33' #-option Constant 
Set-Variable ERRFUNC4   -value '34' #-option Constant 
Set-Variable ERRSUBADDPRO1   -value '41' #-option Constant 
Set-Variable ERRSUBADDPRO2   -value '42' #-option Constant 
Set-Variable ERRSUBADDPRO3   -value '43' #-option Constant 
Set-Variable ERRSUBADDPRO4   -value '44' #-option Constant 
Set-Variable ERRCFG1   -value '100' #-option Constant 
Set-Variable ERRIP1   -value '110' #-option Constant 
Set-Variable ERRIP2   -value '111' #-option Constant 
Set-Variable ERRIP3   -value '112' #-option Constant 
Set-Variable ERRIPDEL1   -value '120' #-option Constant 
Set-Variable ERRIPDEL2   -value '121' #-option Constant 
Set-Variable ERRINIT3   -value '130' #-option Constant 
Set-Variable ERRINIT4   -value '131' #-option Constant 

##############################################
# get the message (exemaple error message
#   in the future the message will be loaded from a error file message
#   the fields will replace the variables #1#, #2#, #3#, .....
# input:
#   @code code error
#   @fields additional fields semi-coloumn separated
# return:
#   @msg error message
##############################################
function getMessage($code,$fields='') {
 $msg='...!';
 #message are temporary local, in future in a file
 $error=@{}
 $error["$ERRFUNC2"]= "No configuration found! Cannot apply other changes";
 $error["$ERRFUNC3"]= "Wrong action! Should be one of these values #1# ! You choose #2#.";
 $error["$ERRFUNC4"]= "No IP-subnetfound.";
 $error["$ERRFUNC1"]= 'file #1# cannot be read or does not exist!';
 $error["$ERRCFG1"] = 'Missing configuration or configuration #1# invalid.';
 $error["$INIT1"] = 'creating Log-file.';
 $error["$INIT2"] = 'Error on logout #1#.';
 $error["$INIT3"] = "Configuration '#1#' found, Configuration ID = #2#";
 $error["$ERRINIT3"] = "Configuration '#1#' not found! #2#";
 $error["$ERRINIT4"] = "Message level '#1#' not in the list of levels '#2#'.";
 $error["$ERRTAG4"] = "Cannot find the parent object=#1# in configuration '#2#' for the tag '#3#'. Cannot do the link!";
 $error["$ERRTAG1"] = "Tag group '#1#' does not exist. Cannot add objet '#2#'.#3#";
 $listfields = $fields.split(';');
 if ($error.containsKey($code)) {
   $msg = $error[$code];
   $i=1;
   foreach ($f in $listfields){
     $msg = $msg.replace('#'+$i+'#',$f);
     $i++;
   }
 } else {
   $msg = $msg + $fields;
 }
 return $msg;
}

##############################################
# show error message
#   the fields will replace the variables #1#, #2#, #3#, .....
# input:
#   @code code error
#   @fields additional fields semi-coloumn separated
# return:
#   @code error code
##############################################
function showError($code,$fields='') {
  $msg= getMessage -code $code -field $fields;
  sendMessages -typmsg "ERROR" -msg $msg;
  return $code;
}

##############################################
# Main function
# input: none
# return: none
##############################################
function main($ip,$isout,$user,$password) {
 sendMessages -typmsg "DEBUG" -msg "---------- BEGIN -------------"
 $errmsgno= 0;
 $userAPI= $user;
 $pwAPI= $password;
 $theInput="";
 $containerFile="";
 $cfgid = 0;
 $cfgname = '';
 $lista= ""; foreach ($a in $listActions) { $lista= $lista+","+$a; }
 if ($global:logoverwrite -eq 'YES') {
     $msg = 'creating Log-file.';
     Write-Output $msg | Out-File $LOG_FILE
 }
 if ($global:outputoverwrite -eq 'YES') {
     $msg = '';
     Write-Output '' | Out-File $OUTPUT_FILE
 }
 getInputs -name ([ref]$userAPI) -pass ([ref]$pwAPI) -ip ([ref]$ip) -out ([ref] $isout);

 if (-not( Test-Path $INPUT_FILE) ) {
    return showError -code $ERRFUNC1 -fields $INPUT_FILE;
	exit;
 }
 $pingnb=0;
 do {
	$ping = new-object system.net.networkinformation.ping;
    try {
      $pingreturns = $ping.Send($proteus);
      $status = $pingreturns.Status;
    } catch {
       $msg ="Error system: Check your IP ${proteus} ... ${status}";
    }
    $pingnb++;
 } until (($Status -eq 'Success') -or ($pingnb -ge 4));
 if ($pingreturns.Status -ne 'Success') {
       $msg ="Cannot ping ${proteus} ... ${status}";
       sendMessages -typmsg "DEBUG" -msg $msg;
       exit;
 } else {
   sendMessages -typmsg 'DEBUG' -msg 'Proteus reachable';
 }
 sendMessages -typmsg 'DEBUG' -msg "initialize .Net";
 $wsdl= initAPI -name $userAPI -pass $pwAPI;
 if (($wsdl -ne $null) -and ($wsdl -ne 0)) {
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
      } else {
        if ($theAction.Contains("CONFIG-NAME")) {
          $cfgname = $thedata["name"];
          $cfgid= initConfiguration -wsdl ([ref] $wsdl) -configname $cfgname;
        } else {
          if (($listReadActions -contains $theAction)) {
            switch ($theAction) {
             "SEARCHSUBNET"   { $e=searchSubnet -wsdl $wsdl["proxy"] -data $thedata; break; }
             "LISTIPS"        { $e=listIPs -wsdl $wsdl["proxy"] -cfgid $cfgid -data $thedata; break; }
             "LISTDEVICES"    { $e=listDevices -wsdl $wsdl["proxy"] -cfgid $cfgid -data $thedata;  break; }
             'COMMENT_OUTPUT' { $e=addCommentOutput -wsdl $wsdl["proxy"] -cfgid $cfgid -data $thedata ; break;}
             default { break; }
            } #end switch
          } else {
            if (($listActions -contains $theAction)) {
              if ( ($theAction.Contains("_DEVICE")) -or ($theAction.Contains("_TAG")) ) {
                switch ($theAction) {
                 "DEL_DEVICE"    { $e=deleteDevice -wsdl $wsdl["proxy"] -cfgid $cfgid -data $thedata -fields $theFields; break; }
                 "ADD_DEVICE"    { $e=addDevice -wsdl $wsdl["proxy"] -cfgid $cfgid -data $thedata; break; }
                 "MODIFY_DEVICE" { $e=modifyDevice -wsdl $wsdl["proxy"] -cfgid $cfgid -data $thedata -fields $theFields; break; }
                 "ADD_TAG"       { $e=addTags -wsdl $wsdl["proxy"] -cfgid $cfgid -data $thedata -fields $theFields; break; }
                 "MODIFY_TAG"    { $e=modifyTags -wsdl $wsdl["proxy"] -cfgid $cfgid -data $thedata -fields $theFields; break; }
                 default {
                   $errmsgno=$ERRFUNC2;
                   $msg2= getMessage -code $ERRFUNC2;
                   $msg= $msg2+" "+$thedata["action"];
                   sendMessages -typmsg "ERROR" -msg $msg;
                 }
               } #end switch
             } else {
               if($cfgid -ne 0) {
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
                  $rangeFound = $wsdl["proxy"].getIPRangedByIP($cfgid, "IP4Block",$value)
                  $msg= $tmp + " belongs to block name="+$rangeFound.name + "("+$rangeFound.id+") properties="+$rangeFound.properties;
                  sendMessages -typmsg "INFO" -msg $msg;
                } catch {
                  $msg = 'Error by searching range '+$value+'. ' + $_.Exception.Message;
                  sendMessages -typmsg "ERROR" -msg $msg;
                }
                if (($rangeFound.Type -ne $null) -and ($rangeFound.Id -ne 0) ) {
                   switch ($theAction) {
                    "MODIFY_IP"  { $e= modifyIP -wsdl $wsdl["proxy"] -cfgid $cfgid -range $rangeFound -data $thedata; break; }
                    "ADD_IP"     { $e= addIP -wsdl $wsdl["proxy"] -cfgid $cfgid -range $rangeFound -data $thedata; break; }
                    "DEL_IP"     { $e= deleteIP -wsdl $wsdl["proxy"] -cfgid $cfgid -data $thedata; break; }
                    "ADD_SUBNET" { $e= addSubnet -wsdl $wsdl["proxy"] -cfgid $cfgid -range $rangeFound -data $thedata; break; }
                    "MODIFY_SUBNET" { $e= modifySubnet -wsdl $wsdl["proxy"] -cfgid $cfgid -range $rangeFound -data $thedata; break; }
                    default {
                      $msg= getMessage -code $ERRFUNC3 -fields "${lista};${theAction}";
                      sendMessages -typmsg 'ERROR' -msg $msg;
                    }
                   } #end switch
                } else {
                  return showError -code $ERRFUNC4 -fields " ${theAction}";
                }
               } else {
                 return showError -code $ERRCFG1 -fields "${cfgname}";
               }
             }
            } else {
              $msg= getMessage -code $ERRFUNC3 -fields "${lista};${theAction}";
              sendMessages -typmsg 'ERROR' -msg $msg;
            }
          }
       }
      }
    } 
   }
   try {
     $wsdl['proxy'].logout();
   } catch {
     $msg= getMessage -code $INIT2 -fields "Proteus ${proteus}";
     sendMessages -typmsg "ERROR" -msg $msg
   }
 }
 sendMessages -typmsg 'DEBUG' -msg '------------- END ------------';
}
if ($help) { showHelp -path $PSScriptRoot; }
if ($commands) { $INPUT_FILE = $commands; }
if ($output) { $OUTPUT_FILE = $output; $global:isoutput = 'YES'; $isout = 'YES'; } else { $isout = ''; }
if ($ip) { $global:proteus = $ip;} else { $ip ='';}
if (!$user) { $user ='';}
if (!$password) { $password ='';}
if ($level) {
   $levels = getLevelParam;
   $list='';
   foreach ($ky in $levels.Keys) {
      if ($list -eq '') { $list=$ky;} else { $list = $list + ',' + $ky;}
   }
   if ($list.Contains($level.ToUpper())) {
      $global:ERROR_LEVEL = $level.ToUpper();
   } else { 
      $msg2 = $level+';'+$list;
      $msg= getMessage -code $ERRINIT4 -fields $msg2;
      sendMessages -typmsg 'INFO' -msg $msg;
   }
}

main -ip $ip -isout $isout -user $user -password $password;
exit;
