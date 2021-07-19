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
  # un-registering windows tscm client
  ibm_tscm_tscmagentwin 'deregister-tscm-agent' do
    action :deregister
  end
when 'redhat'
  # un-registering linux tscm client
  ibm_tscm_tscmagent 'unregister-tscm' do
    action :unregister
  end
when 'aix'
  # un-registering linux tscm client
  ibm_tscm_tscmagent 'unregister-tscm' do
    action :unregister
  end
end