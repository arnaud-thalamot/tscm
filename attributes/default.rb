########################################################################################################################
#                                                                                                                      #
#                                     TSCM attribute for TSCM Cookbook                                                 #
#                                                                                                                      #
#   Language            : Chef/Ruby                                                                                    #
#   Date                : 23.11.2016                                                                                   #
#   Date Last Update    : 23.11.2016                                                                                   #
#   Version             : 0.1                                                                                          #
#   Author              : Arnaud THALAMOT                                                                              #
#                                                                                                                      #
########################################################################################################################

# TSCM cookbook execution status
 default['tscm']['status'] = 'failure'

case platform
when 'windows'
  # tscm installer native file
  default['tscm']['TSCMfile'] = 'installer-tscmclient-win2k12.zip'
  # Remote location for TSM setup file
  default['tscm']['TSCMfile_Path'] = 'https://client.com/ibm/windows2012R2/tscm/installer-tscmclient-win2k12.zip'
  # tscm wsusscn2.cab native file
  default['tscm']['TSCMConffile'] = 'wsusscn2.cab'
  # Temp file where we copy the tscm installer
  default['tscm']['temp'] = 'C:\\tscm_temp'
  # Installed file for tscm agent
  default['tscm']['alreadyInstalledFile'] = 'C:\\Program Files\\IBM\\SCM\\bin'
  # location to store the report on the node
  default['tscm']['reportcopy_path'] = 'C:\\PROGRA~1\\IBM\\SCM\\client'
  # Path for tscm installation
  default['tcsm']['install_path'] = 'C:\\tscm_software'
  # The hostname of the machine
  default['tscm']['hostname'] = node['hostname'].downcase
  # The OS name of the machine
  default['tscm']['osname'] = node['platform'].downcase
  # The IP address of the machine
  default['tscm']['ipaddress'] = node['ipaddress']
  # Path for the client.pref file
  default['tscm']['clientConfFile'] = 'C:\\Program Files\\IBM\\SCM\\client\\client.pref'
  # Path for the client.id file
  default['tscm']['clientIDFile'] = 'C:\\Program Files\\IBM\\SCM\\client\\client.id'
  # Path for the 'completed' folder where we can copy the file from TSCM server
  default['tscm']['patchAuditingPath'] = 'C:\\Program Files\\IBM\\SCM\\client\\software\\completed'
  # Service Name
  default['tscm']['serviceName'] = 'jacservice'
  # TSCM server details
  default['tscm']['TSCMProxy_server'] = '10.0.0.1'
  default['tscm']['TSCMProxy_user'] = 'scm_auto_usr'
  # tscm proxy key
  default['tscm']['native_proxykey'] = 'SCM_id_rsa'
  # script to copy file
  default['tscm']['native_ScriptFile'] = 'CopyScript.ps1'
  # Path of reports stored on the sever
  default['tscm']['reports_path'] = 'C:\\TSCM_Automation\\Reports'
  # copy script location on the server
  default['tscm']['copyScript_path'] = 'C:\\Users\\scm_auto_usr'
  # TSCM Wrapper scipt path on the server
  default['tscm']['tscmWrapper_path'] = 'C:\\TSCM_Automation\\TSCM_wrapper.ps1'
  # TSCM deregister log file
  default['tscm']['deregister_log'] = 'C:\\deregister_tscm.log'
  # TSCM register log file
  default['tscm']['register_log'] = 'C:\\register_tscm.txt'
  # TSCM health Check log file
  default['tscm']['healthCheck_log'] = 'C:/healthCheck_tscm.txt'
  # TSCM report check log file
  default['tscm']['report_log'] = 'C:\\report_tscm.txt'
end
