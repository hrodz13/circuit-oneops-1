os_disk_blobname = (node['vhd_uri'].split("/").last)
OOLog.info("Deleting os_disk : #{os_disk_blobname}")

base_manager = AzureBase::AzureBaseManager.new(node)

dd_manager = Datadisk.new(base_manager.creds, node['storage_account'], node['platform-resource-group'], nil, nil)
dd_manager.set_storage_account_service(base_manager.creds)
dd_manager.delete_disk_by_name(os_disk_blobname)

if node['datadisk_uri'] != nil
data_disk_blobname = (node['datadisk_uri'].split("/").last)

  if data_disk_blobname.include?(node['storage_account'])
    OOLog.info("Deleting data_disk : #{data_disk_blobname}")
    dd_manager.delete_disk_by_name(data_disk_blobname)    
  end
end