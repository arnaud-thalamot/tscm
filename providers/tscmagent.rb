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

require 'chef/resource'

use_inline_resources

def whyrun_supported?
  true
end

action :install do
  converge_by("Create #{@new_resource}") do
    install_tscm
  end
end

action :register do
  converge_by("Create #{@new_resource}") do
    register_tscm
    # validate_registration
  end
end

action :healthcheck do
  converge_by("Create #{@new_resource}") do
    run_healthcheck
  end
end

action :report do
  converge_by("Create #{@new_resource}") do
    generate_report
  end
end

action :unregister do
  converge_by("Create #{@new_resource}") do
    unregister_tscm
  end
end

# installing tscm agent on Linux - Redhat Platform
def install_tscm
  case node['platform']
  when 'redhat'
     # Create dir to mount
    directory '/opt/IBM/SCM' do
      recursive true
      action :create
    end

    #Create SCM logical volume 
     node['tscm']['logvols'].each do |logvol|
    lvm_logical_volume logvol['volname'] do
      group   node['tscm']['volumegroup']
      size    logvol['size']
      filesystem    logvol['fstype']
      mount_point   logvol['mountpoint']
      end
    end      
    # verifying the tscm installation if already exists
    if ::File.exist?("#{node['tscm']['installed_dir']}jacclient")
      install_status = shell_out("#{node['tscm']['installed_dir']}jacclient status").stdout.chop
      if install_status.include?('The Tivoli Security Compliance Manager client is currently running')
        Chef::Log.error('TSCM client already installed on ' + (node['tscm']['node_name']).to_s + '........Nothing to do')
      end
    else
      Chef::Log.info('Installing TSCM ....')

      # creating a temporary directory for installinsg TSCM
      tempfolder = '/opt/IBM/tscm_temp'

      directory tempfolder.to_s do
        action :create
      end

      # get TSCM media to our temp dir
      media = tempfolder + '/' + node['tscm']['base_package'].to_s

      remote_file media.to_s do
        source node['tscm']['url'].to_s
        owner 'root'
        group 'root'
        mode '0755'
        action :create_if_missing
      end

      # Unpacking TSCM media
      execute 'unpack-media' do
        command 'cd ' + tempfolder.to_s + ' ; ' + ' tar -xf ' + media.to_s
        action :run
        not_if { ::File.exist?("#{media}/#{node['tscm']['base_package']}") }
      end

      # run the installation script
      bash 'install-tscm' do
        code <<-EOH
          cd #{tempfolder}
          chmod 744 install_x64.sh
          ./install_x64.sh
        EOH
      end

      # copy the ssh key for TSCM to /opt/IBM/
      cookbook_file node['tscm']['key'].to_s do
        source node['tscm']['key_name'].to_s
        owner 'root'
        group 'root'
        mode '400'
        action :create_if_missing
      end

      # create temp directory to copy the auditing patching file
      directory node['tscm']['patch_dir'].to_s do
        recursive true
        owner 'root'
        group 'root'
        mode '0744'
        action :create
      end

      # copy the powershell script to node system
      cookbook_file node['tscm']['copy_script_path'].to_s do
        source 'copy_script.ps1'
        owner 'root'
        group 'root'
        mode '750'
        action :create
      end

      # copy the powershell script to TSCM Server
      bash 'copy-powershell-script-to-tscm-server' do
        code <<-EOH
          scp -C -o StrictHostKeyChecking=no -i #{node['tscm']['key']} #{node['tscm']['copy_script_path']} #{node['tscm']['proxy_user']}@#{node['tscm']['proxy_server']}:/c:/users/scm_auto_usr/
	      EOH
        live_stream true
        action :run
      end

      # run the powershell scripts
      execute 'run-powershell-script' do
        command "ssh -n -i #{node['tscm']['key']} #{node['tscm']['proxy_user']}@#{node['tscm']['proxy_server']} powershell -File 'C:/Users/scm_auto_usr/copy_script.ps1'"
        live_stream true
        action :run
      end

      # copy the audit patching file
      execute 'download-audi-patching-file' do
        command "scp -o StrictHostKeyChecking=no -i #{node['tscm']['key']} #{node['tscm']['proxy_user']}@#{node['tscm']['proxy_server']}:/C:/Users/scm_auto_usr/lssec_secfixdb_all.tar.gz /opt/IBM/SCM/client/software/completed/"
        live_stream true
        action :run
        not_if { ::File.exist?(node['tscm']['audit_file'].to_s) }
      end

      client_pref = shell_out("grep 'debug=true' #{node['tscm']['client_pref']} ").stdout.chop

      if client_pref.include?('debug=true')
        Chef::Log.info('File Up to date..........Nothing to do')
      else
        # update the client.pref file to debug mode
        execute 'update-client.pref' do
          command "sed -i -e 's/debug=false/debug=true/' #{node['tscm']['client_pref']}"
          action :run
        end

        # restarting TSCM agent service for changes to take effect
        service node['tscm']['service_name'].to_s do
          action :stop
        end

        service node['tscm']['service_name'].to_s do
          action :start
        end
      end
    end

  # installing on aix
  when 'aix'
    Chef::Log.info('Installing TSCM on AIX platform...........')

    if ::File.exist?("#{node['tscm']['installed_dir']}jacclient")
      install_status = shell_out("#{node['tscm']['installed_dir']}jacclient status").stdout.chop
      if install_status.include?('HCVIN0033I The Tivoli Security Compliance Manager client is currently running')
        Chef::Log.error('TSCM client already installed on ' + (node['tscm']['node_name']).to_s + '........Nothing to do')
      end
    else
      Chef::Log.info('TSCM not installed ........Installing TSCM ')

      # creating temporary directory for copying tscm binaries
      tempfolder = '/opt/IBM/tscm_software'

      directory tempfolder.to_s do
        action :create
        not_if { ::File.exist?(tempfolder.to_s) }
      end

      media = tempfolder.to_s + '/' + (node['tscm']['base_package']).to_s
      node.default['tscm']['package_name'] = (node['tscm']['base_package']).to_s.chomp('.tar')

      # downloading binaries from the url
      remote_file media.to_s do
        source node['tscm']['url'].to_s
        owner 'root'
        mode '0755'
        action :create_if_missing
      end

      # creating prerequisite FS
      # create volume group ibmvg as mandatory requirement
      execute 'create-VG-ibmvg' do
        command 'mkvg -f -y ibmvg hdisk1'
        action :run
        returns [0, 1]
        not_if { shell_out('lsvg | grep ibmvg').stdout.chop != '' }
      end

      # required FS
      volumes = [
        { lvname: 'lv_scm', fstype: 'jfs2', vgname: 'ibmvg', size: 500, fsname: '/opt/IBM/SCM' },
      ]
      # Custom FS creation
      volumes.each do |data|
        ibm_tscm_makefs "creation of #{data[:fsname]} file system" do
          lvname data[:lvname]
          fsname data[:fsname]
          vgname data[:vgname]
          fstype data[:fstype]
          size data[:size]
        end
      end

      # Unpacking TSCM media
      execute 'unpack-media' do
        command 'cd ' + tempfolder.to_s + ' ; ' + ' tar -xf ' + media.to_s
        action :run
        not_if { ::File.exist?(media.to_s + node['tscm']['package_name'].to_s + 'install_aix6.sh') }
      end

      # run the installation script
      bash 'install-tscm' do
        code <<-EOH
        cd #{tempfolder}
        chmod +x install_aix6.sh
        ./install_aix6.sh      
        EOH
      end

      # copy the ssh key for TSCM to /opt/IBM/ directory
      cookbook_file node['tscm']['key'].to_s do
        source node['tscm']['key_name'].to_s
        owner 'root'
        mode '400'
        action :create_if_missing
      end

      # create temp directory to copy the auditing patching file
      directory node['tscm']['patch_dir'].to_s do
        recursive true
        owner 'root'
        mode '0744'
        action :create
      end

      # copy the audit patching file
      execute 'download-audi-patching-file' do
        command "scp -o StrictHostKeyChecking=no -i #{node['tscm']['key']} #{node['tscm']['proxy_user']}@#{node['tscm']['proxy_server']}:/C:/PROGRA~1/IBM/SCM/client/software/completed/lssec_secfixdb_all.tar.gz /opt/IBM/SCM/client/software/completed/"
        action :run
        not_if { ::File.exist?(node['tscm']['audit_file'].to_s) }
      end

      # changing log-level to debug mode
      client_pref = shell_out("grep 'debug=true' #{node['tscm']['client_pref']} ").stdout.chop

      if client_pref.include?('debug=true')
        Chef::Log.info('File Up to date..........Nothing to do')
      else
        # update the client.pref file to debug mode
        execute 'update-client.pref' do
          command "sed -e 's/debug=false/debug=true/g' #{node['tscm']['client_pref']}"
          action :run
        end

        # restarting TSCM agent service for changes to take effect
        execute 'restart-tscm-service' do
          command '/opt/IBM/SCM/client/jacclient restart'
          action :run
        end
      end
    end
  end
