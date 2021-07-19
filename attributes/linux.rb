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

case node['platform']
when 'redhat'
  # tscm native installer file
  default['tscm']['base_package'] = 'installer-tscmclient-linux64exp.tar'
  # input for ssh connection
  default['tscm']['ssh_input'] = 'yes'
  # tscm proxy server ip-address
  default['tscm']['proxy_server'] = '10.0.0.1'
  # tscm proxy server user
  default['tscm']['proxy_user'] = 'scm_auto_usr'
  # tscm proxy server password
  default['tscm']['proxy_password'] = 'password'
  # operation type for registering the tscm client with server
  default['tscm']['register_ot'] = 'reg'
  # operation type for un-registering/deleting the tscm client from server
  default['tscm']['unregister_ot'] = 'del'
  # operation type for performing healthcheck on the tscm client
  default['tscm']['hc_ot'] = 'col'
  # operation type for generating reports on tscm server
  default['tscm']['report_ot'] = 'rep'
  # operating system type
  default['tscm']['OS_type'] = 'linux'
  # location of tscm wrapper script on the tscm server
  default['tscm']['wrapper_script'] = 'C:\\TSCM_Automation\\TSCM_wrapper.ps1'
  # tscm client fqdn
  default['tscm']['node_name'] = node['hostname'] + '.client.com'
  # ssh key for authentication with proxy server
  default['tscm']['key'] = '/opt/IBM/SCM_id_rsa'
  default['tscm']['key_name'] = 'SCM_id_rsa'
  # tscm client service_name
  default['tscm']['service_name'] = 'IBMSCMclient'
  # location of client.pref configuration file to change logging level
  default['tscm']['client_pref'] = '/opt/IBM/SCM/client/client.pref'
  # temporary directory for downloading tscm binaries
  default['tscm']['temp_dir'] = '/opt/IBM/tscm_temp'
  # webserver url for downloading the tscm binary
  default['tscm']['url'] = 'https://pulp.client.com/ibm/redhat7/tscm/installer-tscmclient-linux64exp.tar'
  # default['tscm']['remote_dir'] = "C:\\Users\\tscmuser\\Desktop\\Tools\\SCM Automation deployment\\External file to drop on CHEF clients"
  # location for downloading audit patching file
  default['tscm']['patch_dir'] = '/opt/IBM/SCM/client/software/completed'
  # tscm client ip-address for executing operations
  default['tscm']['node_IP'] = node['ipaddress']
  # audit patching file location on remote server
  default['tscm']['audit_path'] = '/C:/Program Files/IBM/SCM/client/software/completed/lssec_secfixdb_all.tar.gz'
  # installation directory of tscm client
  default['tscm']['installed_dir'] = '/opt/IBM/SCM/client/'
  # path for downloading the reports
  default['tscm']['download_path'] = '/opt/IBM/SCM/client/'
  # location of powershell script to run on server
  default['tscm']['copy_script_path'] = '/opt/IBM/copy_script.ps1'
  # location of audit patching file after download
  default['tscm']['audit_file'] = '/opt/IBM/SCM/client/software/completed/lssec_secfixdb_all.tar.gz'
  # registration output
  default['tscm']['reg_output'] = ''
  default['tscm']['volumegroup'] = 'ibmvg'
  default['tscm']['logvols'] = [
  {
    'volname' => 'lv_scm',
    'size' => '500M',
    'mountpoint' => '/opt/IBM/SCM',
    'fstype' => 'xfs',
  }
 ]

when 'aix'
  # tscm native installer file
  default['tscm']['base_package'] = 'installer-tscmclient-aix6.tar'

  # webserver url for downloading the tscm binary
  default['tscm']['url'] = 'https://pulp.client.com/ibm/aix7/tscm/installer-tscmclient-aix6.tar'

  # package name of aix installer
  default['tscm']['package_name'] = ''

  # installation directory of tscm client
  default['tscm']['installed_dir'] = '/opt/IBM/SCM/client/'

  # tscm client fqdn
  default['tscm']['node_name'] = node['hostname'] + '.client.com'

  # tscm proxy server ip-address
  default['tscm']['proxy_server'] = '10.0.0.1'

  # tscm proxy server user
  default['tscm']['proxy_user'] = 'scm_auto_usr'

  # tscm proxy server password
  default['tscm']['proxy_password'] = 'password'

  # operation type for registering the tscm client with server
  default['tscm']['register_ot'] = 'reg'

  # operation type for un-registering/deleting the tscm client from server
  default['tscm']['unregister_ot'] = 'del'

  # operation type for performing healthcheck on the tscm client
  default['tscm']['hc_ot'] = 'col'

  # operation type for generating reports on tscm server
  default['tscm']['report_ot'] = 'rep'

  # operating system type
  default['tscm']['OS_type'] = 'aix'

  # location of tscm wrapper script on the tscm server
  default['tscm']['wrapper_script'] = 'C:\\TSCM_Automation\\TSCM_wrapper.ps1'

  # ssh key for authentication with proxy server
  default['tscm']['key'] = '/opt/IBM/SCM_id_rsa'
  default['tscm']['key_name'] = 'SCM_id_rsa'

  # tscm client service_name
  default['tscm']['service_name'] = 'IBMSCMclient'

  # location of client.pref configuration file to change logging level
  default['tscm']['client_pref'] = '/opt/IBM/SCM/client/client.pref'

  # location for downloading audit patching file
  default['tscm']['patch_dir'] = '/opt/IBM/SCM/client/software/completed'

  # tscm client ip-address for executing operations
  default['tscm']['node_IP'] = node['ipaddress']

  # audit patching file location on remote server
  default['tscm']['audit_path'] = '/C:/Program Files/IBM/SCM/client/software/completed/lssec_secfixdb_all.tar.gz'

  # path for downloading the reports
  default['tscm']['download_path'] = '/opt/IBM/SCM/client/'

  # location of powershell script to run on server
  default['tscm']['copy_script_path'] = '/opt/IBM/copy_script.ps1'

  # location of audit patching file after download
  default['tscm']['audit_file'] = '/opt/IBM/SCM/client/software/completed/lssec_secfixdb_all.tar.gz'

end
