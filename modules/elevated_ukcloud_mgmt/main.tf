#########################
#### Local Variables ####
#########################

locals {
  flattened_elevated_ukcloud_mgmt_ospf = flatten([
    for node_key, node in var.elevated_ukcloud_mgmt_ospf : [
      for interface in node.interfaces : {
        node_key     = node_key
        interface_id = interface.interface_id
        address      = interface.address
      }
    ]
  ])
}

####################################
#### Elevated UKCloud Management ####
####################################

resource "aci_vlan_pool" "elevated_ukcloud_mgmt" {
  name       = "vlan_static_l3_out_elevated_ukcloud_mgmt"
  alloc_mode = "static"
}

resource "aci_ranges" "elevated_ukcloud_mgmt" {
  vlan_pool_dn = aci_vlan_pool.elevated_ukcloud_mgmt.id
  from         = "vlan-3964"
  to           = "vlan-3964"
  alloc_mode   = "static"
}

resource "aci_l3_domain_profile" "elevated_ukcloud_mgmt" {
  name                      = "l3_out_elevated_ukcloud_mgmt"
  relation_infra_rs_vlan_ns = aci_vlan_pool.elevated_ukcloud_mgmt.id
}

resource "aci_tenant" "elevated_ukcloud_mgmt" {
  name = "elevated_ukcloud_mgmt"
}

resource "aci_vrf" "elevated_ukcloud_mgmt" {
  tenant_dn = aci_tenant.elevated_ukcloud_mgmt.id
  name      = "elevated_ukcloud_mgmt"
}

resource "aci_ospf_interface_policy" "elevated_ukcloud_mgmt" {
  tenant_dn = aci_tenant.elevated_ukcloud_mgmt.id
  name      = "ospf_int_p2p_protocol_policy_elevated_ukcloud_mgmt"
  ctrl = [
    "advert-subnet",
    "bfd",
    "mtu-ignore"
  ]
  nw_t = "p2p"
}

resource "aci_l3_outside" "elevated_ukcloud_mgmt" {
  tenant_dn = aci_tenant.elevated_ukcloud_mgmt.id
  name      = "elevated_ukcloud_mgmt"

  relation_l3ext_rs_ectx       = aci_vrf.elevated_ukcloud_mgmt.id
  relation_l3ext_rs_l3_dom_att = aci_l3_domain_profile.elevated_ukcloud_mgmt.id
}

resource "aci_logical_node_profile" "elevated_ukcloud_mgmt" {
  l3_outside_dn = aci_l3_outside.elevated_ukcloud_mgmt.id
  name          = "elevated_ukcloud_mgmt"
}

resource "aci_logical_node_to_fabric_node" "elevated_ukcloud_mgmt" {
  for_each = var.elevated_ukcloud_mgmt_ospf

  logical_node_profile_dn = aci_logical_node_profile.elevated_ukcloud_mgmt.id
  tdn                     = "topology/pod-1/node-${each.key}"
  rtr_id                  = each.value.router_id
}

resource "aci_logical_interface_profile" "elevated_ukcloud_mgmt" {
  logical_node_profile_dn = aci_logical_node_profile.elevated_ukcloud_mgmt.id
  name                    = "ospf_int_profile_elevated_ukcloud_mgmt"
}

resource "aci_l3out_ospf_interface_profile" "elevated_ukcloud_mgmt" {
  logical_interface_profile_dn = aci_logical_interface_profile.elevated_ukcloud_mgmt.id
  auth_key                     = "key"
  auth_key_id                  = "1"
  auth_type                    = "md5"
  relation_ospf_rs_if_pol      = aci_ospf_interface_policy.elevated_ukcloud_mgmt.id
}

resource "aci_l3out_path_attachment" "elevated_ukcloud_mgmt" {
  for_each = {
    for interface in local.flattened_elevated_ukcloud_mgmt_ospf : "${interface.node_key}.${interface.interface_id}" => interface
  }

  logical_interface_profile_dn = aci_logical_interface_profile.elevated_ukcloud_mgmt.id
  target_dn                    = "topology/pod-1/paths-${each.value.node_key}/pathep-[${each.value.interface_id}]"
  if_inst_t                    = "sub-interface"
  addr                         = each.value.address
  encap                        = "vlan-${var.elevated_ukcloud_mgmt_ospf_interface_vlan}"
  encap_scope                  = "local"
  mode                         = "regular"
  mtu                          = "9000"
}

resource "aci_external_network_instance_profile" "elevated_ukcloud_mgmt" {
  l3_outside_dn = aci_l3_outside.elevated_ukcloud_mgmt.id
  name          = "all"
}

resource "aci_l3_ext_subnet" "elevated_ukcloud_mgmt_all" {
  external_network_instance_profile_dn = aci_external_network_instance_profile.elevated_ukcloud_mgmt.id
  ip                                   = "0.0.0.0/0"
}

resource "aci_l3out_ospf_external_policy" "elevated_ukcloud_mgmt" {
  l3_outside_dn = aci_l3_outside.elevated_ukcloud_mgmt.id
  area_cost     = "1"
  area_ctrl     = "redistribute,summary"
  area_id       = var.elevated_ukcloud_mgmt_ospf_area_id
  area_type     = "regular"
}

#######################
#### Output Values ####
#######################

output "tenant" {
  value = aci_tenant.elevated_ukcloud_mgmt.id
}

output "vrf" {
  value = aci_vrf.elevated_ukcloud_mgmt.id
}

output "l3out" {
  value = aci_l3_outside.elevated_ukcloud_mgmt.id
}