end

# copy key when required and check if already exist
def verify_key
  Chef::Log.info('Check for RSA key and download key ')

  if ::File.exist?('/opt/IBM/SCM_id_rsa')
    Chef::Log.info('Key already exist..........')
  else
    Chef::Log.info('Downloading the key.........')
    # copy the ssh key for TSCM to /opt/IBM/
    cookbook_file node['tscm']['key'].to_s do
      source node['tscm']['key_name'].to_s
      owner 'root'
      mode '400'
      action :create_if_missing
    end
    Chef::Log.info('Finished downloading RSA key...............')
  end
end

# registering the tscm agent with tscm server
def register_tscm
  case node['platform']
  when 'redhat'
    client_id = shell_out('cat /opt/IBM/SCM/client/client.id').stdout

    if client_id.to_i == -1
      # registering the tscm client with server
      Chef::Log.info('Registering TSCM client........')

      # check for key required for server authentication
      verify_key

      # registering client using ssh command
      execute 'register-node' do
        command "ssh -n -o StrictHostKeyChecking=no -i #{node['tscm']['key']} #{node['tscm']['proxy_user']}@#{node['tscm']['proxy_server']} powershell.exe -File 'C:/TSCM_Automation/TSCM_wrapper.ps1' #{node['tscm']['register_ot']} #{node['tscm']['node_name']} #{node['tscm']['OS_type']} #{node['tscm']['node_IP']}"
        action :run
        timeout 1800
      end

      ruby_block 'sleep-after-register' do
        block do
          sleep(120)
        end
        action :run
      end
    
    else
      Chef::Log.error('TSCM Client: ' + (node['tscm']['node_name']).to_s + ' Already Registered with Object ID : ' + client_id.to_s + '.....................Nothing to do')
      node.default['tscm']['registration_status'] = 'success'
    end

  # registering on aix
  when 'aix'
    client_id = shell_out('cat /opt/IBM/SCM/client/client.id').stdout

    # check if the key is available; download in case it is not available
    verify_key
  
    Chef::Log.error(client_id.to_i)
    if client_id.to_i == -1
      Chef::Log.info('Registering the TSCM client.......')

      # registering the tscm client with server
      Chef::Log.info('Registering TSCM client........')

      execute 'register-tscm' do
        command "ssh -n -o StrictHostKeyChecking=no -i #{node['tscm']['key']} #{node['tscm']['proxy_user']}@#{node['tscm']['proxy_server']} powershell.exe -File 'C:/TSCM_Automation/TSCM_wrapper.ps1' #{node['tscm']['register_ot']} #{node['tscm']['node_name']} #{node['tscm']['OS_type']} #{node['tscm']['node_IP']}"
        action :run
        timeout 1800
      end

      ruby_block 'sleep-after-register' do
        block do
          sleep(120)
        end
        action :run
      end

      # checking log files for validating registration
      if ::File.exist?('/opt/IBM/SCM/client/client.log') && ::File.readlines('/opt/IBM/SCM/client/client.log').grep(/Storing obsfucated schedules/)
        Chef::Log.info('Registration Success...........')
      else
        Chef::Log.error('Registration Failed...........')
      end
    else
      Chef::Log.error('TSCM Client: ' + (node['tscm']['node_name']).to_s + ' Already Registered with Object ID : ' + client_id.to_s + '.....................Nothing to do')
      node.default['tscm']['registration_status'] = 'success'
      Chef::Log.error((node['tscm']['registration_status']).to_s)
    end
  end
