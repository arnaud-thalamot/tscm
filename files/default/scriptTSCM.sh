#!/bin/bash                                              
set -x
# Parameters
opType=$1
vmHostname=$2
vmPlatform=$3
vmIPAddress=$4

# Script variables
certFile=/tmp/SCM_id_rsa
logPath=/home/masterico
logFile=scriptTSCM.log

#################
F_LOG()
#################
{
	echo -e "\n$(date +"%d/%m/%Y %H:%M:%S") $1\c" |tee -a ${logPath}/${logFile}
}

#################
F_EXEC()
#################
{
    echo -e "$(date +"%d/%m/%Y %H:%M:%S") [EXEC] $1" >> ${logPath}/${logFile}
    $1 1>> ${logPath}/${logFile} 2>&1
}

# MAIN
F_LOG "[INFO] TSCM local script startup"
cd /home/masterico

F_EXEC "/usr/bin/ssh -o StrictHostKeyChecking=no -i ${certFile} scm_auto_usr@10.0.146.37 \"powershell C:\TSCM_Automation\TSCM_wrapper.ps1 ${opType} ${vmHostname} ${vmPlatform} ${vmIPAddress}\""

F_LOG "[INFO] TSCM local script end"