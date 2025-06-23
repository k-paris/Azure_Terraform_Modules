# ------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------   DDOS Protection Plan  -----------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------

# This module creates a DDoS protection plan if `ddos_protection_plan_enabled` is true and no plan ID is provided.

resource "azurerm_network_ddos_protection_plan" "vnet_ddos_plan" {
  # This resource is created only if DDoS protection is enabled and no plan ID is provided
  count               = var.ddos_protection_plan_enabled == true && var.ddos_protection_plan_id == null ? 1 : 0
  name                = var.ddos_protection_plan_name
  location            = var.location
  resource_group_name = var.resource_group_name
}

# ------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------   Resource Group  -----------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------


resource "azurerm_resource_group" "rg" {
  # create a resource group only if `create_resource_group` is true
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
}

# ------------------------------------------------------------------------------------------------------------------------
# -----------------------------------------------   Virtual Networks  ----------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------

resource "null_resource" "wait_for_resource_group" {
  # This resource is used to ensure that the VNet creation starts after the resource group is created if `create_resource_group` is true
  triggers = {
    id = var.create_resource_group ? azurerm_resource_group.rg[0].id : 0
  }
  # provisioner "local-exec" {
  #   command = "echo 'Starting VNet creation...'"
  # }
}

resource "azurerm_virtual_network" "vnets" {
  for_each            = { for vnet in var.vnets : vnet.name => vnet }
  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["${each.value.address_space}"]

  depends_on = [null_resource.wait_for_resource_group]

  dynamic "ddos_protection_plan" {
    for_each = var.ddos_protection_plan_enabled ? [1] : []
    content {
      # if `ddos_protection_plan_id` is provided, use it; otherwise, use the ID of the created DDoS protection plan
      id     = var.ddos_protection_plan_id != null ? var.ddos_protection_plan_id : azurerm_network_ddos_protection_plan.vnet_ddos_plan[0].id
      enable = true
    }
  }
}

# ------------------------------------------------------------------------------------------------------------------------
# ---------------------------------------------------   Subnets  ---------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------

# --------------------   Local Variables   --------------------


# Local variables to flatten the list of subnets and create a mapping of subnet names 
# to their corresponding virtual network names

locals {
  # Flatten the list of subnets from all virtual networks
  # and filter out any null subnets
  subnets           = [for vnet in var.vnets : vnet.subnets if vnet.subnets != null]
  flattened_subnets = flatten(local.subnets)
  # Create a map of subnet names to their corresponding virtual network names
  subnet_to_vnet_map = {
    for pair in flatten([
      for vnet in var.vnets : [
        for subnet in vnet.subnets != null ? vnet.subnets : [] : {
          subnet_name = subnet.name
          vnet_name   = vnet.name
        }
      ]
    ]) : pair.subnet_name => pair.vnet_name
  }
}

# --------------------   Create Subnets   --------------------

resource "azurerm_subnet" "subnets" {
  # Create subnets for each virtual network, iterating over the flattened list of subnets
  for_each            = { for subnet in local.flattened_subnets : "${subnet.name}" => subnet }
  name                = each.value.name
  resource_group_name = var.resource_group_name
  # Use the subnet name to find the corresponding virtual network name from the local map
  virtual_network_name = local.subnet_to_vnet_map[each.value.name]
  address_prefixes     = [each.value.address_prefix]

  service_endpoints = each.value.service_endpoints != null ? each.value.service_endpoints : []

  dynamic "delegation" {
    for_each = each.value.delegation != null ? [each.value.delegation] : []
    content {
      name = delegation.value.name

      service_delegation {
        name    = delegation.value.service_delegation_name
        actions = delegation.value.actions != null ? delegation.value.actions : []
      }
    }
  }

  depends_on = [azurerm_virtual_network.vnets]
}

# ------------------------------------------------------------------------------------------------------------------------
# -----------------------------------------------   Virtual Network Gateway  ---------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------