end

# running tscm healthcheck
def run_healthcheck
  case node['platform']
  when 'redhat'
    Chef::Log.info('Running TSCM healthcheck.............')

    # check for key required for server authentication
    verify_key

    # TSCM healthchecking command
    hc_command = "powershell.exe -File 'C:/TSCM_Automation/TSCM_wrapper.ps1' #{node['tscm']['hc_ot']} #{node['tscm']['node_name']} #{node['tscm']['OS_type']} "

    # performing TSCM healthcheck
    execute 'healthchecking-tscm' do
      command "ssh -n -o StrictHostKeyChecking=no #{node['tscm']['proxy_user']}@#{node['tscm']['proxy_server']} -i #{node['tscm']['key']} " + hc_command.to_s
      action :run
      not_if { (node['tscm']['registration_status']).to_s == 'success'}
    end

  # running healthcheck on aix
  when 'aix'
    Chef::Log.info('Running TSCM healthcheck.............')

    # check if the key is available; download in case it is not available
    verify_key

    # TSCM healthchecking command
    hc_command = "powershell.exe -File 'C:/TSCM_Automation/TSCM_wrapper.ps1' #{node['tscm']['hc_ot']} #{node['tscm']['node_name']} #{node['tscm']['OS_type']} "

    # performing TSCM healthcheck
    execute 'healthchecking-tscm' do
      command "ssh -n -o StrictHostKeyChecking=no #{node['tscm']['proxy_user']}@#{node['tscm']['proxy_server']} -i #{node['tscm']['key']} " + hc_command.to_s
      action :run
      not_if { (node['tscm']['registration_status']).to_s == 'success' }
    end
  end
