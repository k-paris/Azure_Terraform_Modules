variable "vnets" {
  description = "The list of virtual networks objects to be created. Each entry should include the name, address_ space, and whether it is a hub network."
  type = list(object({
    name          = string
    address_space = string
    # default value for is_hub is false
    is_hub = bool # Default value for is_hub is false

    subnets = optional(list(object({
      name           = string
      address_prefix = string
      # default value for service_endpoints is null
      service_endpoints = optional(list(string), null)
      # default value for delegation is null
      delegation = optional(object({
        name                    = string
        service_delegation_name = string
        actions                 = optional(list(string), null)
      }), null)

    })))
  }))
  # validation {
  #   condition     = alltrue([for vnet in var.vnets : (vnet.name != null && vnet.name != "") && (vnet.address_space != null && vnet.address_space != "")])
  #   error_message = "Each virtual network must have a name and an address space defined. A list of virtual network objects must be provided: [{name = string, address_space = string, is_hub = bool}]."
  # }
  validation {
    # Ensure that at least one virtual network is marked as a hub
    condition     = anytrue([for vnet in var.vnets : vnet.is_hub == true])
    error_message = "At least one virtual network must be marked as a hub (is_hub = true)."
  }
  validation {
    # Ensure that only one virtual network can be marked as a hub
    condition     = length([for vnet in var.vnets : vnet.is_hub == true]) > 1
    error_message = "Only one virtual network can be marked as a hub (is_hub = true)."
  }
}


variable "location" {
  description = "The Azure region where the virtual network will be created."
  type        = string
  validation {
    condition     = can(var.location)
    error_message = "The location must must not be null or empty."
  }
}
variable "resource_group_name" {
  description = "The name of the resource group where the virtual network will be created."
  type        = string
  validation {
    condition     = can(var.resource_group_name)
    error_message = "The resource group name must not be null or empty."
  }
}

variable "create_resource_group" {
  description = "Flag to indicate whether to create a new resource group for the virtual network. If false, the resource group must already exist."
  type        = bool
  default     = false

}

variable "ddos_protection_plan_enabled" {
  description = "Flag to enable DDoS protection plan for the hub virtual network."
  type        = bool
  default     = false
}

variable "ddos_protection_plan_id" {
  description = "The ID of the DDoS protection plan to be associated with the hub virtual network. Default is null, if this value is not passed a new plan will be created if `ddos_protection_plan_enabled` is true."
  type        = string
  default     = null
}

variable "ddos_protection_plan_name" {
  description = "The name of the DDoS protection plan to be created if `ddos_protection_plan_enabled` is true and `ddos_protection_plan_id` is null."
  type        = string
  default     = "vnet-ddos-protection-plan"
}

variable "create_vpn_gateway" {
  description = "Flag to indicate whether to create a VPN gateway for the hub virtual network."
  type        = bool
  default     = false
  validation {
    # check if within var.vnets, at least one subnet has the name 'GatewaySubnet'
    condition     = !var.create_vpn_gateway || anytrue([for vnet in var.vnets : anytrue([for subnet in vnet.subnets : subnet.name == "GatewaySubnet"])])
    error_message = "If create_vpn_gateway is true, at least one subnet must be named 'GatewaySubnet' in the hub virtual network."
  }
}

variable "vpn_public_ip_id" {
  description = "The ID of the public IP address to be associated with the VPN gateway."
  type        = string
  default     = null
}

variable "vpn_public_ip_name" {
  description = "The name of the public IP address to be created for the VPN gateway if `vpn_public_ip_id` is null."
  type        = string
  default     = "vpn-gateway-ip"
}

variable "vpn_public_ip_allocation_method" {
  description = "The allocation method for the VPN gateway public IP address. Default is 'Static'."
  type        = string
  default     = "Static"
  validation {
    condition     = can(var.vpn_public_ip_allocation_method) && (var.vpn_public_ip_allocation_method == "Static" || var.vpn_public_ip_allocation_method == "Dynamic")
    error_message = "The VPN public IP allocation method must be either 'Static' or 'Dynamic'."
  }
}

