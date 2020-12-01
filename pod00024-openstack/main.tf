##### APIC Login

  provider "aci" {
    username = "admin"
    password = "ciscopsdt"
    url      = "https://sandboxapicdc.cisco.com"
    insecure = false
  }

##### Modules

module "pod00024-openstack" {
  source    = "./modules/openstack-pod"
  for_each  = var.openstack_pods
  pod_id    = each.value.pod_id
  pod_nodes = each.value.pod_nodes
}