end

# generating reports for TSCM agent
def generate_report
  case node['platform']
  when 'redhat'
    Chef::Log.info('Generating healthcheck reports for TSCM .......')

    # check for key required for server authentication
    verify_key

    # generating reports command
    rep_command = "powershell.exe -File 'C:/TSCM_Automation/TSCM_wrapper.ps1' #{node['tscm']['report_ot']} #{node['tscm']['node_name']} #{node['tscm']['OS_type']} "

    # generating TSCM reports
    execute 'generate-report-tscm' do
      command "ssh -n -o StrictHostKeyChecking=no #{node['tscm']['proxy_user']}@#{node['tscm']['proxy_server']} -i #{node['tscm']['key']} " + rep_command.to_s
      action :run
      not_if { (node['tscm']['registration_status']).to_s == 'success'}
    end

    # downloading reports from tscm server
    execute 'download-reports-zip' do
      command "scp -o StrictHostKeyChecking=no -i #{node['tscm']['key']} #{node['tscm']['proxy_user']}@#{node['tscm']['proxy_server']}:/c:/TSCM_Automation/Reports/#{node['tscm']['node_name']}/#{node['tscm']['node_name']}.zip #{node['tscm']['download_path']} "
      live_stream true
      action :run
      not_if { (node['tscm']['registration_status']).to_s == 'success'}
    end

    # downloading reports text file from tscm server
    execute 'download-report-text' do
      command "scp -o StrictHostKeyChecking=no -i #{node['tscm']['key']} #{node['tscm']['proxy_user']}@#{node['tscm']['proxy_server']}:/c:/TSCM_Automation/Reports/#{node['tscm']['node_name']}/#{node['tscm']['node_name']}.txt #{node['tscm']['download_path']} "
      live_stream true
      action :run
      not_if { (node['tscm']['registration_status']).to_s == 'success'}
    end

    client_pref = shell_out("grep 'debug=false' #{node['tscm']['client_pref']} ").stdout.chop

    if client_pref.include?('debug=false')
      Chef::Log.info('File Up to date..........Nothing to do')
    else
      # update the client.pref file to debug mode
      execute 'update-client.pref' do
        command "sed -i -e 's/debug=true/debug=false/' #{node['tscm']['client_pref']}"
        action :run
      end

      # restarting TSCM agent service for changes to take effect
      service node['tscm']['service_name'].to_s do
        action :stop
      end

      service node['tscm']['service_name'].to_s do
        action :start
      end
    end

    # removing unwanted files
    file node['tscm']['key'].to_s do
      action :delete
      only_if { ::File.exist?(node['tscm']['key'].to_s) }
    end

    file node['tscm']['copy_script_path'].to_s do
      action :delete
      only_if { ::File.exist?(node['tscm']['copy_script_path'].to_s) }
    end

    tempfolder = '/opt/IBM/tscm_temp'
    directory tempfolder.to_s do
      recursive true
      action :delete
      only_if { ::File.exist?(tempfolder.to_s) }
    end

    ruby_block 'display-deviations-found' do
      block do
        if ::File.exist?("#{node['tscm']['download_path']}#{node['tscm']['node_name']}.txt")
	      # setting tscm deviation attribute
          deviation = shell_out("cat #{node['tscm']['download_path']}#{node['tscm']['node_name']}.txt").stdout
          # deviation[0,2] = ''
          node.default['tscm']['deviation'] = "#{deviation}"
          puts "No of deviations found : #{deviation}"
        else
          Chef::Log.info("Report not generated !")
        end
      end
    end

  # generating reports on aix
  when 'aix'
    Chef::Log.info('Generating healthcheck reports for TSCM .......')

    # check if the key is available; download in case it is not available
    verify_key
    # generating reports command
    rep_command = "powershell.exe -File 'C:/TSCM_Automation/TSCM_wrapper.ps1' #{node['tscm']['report_ot']} #{node['tscm']['node_name']} #{node['tscm']['OS_type']} "

    # generating TSCM reports
    execute 'generate-report-tscm' do
      command "ssh -n -o StrictHostKeyChecking=no #{node['tscm']['proxy_user']}@#{node['tscm']['proxy_server']} -i #{node['tscm']['key']} " + rep_command.to_s
      action :run
      not_if { (node['tscm']['registration_status']).to_s == 'success' }
    end

    # downloading reports from tscm server
    execute 'download-reports-zip' do
      command "scp -o StrictHostKeyChecking=no -i #{node['tscm']['key']} #{node['tscm']['proxy_user']}@#{node['tscm']['proxy_server']}:/c:/TSCM_Automation/Reports/#{node['tscm']['node_name']}/#{node['tscm']['node_name']}.zip #{node['tscm']['download_path']} "
      action :run
      not_if { (node['tscm']['registration_status']).to_s == 'success' || (node['tscm']['registration_status']).to_s == 'fail' }
    end

    # downloading reports text file from tscm server
    execute 'download-report-text' do
      command "scp -o StrictHostKeyChecking=no -i #{node['tscm']['key']} #{node['tscm']['proxy_user']}@#{node['tscm']['proxy_server']}:/c:/TSCM_Automation/Reports/#{node['tscm']['node_name']}/#{node['tscm']['node_name']}.txt #{node['tscm']['download_path']} "
      action :run
      not_if { (node['tscm']['registration_status']).to_s == 'success' }
    end

    client_pref = shell_out("grep 'debug=false' #{node['tscm']['client_pref']} ").stdout.chop

    if client_pref.include?('debug=false')
      Chef::Log.info('File Up to date..........Nothing to do')
    else
      # update the client.pref file to debug mode
      execute 'update-client.pref' do
        command "sed -e 's/debug=true/debug=false/g' #{node['tscm']['client_pref']}"
        action :run
      end

      # restarting TSCM agent service for changes to take effect
      execute 'restart-tscm-service' do
        command '/opt/IBM/SCM/client/jacclient restart'
        action :run
      end
    end

    # removing unwanted files
    file node['tscm']['key'].to_s do
      action :delete
      only_if { ::File.exist?(node['tscm']['key'].to_s) }
    end

    file node['tscm']['copy_script_path'].to_s do
      action :delete
      only_if { ::File.exist?(node['tscm']['copy_script_path'].to_s) }
    end

    tempfolder = '/opt/IBM/tscm_temp'
    directory tempfolder.to_s do
      recursive true
      action :delete
      only_if { ::File.exist?(tempfolder.to_s) }
    end

     ruby_block 'display-deviations-found' do
      block do
        if ::File.exist?("#{node['tscm']['download_path']}#{node['tscm']['node_name']}.txt")
	      # setting tscm deviation attribute
          deviation = shell_out("cat #{node['tscm']['download_path']}#{node['tscm']['node_name']}.txt").stdout
          # deviation[0,2] = ''
          node.default['tscm']['deviation'] = "#{deviation}"
          puts "No of deviations found : #{deviation}"
        else
          Chef::Log.info("Report not generated !")
        end
      end
    end
  end
