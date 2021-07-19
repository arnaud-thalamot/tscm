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
when 'windows'
  # install configure register tscm client for windows
  ibm_tscm_tscmagentwin 'install-configure-tscm-agent' do
    action [:install]
  end

when 'redhat'

  execute 'disable-selinux' do
    command 'setenforce 0'
    action :run
  end

  # installing TSCM client
  ibm_tscm_tscmagent 'install-register-generate-reports-tscm' do
    action [:install, :register]
  end

  execute 'enable-selinux' do
    command 'setenforce 1'
    action :run
  end

when 'aix'
  ibm_tscm_tscmagent 'install-register-generate-reports-tscm' do
    action [:install, :register]
  end
end

node.set['tscm']['status'] = 'success'
