##### APIC Login

provider "aci" {
  username = var.a_username
  password = var.b_password
  url      = "https://devasc-aci-1.cisco.com"
  insecure = false
}

##### Modules

module "pod00069" {
  source = "./modules/vmware-pod"
  pod_id = "pod00069"
  
  interface_map = {
    leafs_301_302 = {
      node_ids   = [301, 302]
      clnt_ports = [1, 2, 3, 4]
    },
    leafs_303_304 = {
      node_ids   = [303, 304]
      clnt_ports = [1, 2]
    }
  }
}

/***
module "openstack" {
  source   = "./modules/openstack-pod"
  for_each = var.openstack_pods

  pod_id    = each.value.pod_id
  pod_nodes = each.value.pod_nodes

  ukcloud_mgmt_tenant = each.value.ukcloud_mgmt_tenant
  ukcloud_mgmt_l3_out = each.value.ukcloud_mgmt_l3_out
  ukcloud_mgmt_vrf    = each.value.ukcloud_mgmt_vrf

  internal_api_bd_subnet      = each.value.internal_api_bd_subnet
  ipmi_bd_subnet              = each.value.ipmi_bd_subnet
  mgmt_bd_subnet              = each.value.mgmt_bd_subnet
  mgmt_provisioning_bd_subnet = each.value.mgmt_provisioning_bd_subnet
  storage_bd_subnet           = each.value.storage_bd_subnet
  storage_mgmt_bd_subnet      = each.value.storage_mgmt_bd_subnet
  tenant_bd_subnet            = each.value.tenant_bd_subnet
  mgmt_openstack_bd_subnet    = each.value.mgmt_openstack_bd_subnet
}
***/