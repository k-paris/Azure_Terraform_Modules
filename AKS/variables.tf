variable "name" {
  description = "The name of the AKS cluster"
  type = string
  validation {
    condition     = can(var.name)
    error_message = "The location must must not be null or empty."
  }
}

variable "location" {
  description = "The location of hte resource group in which the AKS cluster will be created"
  type = string
  validation {
    condition = can(var.location)
    error_message = "The location must must not be null or empty."
  }
}

variable "resource_group_name" {
  description = "The name of the resource group in which the AKS cluster will be created"
  type = string
  validation {
    condition     = can(var.resource_group_name)
    error_message = "The resource group name must not be null or empty."
  }
}

variable "sku_tier" {
  description = <<EOT
  (Optional) The SKU tier of the managed cluster. Possible values are:
  - Free
  - Standard
  - Premium
  - etc..
  Default: Standard
  EOT
  type = string
  default = "Standard"
#   validation {
#     condition     = contains(["Free", "Paid"], var.sku_tier)
#     error_message = "The SKU tier must be either 'Free' or 'Paid'."
#   }
}

variable "dns_prefix" {
  description = <<EOT
  (Optional) The DNS prefix specified when creating the managed cluster. Possible values must begin 
  and end with a letter or number contain only letters, numbers, and hyphens, and be between
  1 and 54 chracters in length.
  Default: null
  EOT
  type = string
  default = null
}

variable "dns_prefix_private_cluster" {
  description = <<EOT
  (Optional) Specifies the DNS prefix to use with the private cluster.
  Default: null
  EOT
  type = string
  default = null
}
variable "kubernetes_version" {
  description = "The version of Kubernetes to use for the AKS cluster"
  type = string
  default = null
}

variable "oidc_issuer_enabled" {
  description = <<EOT
  (Optional) Should the AKS cluster have OIDC issuer enabled?
  Default: false
  EOT
  type = bool
  default = false
}

variable "workload_identity_enabled" {
  description = <<EOT
  (Optional) Should the AKS cluster have workload identity enabled?
  Default: false
  EOT
  type = bool
  default = false
}

variable "private_dns_zone_id" {
  type = string
}
variable "default_node_pool_name" {
  description = "The name of the default node pool"
  type = string
  default = "systempool"
}
variable "default_node_pool_node_count" {
  description = "The number of nodes in the default node pool"
  type = number
  default = null
}
variable "default_node_pool_vm_size" {
  description = "The size of the VMs in the default node pool"
  type = string
  default = "Standard_DS2_v2"
}
variable "default_node_pool_type" {
  description = <<EOT
  (Optional) The type of the default node pool. Possible values are:
  - AvailabilitySet
  - VirtualMachineScaleSets
  Default: VirtualMachineScaleSets
  EOT
  type = string
  default = "VirtualMachineScaleSets"
  # validation {
  #   condition = contains(["AvailabilitySet", "VirtualMachineScaleSets"], var.default_node_pool_type)
  #   error_message = "Invalid value for 'default_node_pool_type'."
  # }
}
variable "default_node_pool_os_sku" {
  description = <<EOT
  The SKU of the OS in the default node pool
  Available options are:
    - Ubuntu
    - AzureLinux
    - Windows2019
    - Windows2022
  Default: Ubuntu
  EOT
  type = string
  default = "Ubuntu"
  # validation {
  #     condition = contains(["Ubuntu", "AzureLinux", "Windows2019", "Windows2022"], var.default_node_pool_os_sku)
  #     error_message = "Invalid value for 'default_node_pool_os_sku'."
  # }
} 
variable "default_node_pool_os_disk_type" {
  description = <<EOT
  (Optional) The type of the OS disk in the default node pool
  available options are:
    - Ephemeral
    - Managed
    Default: Managed
  EOT
  type = string
  default = "Managed"
  # validation {
  #   condition = contains(["Ephemeral", "Managed"], var.default_node_pool_os_disk_type)
  #   error_message = "Invalid value for 'default_node_pool_os_disk_type'."
  # }
  
}
variable "default_node_pool_os_disk_size_gb" {
  description = "The size of the OS disk in GB in the default node pool"
  type = number
  default = null
}
variable "default_node_pool_zones" {
  description = <<EOT
  (Optional) A list of availability zones in which the default node pool should be created.
  This requires that the type is set to VirtualMachineScaleSets 
  and that load_balancer_sku is set to Standard.
  Default: null
  EOT
  type = list(string)
  default = null
}
variable "default_node_pool_auto_scaling_enabled" {
  description = <<EOT
  (Optional) Should the default node pool have auto-scaling enabled?
  This requires that the type is set to VirtualMachineScaleSets.
  Default: null
  EOT
  type = bool
  default = true
}
variable "default_node_pool_min_count" {
  description = <<EOT
  (Optional) The minimum number of nodes in the default node pool.
  This requires that the type is set to VirtualMachineScaleSets and that auto_scaling_enabled is set to true.
  Default: null
  EOT
  type = number
  default = 2
}
variable "default_node_pool_max_count" {
  description = <<EOT
  (Optional) The maximum number of nodes in the default node pool.
  This requires that the type is set to VirtualMachineScaleSets and that auto_scaling_enabled is set to true.
  Default: null
  EOT
  type = number
  default = 3
}
variable "default_node_pool_vnet_subnet_id" {
  type = string
}
variable "private_cluster_enabled" {
  description = <<EOT
  (Optional) Should the AKS cluster have its API server only exposed on internal IP addresses?
  This provides a Private IP Address for the Kubernetes API o the Virtual Network where the 
  Kubernetes Cluster is located.
  Default: false
  EOT
  type = bool
  default = false
}
variable "identity_type" {
  description = <<EOT
  (Optional) The identity type to use for the AKS cluster. Possible values are:
  - SystemAssigned
  - ServicePrincipal
  Default: SystemAssigned
  EOT
  type = string
  default = "SystemAssigned"
  # validation {
  #   condition = contains(["SystemAssigned", "ServicePrincipal", "UserAssigned"], var.identity_type)
  #   error_message = "Invalid value for 'identity_type'."
  # }
}
variable "identity_ids" {
  type =list(string)
}
variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type = map(string)
  default = {}
}
variable "azure_policy_enabled" {
  description = <<EOT
  (Optional) Should the AKS cluster have Azure Policy enabled?
  Default: false
  EOT
  type = bool
  default = null
  
}
variable "private_cluster_public_fqdn_enabled" {
  description = <<EOT
  (Optional) Should the AKS cluster have a public FQDN?
  Default: false
  EOT
  type = bool
  default = false
}
variable "role_based_access_control_enabled" {
  description = <<EOT
  (Optional) Should the AKS cluster have Role Based Access Control enabled?
  Default: true
  EOT
  type = bool
  default = true
  # validation {
  #   condition = contains([true, false], var.role_based_access_control_enabled)
  #   error_message = "Invalid value for 'role_based_access_control_enabled'."
  # }
}

