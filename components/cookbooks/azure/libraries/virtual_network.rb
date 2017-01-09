require 'fog/azurerm'
require 'chef'

require ::File.expand_path('../../../azure_base/libraries/logger', __FILE__)


# module to contain classes for dealing with the Azure Network features.
module AzureNetwork
  # Class that defines the functions for manipulating virtual networks in Azure
  class VirtualNetwork
    attr_accessor :location,
                  :name,
                  :address,
                  :sub_address,
                  :dns_list,
                  :network_client
    attr_reader :creds, :subscription

    def initialize(creds, subscription)
      @creds = creds
      tenant_id = creds[:tenant_id]
      client_secret = creds[:client_secret]
      client_id = creds[:client_id]
      @subscription = subscription
      @network_client = Fog::Network::AzureRM.new(client_id: client_id, client_secret: client_secret, tenant_id: tenant_id, subscription_id: subscription)
    end

    # this method creates the vnet object that is later passed in to create
    # the vnet
    def build_network_object
      OOLog.info("network_address: #{@address}")

      ns_list = []
      @dns_list.each do |dns_list|
        OOLog.info('dns address[' + @dns_list.index(dns_list).to_s + ']: ' + dns_list.strip)
        ns_list.push(dns_list.strip)
      end

      subnet = AzureNetwork::Subnet.new(@creds, @subscription)
      subnet.sub_address = @sub_address
      subnet.name = @name
      sub_nets = subnet.build_subnet_object

      virtual_network = Fog::Network::AzureRM::VirtualNetwork.new
      virtual_network.location = @location
      virtual_network.address_prefixes = [@address]
      virtual_network.dns_servers = ns_list unless ns_list.nil?
      virtual_network.subnets = sub_nets

      virtual_network
    end

    # this will create/update the vnet
    def create_update(resource_group_name, virtual_network)
      OOLog.info("Creating Virtual Network '#{@name}' ...")
      start_time = Time.now.to_i
      begin
        response = @network_client.virtual_networks.create(name: @name,
                                                           location: virtual_network.location,
                                                           resource_group: resource_group_name,
                                                           subnets: virtual_network.subnets,
                                                           dns_servers: virtual_network.dns_servers,
                                                           address_prefixes: virtual_network.address_prefixes)
      rescue MsRestAzure::AzureOperationError => e
        OOLog.fatal("Failed creating/updating vnet: #{@name} with exception #{e.body}")
      rescue => ex
        OOLog.fatal("Failed creating/updating vnet: #{@name} with exception #{ex.message}")
      end
      end_time = Time.now.to_i
      duration = end_time - start_time
      OOLog.info('Successfully created/updated network name: ' + @name + "\nOperation took #{duration} seconds")
      response
    end

    # this method will return a vnet from the name given in the resource group
    def get(resource_group_name)
      OOLog.fatal('VNET name is nil. It is required.') if @name.nil?
      OOLog.info("Getting Virtual Network '#{@name}' ...")
      start_time = Time.now.to_i
      begin
        response = @network_client.virtual_networks.get(resource_group_name, @name)
      rescue MsRestAzure::AzureOperationError => e
        OOLog.fatal("Error getting virtual network: #{@name} from resource group #{resource_group_name}.  Exception: #{e.body}")
      rescue => ex
        OOLog.fatal("Error getting virtual network: #{@name} from resource group #{resource_group_name}.  Exception: #{ex.message}")
      end

      end_time = Time.now.to_i
      duration = end_time - start_time
      OOLog.info("operation took #{duration} seconds")
      response
    end

    # this method will return a list of vnets from the resource group
    def list(resource_group_name)
      OOLog.info("Getting vnets from Resource Group '#{resource_group_name}' ...")
      start_time = Time.now.to_i
      begin
        response = @network_client.virtual_networks(resource_group: resource_group_name)
      rescue MsRestAzure::AzureOperationError => e
        OOLog.fatal("Error getting all vnets for resource group. Exception: #{e.body}")
      rescue => ex
        OOLog.fatal("Error getting all vnets for resource group. Exception: #{ex.message}")
      end
      end_time = Time.now.to_i
      duration = end_time - start_time
      OOLog.info("operation took #{duration} seconds")
      response
    end

    # this method will return a list of vnets from the subscription
    def list_all
      OOLog.info('Getting subscription vnets ...')
      start_time = Time.now.to_i
      begin
        response = @network_client.virtual_networks
      rescue MsRestAzure::AzureOperationError => e
        OOLog.fatal("Error getting all vnets for the sub. Exception: #{e.body}")
      rescue => ex
        OOLog.fatal("Error getting all vnets for the sub. Exception: #{ex.message}")
      end
      end_time = Time.now.to_i
      duration = end_time - start_time
      OOLog.info("operation took #{duration} seconds")
      response
    end

    # this method will return a vnet from the name given in the resource group
    def exists?(resource_group_name)
      OOLog.fatal('VNET name is nil. It is required.') if @name.nil?
      OOLog.info("Checking if Virtual Network '#{@name}' Exists! ...")
      begin
        @network_client.virtual_networks.check_virtual_network_exists?(resource_group_name, @name)
      rescue MsRestAzure::AzureOperationError => e
        OOLog.info("Exception from Azure: #{e.body}")
          OOLog.fatal("Error getting virtual network: #{@name} from resource group #{resource_group_name}.  Exception: #{e.body}")
      rescue => ex
        OOLog.fatal("Error getting virtual network: #{@name} from resource group #{resource_group_name}.  Exception: #{ex.message}")
      end
      OOLog.info('VNET EXISTS!!')
      true
    end
  end # end of class
end