end

# uninstalling TSCM client
def unregister_tscm
  case node['platform']
  when 'redhat'
    Chef::Log.info('Unregister TSCM client.........')

    # check for key required for server authentication
    verify_key

    # un-register the tscm client from tscm server
    ruby_block 'unregister_node' do
      block do
        Chef::Log.info('Un-registering the Node from TSCM server...............')
        Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
        command = "ssh -n -o StrictHostKeyChecking=no -i #{node['tscm']['key']} #{node['tscm']['proxy_user']}@#{node['tscm']['proxy_server']} powershell.exe -File 'C:/TSCM_Automation/TSCM_wrapper.ps1' #{node['tscm']['unregister_ot']} #{node['tscm']['node_name']} #{node['tscm']['OS_type']} #{node['tscm']['node_IP']}"
        Chef::Log.info command
        command_out = shell_out("#{command} > /opt/IBM/un-register.log 2>&1").stdout.chop
        execute "cat /opt/IBM/un-register.log"
      end
      action :create
    end

    # removing unwanted files
    file node['tscm']['key'].to_s do
      action :delete
      only_if { ::File.exist?(node['tscm']['key'].to_s) }
    end

  # uninstalling on aix
  when 'aix'
    Chef::Log.info('Unregister TSCM client.........')

    # check if the key is available; download in case it is not available
    verify_key

    # un-register the tscm client from tscm server
    ruby_block 'unregister_node' do
      block do
        Chef::Log.info('Un-registering the Node from TSCM server...............')
        Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
        command = "ssh -tt -o StrictHostKeyChecking=no -i #{node['tscm']['key']} #{node['tscm']['proxy_user']}@#{node['tscm']['proxy_server']} powershell.exe -File 'C:/TSCM_Automation/TSCM_wrapper.ps1' #{node['tscm']['unregister_ot']} #{node['tscm']['node_name']} #{node['tscm']['OS_type']} #{node['tscm']['node_IP']}"
        Chef::Log.info command
        command_out = shell_out("#{command} > /opt/IBM/un-register.log 2>&1").stdout.chop
        Chef::Log.info(command_out.to_s)
        not_if { "#{node['tscm']['registration_status']}" == 'fail' }
      end
      action :create
    end
  end
end
