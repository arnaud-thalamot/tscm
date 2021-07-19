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
     register_node
  end
end

action :validate do
  converge_by("Create #{@new_resource}") do
    validate_registration
  end
end

action :healthcheck do
  converge_by("Create #{@new_resource}") do
    health_check
  end
end

# method to install the tscm agent
def install_tscm
  case node['platform']
  when 'windows'
    if ::File.directory?(node['tscm']['alreadyInstalledFile'].to_s)
      Chef::Log.info('tscm is already install, nothing to install for tscm agent')
    else
      # Create temp directory where we copy/create source files to install tscm agent
      directory "#{node['tscm']['temp']}" do
        action :create
      end
      # get tscm agent media to our temp dir
      remote_file "#{node['tscm']['temp']}\\#{node['tscm']['TSCMfile']}" do
        source "#{node['tscm']['TSCMfile_Path']}"
        action :create
      end

      media = "#{node['tscm']['temp']}\\#{node['tscm']['TSCMfile']}"
      Chef::Log.info("media: #{media}")

      # Unpack media
      ruby_block 'unzip-install-file' do
        block do
          Chef::Log.info('unziping the tscm Installer file')
          command = powershell_out "Add-Type -assembly \"system.io.compression.filesystem\"; [io.compression.zipfile]::ExtractToDirectory('#{media}', 'C:\\tscm_temp')"
          Chef::Log.debug command
          action :create
        end
      end
      Chef::Log.info('Performing tscm agent installation...')
      ruby_block 'Install TSCM Agent' do
        block do
          install_cmd = powershell_out "Start-Process '#{node['tscm']['temp']}\\setup-x64.exe' '/verysilent /suppressmsgboxes /log=C:/tscminstall.log'"
          Chef::Log.debug install_cmd
          not_if { ::File.exist?("#{node['tsm']['alreadyInstalledFile']}") }
        end
        action :create
      end
      # Create directory where we copy wsusscn2.cab file from TSCM Server
      directory node['tscm']['patchAuditingPath'].to_s do
        action :create
        recursive true
      end

      # copy tscm proxy key of tscm server on Node
      cookbook_file "#{node['tscm']['temp']}\\#{node['tscm']['native_proxykey']}" do
        source "#{node['tscm']['native_proxykey']}"
        action :create
      end
      # fix permissions of client side files keys
       powershell_script 'fix_keyfile_permission' do
        code <<-EOH
        cd 'C:/Program Files/OpenSSH-Win64/'
        Import-Module ./OpenSSHUtils.psd1 -Force 
        Repair-UserKeyPermission -FilePath 'C:\\tscm_temp\\SCM_id_rsa' -Confirm:$false
        EOH
      end

      # Copy AuditPatching File to required location on the node
      Chef::Log.info('Copy audit patching file')
      execute 'Copy_auditPatching_file' do
        command 'C:/PROGRA~1/OpenSSH-Win64/scp.exe -o StrictHostKeyChecking=no -i C:/tscm_temp/SCM_id_rsa scm_auto_usr@10.0.146.37:/C:/PROGRA~1/IBM/SCM/client/software/completed/wsusscn2.cab C:/PROGRA~1/IBM/SCM/client/software/completed/'
        action :run
      end

      # Delete Program file which affect to start the SCM service
      file 'C:\\Program' do
        only_if { ::File.exist?('C:\\Program') }
        action :delete
      end
      
      # Copy the wrapper script on tscm temp directory
      cookbook_file "#{node['tscm']['temp']}\\#{node['tscm']['native_ScriptFile']}" do
        source "#{node['tscm']['native_ScriptFile']}"
        action :create
      end

      # Updating the debug value as true in client.pref file
      ruby_block 'update_debugValue' do
        block do
          Chef::Log.info('Sleeping for thirty second to wait to create the client.pref file')
          sleep(30)
          Chef::Log.info('Updating the debug value of client.pref file')
          file_name = "#{node['tscm']['clientConfFile']}"
          text = ::File.read(file_name)
          new_contents = text.gsub(/debug=false/, 'debug=true')
          # write changes to the file
          ::File.open(file_name, 'w') { |file| file.puts new_contents }
        end
        action :create
      end
      
      # Restart the SCM service for reflecting the changes
      service "#{node['tscm']['serviceName']}" do
        action :restart
      end
    end
  end
end