resource "azurerm_public_ip" "vpn-gateway-ip" {
  # create a public IP for the VPN gateway only if `create_vpn_gateway` is true
  count               = var.create_vpn_gateway && var.vpn_public_ip_id == null ? 1 : 0
  name                = var.vpn_public_ip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = var.vpn_public_ip_allocation_method
  sku                 = var.vpn_public_ip_sku
}

resource "azurerm_virtual_network_gateway" "vpn-gateway" {
  count               = var.create_vpn_gateway ? 1 : 0
  name                = var.vpn_gateway.name
  location            = var.location
  resource_group_name = var.resource_group_name
  type                = var.vpn_gateway.type
  vpn_type            = var.vpn_gateway.vpn_type
  sku                 = var.vpn_gateway.sku
  active_active       = var.vpn_gateway.active_active
  enable_bgp          = var.vpn_gateway.enable_bgp
  generation          = var.vpn_gateway.generation

  ip_configuration {
    name                          = var.vpn_gateway.ip_configuration.name
    public_ip_address_id          = var.vpn_public_ip_id != null ? var.vpn_public_ip_id : (length(azurerm_public_ip.vpn-gateway-ip) > 0 ? azurerm_public_ip.vpn-gateway-ip[0].id : null)
    private_ip_address_allocation = var.vpn_gateway.ip_configuration.private_ip_address_allocation
    subnet_id                     = azurerm_subnet.subnets["GatewaySubnet"].id
  }

  dynamic "bgp_settings" {
    for_each = lookup(var.vpn_gateway, "bgp_settings", null) != null ? [var.vpn_gateway.bgp_settings] : []
    content {
      asn = bgp_settings.value.asn

      dynamic "peering_addresses" {
        for_each = lookup(bgp_settings.value, "peering_addresses", [])
        content {
          ip_configuration_name = peering_addresses.value.ip_configuration_name
          apipa_addresses       = lookup(peering_addresses.value, "apipa_addresses", null)
        }
      }

      peer_weight = lookup(bgp_settings.value, "peer_weight", null)
    }
  }

  dynamic "custom_route" {
    for_each = lookup(var.vpn_gateway, "custom_route", null) != null ? [var.vpn_gateway.custom_route] : []
    content {
      address_prefixes = custom_route.value.address_prefixes
    }
  }

  dynamic "vpn_client_configuration" {
    for_each = lookup(var.vpn_gateway, "vpn_client_configuration", null) != null ? [var.vpn_gateway.vpn_client_configuration] : []
    content {
      address_space = vpn_client_configuration.value.address_space

      dynamic "root_certificate" {
        # Fix: Handle null values by providing empty list as fallback
        for_each = lookup(vpn_client_configuration.value, "root_certificates", null) != null ? [vpn_client_configuration.value.root_certificates] : []
        content {
          name             = root_certificate.value.name
          public_cert_data = root_certificate.value.public_cert_data
        }
      }

      dynamic "revoked_certificate" {
        # Fix: Handle null values by providing empty list as fallback
        for_each = lookup(vpn_client_configuration.value, "revoked_certificates", null) != null ? [vpn_client_configuration.value.revoked_certificates] : []
        content {
          name       = revoked_certificate.value.name
          thumbprint = revoked_certificate.value.thumbprint
        }
      }

      dynamic "ipsec_policy" {
        # Fix: Handle null values by providing empty list as fallback
        for_each = lookup(vpn_client_configuration.value, "ipsec_policy", null) != null ? [vpn_client_configuration.value.ipsec_policy] : []
        content {
          sa_lifetime_in_seconds    = lookup(ipsec_policy.value, "sa_lifetime_in_seconds", null)
          sa_data_size_in_kilobytes = lookup(ipsec_policy.value, "sa_data_size_in_kilobytes", null)
          ipsec_encryption          = lookup(ipsec_policy.value, "ipsec_encryption", null)
          ipsec_integrity           = lookup(ipsec_policy.value, "ipsec_integrity", null)
          ike_encryption            = lookup(ipsec_policy.value, "ike_encryption", null)
          ike_integrity             = lookup(ipsec_policy.value, "ike_integrity", null)
          dh_group                  = lookup(ipsec_policy.value, "dh_group", null)
          pfs_group                 = lookup(ipsec_policy.value, "pfs_group", null)
        }
      }

      dynamic "virtual_network_gateway_client_connection" {
        for_each = lookup(vpn_client_configuration.value, "virtual_network_gateway_client_connection", null) != null ? [vpn_client_configuration.value.virtual_network_gateway_client_connection] : []
        content {
          name               = virtual_network_gateway_client_connection.value.name
          policy_group_names = lookup(virtual_network_gateway_client_connection.value, "policy_group_names", null)
          address_prefixes   = lookup(virtual_network_gateway_client_connection.value, "address_prefixes", null)
        }
      }

      vpn_client_protocols  = lookup(vpn_client_configuration.value, "vpn_client_protocols", null)
      vpn_auth_types        = lookup(vpn_client_configuration.value, "vpn_auth_types", null)
      // aad_tenant =>  "https://login.microsoftonline.com/${var.tenant_id}"
      aad_tenant            = lookup(vpn_client_configuration.value, "aad_tenant", null)
      aad_audience          = lookup(vpn_client_configuration.value, "aad_audience", null)
      aad_issuer            = lookup(vpn_client_configuration.value, "aad_issuer", null)
      radius_server_address = lookup(vpn_client_configuration.value, "radius_server_address", null)
      radius_server_secret  = lookup(vpn_client_configuration.value, "radius_server_secret", null)
    }
  }

  depends_on = [
    azurerm_subnet.subnets,
    azurerm_public_ip.vpn-gateway-ip
  ]
}


