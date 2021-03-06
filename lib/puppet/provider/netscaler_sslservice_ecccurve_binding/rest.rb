require 'puppet/provider/netscaler'

require 'json'

Puppet::Type.type(:netscaler_sslservice_ecccurve_binding).provide(:rest, {:parent => Puppet::Provider::Netscaler}) do
  # Provider for sslservice_ecccurve_binding: Binds an SSL certificate-key pair or an SSL policy to an ecc curve.
  def netscaler_api_type
    "sslservice_sslservice_binding"
  end

  def self.instances
    instances = []
    sslservices = Puppet::Provider::Netscaler.call('/config/sslservice')
    return [] if sslservices.nil?

    sslservices.each do |sslservice|
      binds = Puppet::Provider::Netscaler.call("/config/sslservice_ecccurve_binding/#{sslservice['vservername']}") || []

      binds.each do |bind|
        instances << new({
          :ensure => :present,
          :name   => "#{bind['servicename']}/#{bind['ecccurvename']}",

        })
      end
    end

    instances
  end

  mk_resource_methods

  # Map for conversion in the message.
  def property_to_rest_mapping
    {
    :name          => :servicename,
    }
  end

  def immutable_properties
    [
      :crlcheck,
      :ca,
      :snicert,
      :skipcaname,
      :ocspcheck,
    ]
  end

  def destroy
    vservername, ecccurvename = resource.name.split('/')
    result = Puppet::Provider::Netscaler.delete("/config/#{netscaler_api_type}/#{vservername}", {'args'=>"ecccurvename:#{ecccurvename}"})
    @property_hash.clear
    return result
  end

  def per_provider_munge(message)
    message[:vservername], message[:ecccurvename] = message[:name].split('/')
    message.delete(:name)

    message
  end
end
