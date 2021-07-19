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
  # install configure register perform healthcheck and generate reports for windows tscm client
  ibm_tscm_tscmagentwin 'install-configure-tscm-agent' do
    action [:healthcheck]
  end


when 'redhat'
  # installing TSCM client
  ibm_tscm_tscmagent 'install-register-generate-reports-tscm' do
    action [:healthcheck, :report]
  end

when 'aix'
  ibm_tscm_tscmagent 'install-register-generate-reports-tscm' do
    action [:healthcheck, :report]
  end
end
