require 'azure_mgmt_resources'
require File.expand_path('../../libraries/logger.rb', __FILE__)

module Utils

  # method to get credentials in order to call Azure
  def get_credentials(tenant_id, client_id, client_secret)
    begin
      # Create authentication objects
      token_provider =
        MsRestAzure::ApplicationTokenProvider.new(tenant_id,
                                                  client_id,
                                                  client_secret)

      OOLog.fatal('Azure Token Provider is nil') if token_provider.nil?

      MsRest::TokenCredentials.new(token_provider)
    rescue MsRestAzure::AzureOperationError => e
      OOLog.fatal("Error acquiring a token from Azure: #{e.body}")
    rescue => ex
      OOLog.fatal("Error acquiring a token from Azure: #{ex.message}")
    end
  end

  # if there is an apiproxy cloud var define, set it on the env.
  def set_proxy(cloud_vars)
    cloud_vars.each do |var|
      if var[:ciName] == 'apiproxy'
        ENV['http_proxy'] = var[:ciAttributes][:value]
        ENV['https_proxy'] = var[:ciAttributes][:value]
      end
    end
  end

  # if there is an apiproxy cloud var define, set it on the env.
  def set_proxy_from_env(node)
    cloud_name = node['workorder']['cloud']['ciName']
    compute_service =
      node['workorder']['services']['compute'][cloud_name]['ciAttributes']
    OOLog.info("ENV VARS ARE: #{compute_service['env_vars']}")
    env_vars_hash = JSON.parse(compute_service['env_vars'])
    OOLog.info("APIPROXY is: #{env_vars_hash['apiproxy']}")

    if !env_vars_hash['apiproxy'].nil?
      ENV['http_proxy'] = env_vars_hash['apiproxy']
      ENV['https_proxy'] = env_vars_hash['apiproxy']
    end
  end

  def get_component_name(type, ciId)
    ciId = ciId.to_s
    if type == "nic"
      return "nic-"+ciId
    elsif type == "publicip"
      return "publicip-"+ciId
    elsif type == "privateip"
      return "nicprivateip-"+ciId
    elsif type == "lb_publicip"
      return "lb-publicip-"+ciId
    elsif type == "ag_publicip"
      return "ag_publicip-"+ciId
    end
  end

  def get_dns_domain_label(platform_name, cloud_id, instance_id, subdomain)
    subdomain = subdomain.gsub(".", "-")
    return (platform_name+"-"+cloud_id+"-"+instance_id.to_s+"-"+subdomain).downcase
  end

  # this is a static method to generate a name based on a ciId and location.
  def abbreviate_location(region)
    abbr = ''

    # Resouce Group name can only be 90 chars long.  We are doing this case
    # to abbreviate the region so we don't hit that limit.
    case region
      when 'eastus2'
        abbr = 'eus2'
      when 'centralus'
        abbr = 'cus'
      when 'brazilsouth'
        abbr = 'brs'
      when 'centralindia'
        abbr = 'cin'
      when 'eastasia'
        abbr = 'eas'
      when 'eastus'
        abbr = 'eus'
      when 'japaneast'
        abbr = 'jpe'
      when 'japanwest'
        abbr = 'jpw'
      when 'northcentralus'
        abbr = 'ncus'
      when 'northeurope'
        abbr = 'neu'
      when 'southcentralus'
        abbr = 'scus'
      when 'southeastasia'
        abbr = 'seas'
      when 'southindia'
        abbr = 'sin'
      when 'westeurope'
        abbr = 'weu'
      when 'westindia'
        abbr = 'win'
      when 'westus'
        abbr = 'wus'
      else
        OOLog.fatal("Azure location/region, '#{region}' not found in Resource Group abbreviation List")
    end
    return abbr
  end

  def is_prm(size, isUndeployment)
    az_size = ''
    # Method that maps sizes
    case size
      when 'XS'
        az_size = 'Standard_A0'
      when 'S'
        az_size = 'Standard_A1'
      when 'M'
        az_size = 'Standard_A2'
      when 'L'
        OOLog.info("L: Standard_A3") #just testing
        az_size = 'Standard_A3'
      when 'XL'
        az_size = 'Standard_A4'
      when 'XXL'
        az_size = 'Standard_A5'
      when '3XL'
        az_size = 'Standard_A6'
      when '4XL'
        az_size = 'Standard_A7'
      when 'S-CPU'
        az_size = 'Standard_D1'
      when 'M-CPU'
        az_size = 'Standard_D2'
      when 'L-CPU'
        az_size = 'Standard_D3'
      when 'XL-CPU'
        az_size = 'Standard_D4'
      when '8XL-CPU'
        az_size = 'Standard_D11'
      when '9XL-CPU'
        az_size = 'Standard_D12'
      when '10XL-CPU'
        az_size = 'Standard_D13'
      when '11XL-CPU'
        az_size = 'Standard_D14'
      when 'S-MEM'
        az_size = 'Standard_DS1'
      when 'M-MEM'
        az_size = 'Standard_DS2'
      when 'L-MEM'
        az_size = 'Standard_DS3'
      when 'XL-MEM'
        az_size = 'Standard_DS4'
      when '8XL-MEM'
        az_size = 'Standard_DS11'
      when '9XL-MEM'
        az_size = 'Standard_DS12'
      when '10XL-MEM'
        az_size = 'Standard_DS13'
      when '11XL-MEM'
        az_size = 'Standard_DS14'
      #old mappings - this part is used to deprovision only
      when 'S-IO'
        if(isUndeployment)
          az_size = 'Standard_DS1'
        else 
          OOLog.fatal("Azure size map, '#{size}' not found in Mappings List")
        end
      when 'M-IO'
        if(isUndeployment)
          az_size = 'Standard_DS2'
        else 
          OOLog.fatal("Azure size map, '#{size}' not found in Mappings List")
        end
      when 'L-IO'
        if(isUndeployment)
          az_size = 'Standard_DS3'
        else 
          OOLog.fatal("Azure size map, '#{size}' not found in Mappings List")
        end
      else
        OOLog.fatal("Azure size map, '#{size}' not found in Mappings List")
    end

    if az_size =~ /(.*)GS(.*)|(.*)DS(.*)/
      return true
    else
      return false
    end
  end

  def get_resource_tags(node)
    tags = {}
    tags['ApplicationName'] = node.workorder.payLoad.Assembly[0].ciName || 'Unknown'
    tags['OwnerName'] = node.workorder.payLoad.Assembly[0].ciAttributes["owner"] || 'Unknown'
    tags['OwnerTeam'] = node.workorder.payLoad.Organization[0].ciName || 'Unknown'
    tags['NotificationDistList'] = node.workorder.payLoad.Assembly[0].ciAttributes["owner"] || 'Unknown'
    tags['Environment'] = node.workorder.payLoad.Environment[0].ciName || 'Unknown'
    tags['DeploymentType'] = 'OneOps'
    tags['Platform'] = node.workorder.box.ciName || 'Unknown'

    # tags['CostCenter'] =  'Unknown'

    if node.workorder.payLoad.Organization[0].ciAttributes.has_key?('full_name')
      tags['E2EDomain'] = node.workorder.payLoad.Organization[0].ciAttributes["full_name"].split('.').last.strip
    end

    # owner = node.workorder.payLoad.Assembly[0].ciAttributes["owner"] || "Unknown"
    return tags
  end

  def update_resource_tags(creds, subscription_id, resource_group_name, resource, tags)
    OOLog.info("Updating #{resource.name} with tags: #{tags}")
    client = Azure::ARM::Resources::ResourceManagementClient.new(creds)
    client.subscription_id = subscription_id

    type_arr = resource.type.split('/')
    resource_provider = type_arr.shift
    resource_type = type_arr.pop
    resource_parent = '/' + type_arr.join('/')

    case resource_provider
      when /Compute/
        api_version = '2017-03-30'
      when /Network/
        api_version = '2017-03-01'
      when /Storage/
        api_version = '2016-12-01'
    end

    # Get the resource via ResourceManagementClient
    resource = (client.resources.get(resource_group_name, resource_provider, resource_parent,
                                     resource_type, resource.name, api_version).value!).body

    # Add the tags to the resource
    tags.each do |key, value|
      resource.tags[key] = value
    end


    # Update the resource via ResourceManagementClient
    resource = (client.resources.create_or_update(resource_group_name, resource_provider, resource_parent,
                                                  resource_type, resource.name, api_version, resource).value!).body
    OOLog.info("Finished updating #{resource.name}")
    return resource
  end

  module_function :get_credentials,
                  :set_proxy,
                  :set_proxy_from_env,
                  :get_component_name,
                  :get_dns_domain_label,
                  :abbreviate_location,
                  :is_prm,
                  :get_resource_tags,
                  :update_resource_tags

end