variable "vpn_public_ip_sku" {
  description = "The SKU for the VPN gateway public IP address. Default is 'Standard'."
  type        = string
  default     = "Standard"
  validation {
    condition     = can(var.vpn_public_ip_sku) && (var.vpn_public_ip_sku == "Basic" || var.vpn_public_ip_sku == "Standard")
    error_message = "The VPN public IP SKU must be either 'Basic' or 'Standard'."
  }

  # validation {
  #   # if allocation_method is 'Static', sku must be 'Standard'
  #   condition     = var.vpn_public_ip_allocation_method == "Static" ? var.vpn_public_ip_sku == "Standard" : true  
  #   error_message = "If the VPN public IP allocation method is 'Static', the SKU must be 'Standard'."
  # }

}


variable "vpn_gateway" {
  description = "The configuration for the VPN gateway"
  type = object({
    name                                  = string
    location                              = string
    resource_group_name                   = string
    sku                                   = string
    type                                  = string
    vpn_type                              = string
    active_active                         = optional(bool, false)
    enable_bgp                            = optional(bool, false)
    default_local_network_gateway_id      = optional(string, null)
    generation                            = optional(string, null)
    private_ip_address_enabled            = optional(bool, null)
    bgp_route_translation_for_nat_enabled = optional(bool, false)
    dns_forwarding_enabled                = optional(bool, null)
    ip_sec_replay_protection_enabled      = optional(bool, null)
    remote_vnet_traffic_enabled           = optional(bool, false)
    virtual_wan_traffic_enabled           = optional(bool, false)

    bgp_settings = optional(object({
      asn         = optional(number, null)
      peer_weight = optional(number, null)

      peering_addresses = optional(list(object({
        ip_configuration_name = string
        apipa_addresses       = optional(list(string), null)
      })), null)

    }), null)

    ip_configuration = object({
      name                          = string
      public_ip_address_id          = optional(string, null)
      private_ip_address_allocation = string
      subnet_id                     = optional(string, null)
    })

    custom_routes = optional(object({
      address_prefixes = list(string)
    }), null)

    vpn_client_configuration = optional(object({
      address_space         = list(string)
      vpn_auth_types        = optional(list(string), null)
      aad_tenant            = optional(string, null)
      aad_audience          = optional(string, null)
      aad_issuer            = optional(string, null)
      vpn_client_protocols  = optional(list(string), null)
      radius_server_address = optional(string, null)
      radius_server_secret  = optional(string, null)


      root_certificates = optional(object({
        name             = string
        public_cert_data = string
      }), null)

      revoked_certificates = optional(object({
        name       = string
        thumbprint = string
      }), null)

      virtual_network_gateway_client_connection = optional(object({
        name               = string
        policy_group_names = optional(list(string), null)
        address_prefixes   = optional(list(string), null)
      }), null)

      ipsec_policy = optional(object({
        dh_group                  = optional(string, null)
        ike_encryption            = optional(string, null)
        ike_integrity             = optional(string, null)
        ipsec_encryption          = optional(string, null)
        ipsec_integrity           = optional(string, null)
        pfs_group                 = optional(string, null)
        sa_lifetime_in_seconds    = optional(number, null)
        sa_data_size_in_kilobytes = optional(number, null)
      }), null)

    }), null)

  })

  default = null

  # validation {
  #   # Ensure that type is either 'Vpn' or 'ExpressRoute'
  #   condition     = can(var.vpn_gateway.type) && (var.vpn_gateway.type == "Vpn" || var.vpn_gateway.type == "ExpressRoute")
  #   error_message = "The VPN gateway type must be either 'Vpn' or 'ExpressRoute'."
  # }

  # validation {
  #   # if active_active is true then HighPerformance or UltraPerformance SKU must be used
  #   condition     = !var.vpn_gateway.active_active || (var.vpn_gateway.sku == "HighPerformance" || var.vpn_gateway.sku == "UltraPerformance")
  #   error_message = "If active_active is true, the VPN gateway SKU must be 'HighPerformance' or 'UltraPerformance'."
  # }

  # validation {
  #   # Ensure that auth_types is one of the allowed values: AAD, Radius, Certificate
  #   condition     = !can(var.vpn_gateway.vpn_client_configuration) || alltrue([for auth_type in var.vpn_gateway.vpn_client_configuration.vpn_auth_types : auth_type == "AAD" || auth_type == "Radius" || auth_type == "Certificate"])
  #   error_message = "The VPN client authentication types must be one of the following: AAD, Radius, Certificate."
  # }
}