# Method to Register the node for TSCM
def register_node
  case node['platform']
  when 'windows'
   # Create temp directory where we copy/create source files to install tscm agent
    directory "#{node['tscm']['temp']}" do
      action :create
      not_if { ::File.directory?('C:\\tscm_temp')}
    end
    # copy tscm proxy key of tscm server on Node
    cookbook_file "#{node['tscm']['temp']}\\#{node['tscm']['native_proxykey']}" do
      source "#{node['tscm']['native_proxykey']}"
      action :create
    end
     # fix permissions of client side files keys
      powershell_script 'fix_keyfile_permission' do
      code <<-EOH
      cd 'C:/Program Files/OpenSSH-Win64/'
      Import-Module ./OpenSSHUtils.psd1 -Force 
      Repair-UserKeyPermission -FilePath 'C:\\tscm_temp\\SCM_id_rsa' -Confirm:$false
      EOH
    end
    
    execute 'register-tscm' do
      command "C:\\PROGRA~1\\OpenSSH-Win64\\ssh.exe -vvv -n -o StrictHostKeyChecking=no -vvv -i #{node['tscm']['temp']}\\SCM_id_rsa #{node['tscm']['TSCMProxy_user']}@#{node['tscm']['TSCMProxy_server']}" + " powershell.exe -File #{node['tscm']['tscmWrapper_path']} reg #{node['tscm']['hostname']} w2k12 #{node['tscm']['ipaddress']} > #{node['tscm']['register_log']} 2>&1"
      action :run
      timeout 3600
    end
    ruby_block 'sleep-after-register' do
      block do
        sleep(120)
      end
      action :run
    end
  end
end

# Method to validate Registration of the node for TSCM
def validate_registration
  case node['platform']
  when 'windows'
    #if node[:tscm].attribute?(:register_status)
    if  ((node['tscm']['regStatus']).to_s == 'success') 
      node.set['tscm']['regHealth'] = 'ko'
      Chef::Log.info('TSCM registartion already successful thus skipping validation to check the registration success')
    else
      ruby_block 'register_validate' do
        block do
         #  powershell_out("mv #{node['tscm']['register_log']} C:\\register_report")
          if ::File.exist?("#{node['tscm']['register_log']}") && ::File.readlines("#{node['tscm']['register_log']}").grep(/Added client: /).size > 0
            Chef::Log.info('TSCM agent registered successfully')
            node.set['tscm']['regStatus'] = 'success' && node.set['tscm']['regHealth'] = 'success'
            # node.set['tscm']['regHealth'] = 'success'
          else
            if ::File.exist?("#{node['tscm']['register_log']}") && ::File.readlines("#{node['tscm']['register_log']}").grep(/The client is already registered /).size > 0
              Chef::Log.info('The client already registered with TSCM, Skipping all the steps.')
              node.set['tscm']['regStatus'] = 'success'
              node.set['tscm']['regHealth'] = 'ko'
            else
              Chef::Log.info('TSCM agent not registered, Manual Intervention needed to check further.')
              node.set['tscm']['regStatus'] = 'failure'
            end
          end
        end
        action :run
      end
    end
  end
end

