TSCM Cookbook

The tscm cookbook will perform silent installation of tscm agent on the node and register the node on TSM server and does healthcheck of the node & generates the reports which stores on the tscm server side.

Requirements

- Storage : 2 GB
- RAM : 2 GB
- Versions
  - Chef Development Kit Version: 0.17.17
  - Chef-client version: 12.13.37
  - Kitchen version: 1.11.1
- Openssh should be installed before execution of this cookbook to establish ssh connection with tscm server.

Platforms

    RHEL-7/Winodws 2012

Chef

    Chef 11+

Cookbooks

    none

Resources/Providers

- tscmagent
  This tscmagent resource/provider performs the following :-
  
  For Winodws Platform:
  1. Creates necessary directories for 
     - copying the tscm agent installer
  2. Extracting the tscm installer to fetch the required setup file for installation
  3. Install the tscm from temporary directory.
  4. Register the node for TSCM agent.
  5. health check of the node.
  6. Generates the report of healthcheck of node, stores on the server
  7. Delete the temporary directory containing the files used during installation.
  8. uninstall the tscm agent.

Example

1. tscmagent 'install-tscm-agent' do
  action :install, :register, :health_check, :report
end   

Actions

    :install - installs and configures the TSCM agent
    :Register - Register the node for TSCM server.
    :health_check - does health check of the node
    :report - generates the reports and stores on the tscm server

Recipes
  - install_tscm_win:: The recipe installs the required version of tsmcagent for windows platform,register the node for TSCM server,it does health check of the node
                       and generates the reports and stores on the tscm server
  - deregister_tscm:: The recipe deregister the node from the tscm server


- tscminstall
  This resource/provider configures following :-
  
  For RHEL7 platform:
  1.  Creates temporary directory for storing the TSCM installer.
  2.  Downloads and extracts the TSCM native binaries to fetch the installation script.
  3.  Run the installation script ./install.sh to install the TSCM client
  4.  Changes the loggin level by changing the configuration parameters in client.pref and restarting the tscm-agent service to reflect changes.
  5.  Downloads the audit patching file to /opt/IBM/SCM/client/software/completed/ in client installed directory
  6.  Performs TSCM client registration with the TSCM server
  7.  Validates the TSCM registration with TSCM server.
  8.  Once validated registration, then it performs healthcheck operation
  9.  After heathcheck operation completes success then it perofrms reporting operation.
  10. DOwnload the reports from remote TSCM server to client.
  11. Change the logging level to info and restart TSCM client service to reflect changes.

Example:

tscm_tscminstall 'insall-tscm' do
  action :install
end

Actions:

  :install - installs TSCM client and performs prerequisites
  :register - registers the TSCM client with server
  :validate - validates the tSCM registration with server
  :healthcheck - performs healthcheck on the TSCM node
  :reports - generates reports on TSCM server for specific TSCM client


Recipes

    install_tscm_win:: The recipe installs the required version of tsmcagent for windows platform,register the node for TSCM server,it does health check of the node
                       and generates the reports and stores on the tscm server

2. tsmagent 'uninstall-tscm-agent' do
  action :uninstall
end   

Actions

    :uninstall - uninstall the tscm agent


Recipes

    uninstall_tscm:: The recipe uninstalls the required version of tscm agent for windows platform.

Attributes

Below attributes are specific to windows platform:

 
default['tscm']['TSCMfile'] = 'installer-tscmclient-win2k12.zip'     # tscm installer native file
default['tscm']['TSCMfile_Path'] = 'https://pulp.cma-cgm.com/ibm/windows2012R2/tscm/installer-tscmclient-win2k12.zip '     # Remote location for TSM setup file
default['tscm']['TSCMConffile'] = 'wsusscn2.cab'     # tscm patch wsusscn2.cab native file
default['tscm']['temp'] = 'C:\\tscm_temp\\'     # Temp file where we copy the tscm installer
defatult['tscm']['alreadyInstalledFile'] = 'C:\\Program Files\\IBM\\SCM\\client'    # Installed file for tscm agent
default['tcsm']['install_path'] = 'C:\\tscm_software'     # Path for tscm installation
default['tscm']['hostname'] = node['hostname'].downcase   # The hostname of the machine
default['tscm']['osname'] = node['platform'].downcase     # The OS name of the machine
default['tscm']['ipaddress'] = node['ipaddress']          # The IP address of the machine
default['tscm']['clientConfFile'] = 'C:\\Program Files\\IBM\\SCM\\client\\client.pref'        # Path for the client.pref file
default['tscm']['completedDirPath'] = 'C:\\Program Files\\IBM\\SCM\\client\\software\\completed'  # Path for the 'completed' folder where we can copy wsusscn2.cab file from TSCM server
default['tscm']['TSCMProxy_server'] = '10.0.146.37'   # tscm proxy server
default['tscm']['TSCMProxy_user'] = 'scm_auto_usr'    # tscm proxy user
default['tscm']['native_proxykey'] = 'SCM_id_rsa'     # tscm proxy key


For Linux platform:
# TSCM client native installer
default['tscm']['base_package'] = 'installer-tscmclient-linux64exp.tar'
# input for ssh command
default['tscm']['ssh_input'] = 'yes'
# TSCM proxy server
default['tscm']['proxy_server'] = '10.0.146.37'
# TSCM proxy server user
default['tscm']['proxy_user'] = 'scm_auto_usr'
# TSCM proxy user password
default['tscm']['proxy_password'] = 'Passw0rd'
# operation type for performing registration
default['tscm']['register_ot'] = 'reg'
# operation type for performing healthcheck
default['tscm']['hc_ot'] = 'col'
# operation type for performing reporting
default['tscm']['report_ot'] = 'rep'
# Operating system type
default['tscm']['OS_type'] = 'linux'
# TSCM wrapper script location
default['tscm']['wrapper_script'] = "C:\\TSCM_Automation\\TSCM_wrapper.ps1"
# TSCM client FQDN
default['tscm']['node_name'] = node['hostname'] + '.cma-cgm.com'
# TSCM proxy private key path and name
default['tscm']['key'] = '/tmp/SCM_id_rsa'
default['tscm']['key_name'] = 'SCM_id_rsa'
# TSCM client service name
default['tscm']['service_name'] = 'IBMSCMclient'
# configuration file client.pref file for changing logging level
default['tscm']['client_pref'] = '/opt/IBM/SCM/client/client.pref'
# temporary directory for copying TSCM native binaries
default['tscm']['temp_dir'] = '/tmp/tscm_temp'
# url to download TSCM binary
default['tscm']['url'] = 'https://pulp.cma-cgm.com/ibm/redhat7/tscm/installer-tscmclient-linux64exp.tar'
# remote location for copying the audit patching file
default['tscm']['remote_dir'] = "C:\\Users\\tscmuser\\Desktop\\Tools\\SCM Automation deployment\\External file to drop on CHEF clients"
# local path for copying the audit patching file in TSCM installation directory
default['tscm']['patch_dir'] = '/opt/IBM/SCM/client/software/completed'
# TSCM client IP address
default['tscm']['node_IP'] = node['ipaddress']
# # remote location for copying the audit patching file
default['tscm']['audit_path'] = "/C:/Program Files/IBM/SCM/client/software/completed/lssec_secfixdb_all.tar.gz"
