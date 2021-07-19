# check if the directory exist for tscm installer zipfile
describe file('C:\\tscm_temp') do
  it { should exist }
  its('type') { should eq :directory }
  it { should be_directory }
end

# check if the package tscm Agent package is installed
describe package('installer-tscmclient-win2k12.zip') do
  it { should be_installed }
end

# check if tscm service is running and enabled
describe service('jacservice') do
  it { should be_enabled }
  it { should be_running }
end

# check if the private key exist
describe file('C:\\tscm_temp\\SCM_id_rsa') do
  it { should exist }
  it { should be_file }
end

# check for the powershell script if copied on the node
describe file('C:\\tscm_temp\\CopyScript.ps1') do
  it { should exist }
  it { should be_file }
end

# check for the audit patching file if downloaded
describe file('C:\\Program Files\\IBM\\SCM\\client\\software\\completed\\wsusscn2.cab') do
  it { should exist }
  it { should be_file }
end

# check for the TSCM installed directory
describe file('/opt/IBM/SCM/client') do
  it { should exist }
  it { should be :directory }
end

# check if the private key exist
describe file('/tmp/SCM_id_rsa') do
  it { should exist }
  it { should be_file }
end

# check for the audit patching file if downloaded
describe file('/opt/IBM/SCM/client/software/completed/lssec_secfixdb_all.tar.gz') do
  it { should exist }
  it { should be_file }
end

# check for the powershell script if copied on the node
describe file('/tmp/copy_script.ps1') do
  it { should exist }
  it { should be_file }
end

# check if the tscm client is registered with tscm server
describe bash("grep 'Added client:' /tmp/register.log ") do
  its('stdout') { should match '/Added client/' }
  its('exit_status') { should eq 0 }
end

# check if TSCM service is running and enabled
describe service('IBMSCMclient') do
  it { should be_enabled }
  it { should be_running }
end

# check log levels at the end of the cookbook execution
describe bash("grep 'debug=false' /opt/IBM/SCM/client/client.pref ") do
  its('stdout') { should match '/debug=false/' }
  its('exit_status') { should eq 0 }
end