# ------------------------------------------------------------------------------------------------------------------------
# -----------------------------------------------   Virtual Network Peering  ----------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------

resource "null_resource" "wait_for_vpn_gateway" {
  # This resource is used to ensure that the VNet peering is created after the VPN gateway
  triggers = {
    id = var.create_vpn_gateway ? azurerm_virtual_network_gateway.vpn-gateway[0].id : 0
  }
  # provisioner "local-exec" {
  #   command = "echo 'Starting VNet peering...'"
  # }
}

locals {
  hub_vnet   = [for vnet in var.vnets : vnet.name if vnet.is_hub]
  spoke_vnet = { for vnet in var.vnets : vnet.name => vnet if !vnet.is_hub }
}

# vnet peering for hub to spokes
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  for_each = local.spoke_vnet

  name                      = "${local.hub_vnet[0]}-to-${each.value.name}-peering"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = local.hub_vnet[0]
  remote_virtual_network_id = azurerm_virtual_network.vnets[each.value.name].id

  allow_forwarded_traffic = true
  # allow_gateway_transit is set to true if create_vpn_gateway is true, otherwise false
  allow_gateway_transit = var.create_vpn_gateway ? true : false
  use_remote_gateways   = false

  # if create_vpn_gateway is true, first create the vpn gateway before creating the peering
  depends_on = [null_resource.wait_for_vpn_gateway]
}

# vnet peering for spokes to hub
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  for_each = local.spoke_vnet

  name                      = "${each.value.name}-to-${local.hub_vnet[0]}-peering"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = each.value.name
  remote_virtual_network_id = azurerm_virtual_network.vnets[local.hub_vnet[0]].id

  allow_forwarded_traffic = true
  # allow_gateway_transit is set to false for spoke to hub peering
  allow_gateway_transit = false
  use_remote_gateways   = var.create_vpn_gateway ? true : false

  # if create_vpn_gateway is true, first create the vpn gateway before creating the peering
  depends_on = [null_resource.wait_for_vpn_gateway]
}