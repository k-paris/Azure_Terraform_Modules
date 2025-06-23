# Create a map of virtual network names to their IDs using zipmap([vnet_names], [vnet_ids])
output "vnet-ids" {
  value = { for k, v in azurerm_virtual_network.vnets :
    k => v.id
  }
}

output "ddos_protection_plan_id" {
  value = var.ddos_protection_plan_id != null ? var.ddos_protection_plan_id : (length(azurerm_network_ddos_protection_plan.vnet_ddos_plan) > 0 ? azurerm_network_ddos_protection_plan.vnet_ddos_plan[0].id : null)
}

# output resource group id if create_resource_group is true
output "resource_group_id" {
  value = var.create_resource_group ? (length(azurerm_resource_group.rg) > 0 ? azurerm_resource_group.rg[0].id : null) : null
}

output "subnet-ids" {
  value = { for k, v in azurerm_subnet.subnets :
    k => v.id
  }
}