def health_check
  case node['platform']
  when 'windows'            
    # Create temp directory where we copy/create source files to install tscm agent
    directory "#{node['tscm']['temp']}" do
      action :create
      not_if { ::File.directory?('C:\\tscm_temp')}
    end
    # copy tscm proxy key of tscm server on Node
    cookbook_file "#{node['tscm']['temp']}\\#{node['tscm']['native_proxykey']}" do
      source "#{node['tscm']['native_proxykey']}"
      action :create
      not_if { ::File.exist?("#{node['tscm']['temp']}\\#{node['tscm']['native_proxykey']}") }
    end
     # fix permissions of client side files keys
     powershell_script 'fix_keyfile_permission' do
      code <<-EOH
      cd 'C:/Program Files/OpenSSH-Win64/'
      Import-Module ./OpenSSHUtils.psd1 -Force 
      Repair-UserKeyPermission -FilePath 'C:\\tscm_temp\\SCM_id_rsa' -Confirm:$false
      EOH
      only_if { ::File.exist?("#{node['tscm']['temp']}\\#{node['tscm']['native_proxykey']}") }
    end

    # Health checking of the Node
    #powershell_out("&'C:\\Program Files\\OpenSSH-Win64\\ssh.exe' -tt -o StrictHostKeyChecking=no -i #{node['tscm']['temp']}\\SCM_id_rsa #{node['tscm']['TSCMProxy_user']}@#{node['tscm']['TSCMProxy_server']}" + " powershell #{node['tscm']['tscmWrapper_path']} col #{node['tscm']['hostname']} w2k12")
    execute 'healthchecking-tscm' do
      command "C:/PROGRA~1/OpenSSH-Win64/ssh.exe -o StrictHostKeyChecking=no -i #{node['tscm']['temp']}/SCM_id_rsa #{node['tscm']['TSCMProxy_user']}@#{node['tscm']['TSCMProxy_server']} powershell.exe -File #{node['tscm']['tscmWrapper_path']} col #{node['tscm']['hostname']} w2k12"
      action :run
      timeout 1200
    end

    execute 'healthchecking-report' do
      command "C:/PROGRA~1/OpenSSH-Win64/ssh.exe -n -o StrictHostKeyChecking=no -i #{node['tscm']['temp']}/SCM_id_rsa #{node['tscm']['TSCMProxy_user']}@#{node['tscm']['TSCMProxy_server']} powershell #{node['tscm']['tscmWrapper_path']} rep #{node['tscm']['hostname']} w2k12"
      action :run
      timeout 1200
    end
    
    execute 'download-report-txt' do
      command "C:/PROGRA~1/OpenSSH-Win64/scp.exe -o StrictHostKeyChecking=no -r -i #{node['tscm']['temp']}/SCM_id_rsa #{node['tscm']['TSCMProxy_user']}@#{node['tscm']['TSCMProxy_server']}:#{node['tscm']['reports_path']}/#{node['tscm']['hostname']}/#{node['tscm']['hostname']}.txt #{node['tscm']['reportcopy_path']}"
      action :run
      timeout 1200
    end

    execute 'download-report-zip' do
      command "C:/PROGRA~1/OpenSSH-Win64/scp.exe -o StrictHostKeyChecking=no -r -i #{node['tscm']['temp']}/SCM_id_rsa #{node['tscm']['TSCMProxy_user']}@#{node['tscm']['TSCMProxy_server']}:#{node['tscm']['reports_path']}/#{node['tscm']['hostname']}/#{node['tscm']['hostname']}.zip #{node['tscm']['reportcopy_path']}"
      action :run
      timeout 1200
    end

    # Updating the debug value as false in client.pref file
    ruby_block 'update_debugValue' do
      block do
        Chef::Log.info('Updating the debug value of client.pref file')
        file_name = "#{node['tscm']['clientConfFile']}"
        text = ::File.read(file_name)
        new_contents = text.gsub(/debug=true/, "debug=false")
        ::File.open(file_name, 'w') { |file| file.puts new_contents }
      end
      action :create
    end

    # Restart the SCM service for reflecting the changes
    service "#{node['tscm']['serviceName']}" do
      action :restart
    end

    # Deleting the Temp file
    directory node['tscm']['temp'].to_s do
      recursive true
      action :delete
      only_if { ::File.directory?("#{node['tscm']['temp']}")}
    end
  end
end

action :deregister do
  converge_by("Create #{@new_resource}") do
    deregister_node
  end
end

# Method to uninstall tscm agent
def deregister_node
  case node['platform']
  when 'windows'
    # Create temp directory where we copy/create source files to install tscm agent
    directory "#{node['tscm']['temp']}" do
      action :create
      not_if { ::File.directory?(node['tscm']['temp']) }
    end
    # copy tscm proxy key of tscm server on Node
    cookbook_file "#{node['tscm']['temp']}\\#{node['tscm']['native_proxykey']}" do
      source "#{node['tscm']['native_proxykey']}"
      action :create
      not_if { ::File.exist?("#{node['tscm']['temp']}\\#{node['tscm']['native_proxykey']}") }
    end
    # fix permissions of client side files keys
    powershell_script 'fix_keyfile_permission' do
      code <<-EOH
      cd 'C:/Program Files/OpenSSH-Win64/'
      Import-Module ./OpenSSHUtils.psd1 -Force 
      Repair-UserKeyPermission -FilePath 'C:\\tscm_temp\\SCM_id_rsa' -Confirm:$false
      EOH
      only_if { ::File.exist?("#{node['tscm']['temp']}\\#{node['tscm']['native_proxykey']}") }
    end

    # Deregister of the Node
    ruby_block 'deregister_node' do
      block do
        Chef::Log.info('Deregistering the node from TSCM server')
        powershell_out("C:/PROGRA~1/OpenSSH-Win64/ssh.exe -o StrictHostKeyChecking=no -i #{node['tscm']['temp']}/SCM_id_rsa #{node['tscm']['TSCMProxy_user']}@#{node['tscm']['TSCMProxy_server']} powershell #{node['tscm']['tscmWrapper_path']} del #{node['tscm']['hostname']} w2k12")
      end
      action :create
    end
    
    # Deleting the Temp file
    directory node['tscm']['temp'].to_s do
      recursive true
      action :delete
    end
  end
end