variable "network_plugin" {
  description = <<EOT
  (Optional) The network plugin to use for the AKS cluster. Possible values are:
  - azure
  - kubenet
  Default: kubenet
  When network_plugin is set to azure - the pod_cidr field must not be set, unless specifying
  network_plugin_mode to overlay.
  EOT
  type = string
  default = "kubenet"
  # validation {
  #   condition = contains(["azure", "kubenet"], var.network_plugin)
  #   error_message = "Invalid value for 'network_plugin'."
  # }  
}

variable "network_policy" {
  description = <<EOT
  (Optional) The network policy to use for the AKS cluster. Possible values are:
  - azure
  - calico
  - cilium
  Default: null
  When network_policy is set to azure - the network_plugin field must be set to azure.
  When network_policy is set to cilium, the network_data_plane field must be set to cilium.
  EOT
  type = string
  default = null
  # validation {
  #   condition = var.network_policy == null || contains(["azure", "calico", "cilium"], var.network_policy)
  #   error_message = "Invalid value for 'network_policy'."
  # }  
}
variable "dns_service_ip" {
  description = <<EOT
  (Optional) An IP address within the Kubernetes service address range that will be used
  by cluster service discovery (kube-dns).
  Default: null
  EOT
  type = string
  default = null
}
variable "network_data_plane" {
  description = <<EOT
  (Optional) The network data plane to use for the AKS cluster. Possible values are:
  - azure
  - cilium
  Default: null
  When network_data_plane is set to cilium - the network_plugin field must be set to azure.
  When network_data_plane is set to clilum, one of either network_plugin_mode = 'overlay' or
  pod_subnet_id must be set.
  EOT
  type = string
  default = null
  # validation {
  #   condition = var.network_data_plane == null || contains(["azure", "cilium"], var.network_data_plane)
  #   error_message = "Invalid value for 'network_data_plane'."
  # }  
}
variable "network_plugin_mode" {
  description = <<EOT
  (Optional) The network plugin mode to use for the AKS cluster. Possible values are:
  - overlay
  Default: null
  When network_plugin_mode is set to overlay - the network_plugin field must be set to azure.
  When upgrading from Azure CNI without overlay, pod_subnet_id must be specified.
  EOT
  type = string
  default = null
  # validation {
  #   condition = var.network_plugin_mode == null || var.network_plugin_mode == "overlay"
  #   error_message = "Invalid value for 'network_plugin_mode'."
  # }  
}
variable "outbound_type" {
  description = <<EOT
  (Optional) The outbound type to use for the AKS cluster. 
  Possible values are:
  - loadBalancer
  - userDefinedRouting
  - managedNATGateway
  - userAssignedNATGateway
  Default: loadBalancer
  EOT
  type = string
  default = "loadBalancer"
  # validation {
  #   condition = contains(["loadBalancer", "userDefinedRouting", "managedNATGateway", "userAssignedNATGateway"], var.outbound_type)
  #   error_message = "Invalid value for 'outbound_type'."
  # }  
}
variable "pod_cidr" {
  description = <<EOT
  (Optional) The CIDR to use for pod IP addresses. 
  Default: null
  EOT
  type = string
  default = null  
}
variable "service_cidr" {
  description = <<EOT
  (Optional) The Network Range to use for the services in the AKS cluster.
  Default: null
  EOT
  type = string
  default = null
}
variable "load_balancer_sku" {
  description = <<EOT
  (Optional) The SKU of the Load Balancer to use for the AKS cluster. 
  Possible values are:
  - basic
  - standard
  Default: Standard
  EOT
  type = string
  default = "standard"
  # validation {
  #   condition = contains(["Basic", "Standard"], var.load_balancer_sku)
  #   error_message = "Invalid value for 'load_balancer_sku'."
  # }  
}
variable "log_analytics_workspace_id" {
  type = string
  default = null
}
variable "gateway_id" {
  type = string
  default = null  
}
variable "local_account_disabled" {
  type = bool
  default = true
}

variable "tenant_id" {
  type = string
}
variable "admin_group_object_ids" {
  type = list(string)
}
variable "azure_rbac_enabled" {
  type = bool
  default = true
}