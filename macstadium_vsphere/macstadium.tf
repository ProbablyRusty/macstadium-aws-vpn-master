provider "vsphere" {
  user                 = "${var.macstadium_vcenter_management_username}"
  password             = "${var.macstadium_vcenter_management_password}"
  vsphere_server       = "${var.macstadium_vcenter_management_ip_address}"
  allow_unverified_ssl = true
}

resource "vsphere_virtual_machine" "macstadium_test_instance" {
  count = "${var.create_macstadium_test_instances == "0" ? "0" : var.number_of_test_instances}"

  name       = "macstadium-test-${count.index + 1}"
  vcpu       = 1
  memory     = 2048
  datacenter = "${var.macstadium_vcenter_datacenter_name}"
  cluster    = "${var.macstadium_vcenter_cluster_name}"
  domain     = "macstadium-test-${count.index + 1}"

  network_interface {
    label              = "Private-1"
    ipv4_address       = "${cidrhost(var.macstadium_cidr, count.index + 2)}"
    ipv4_gateway       = "${cidrhost(var.macstadium_cidr, 1)}"
    ipv4_prefix_length = "${replace(var.macstadium_cidr, "/(.*)\\//", "")}"
  }

  disk {
    datastore = "${var.macstadium_vcenter_datastore_name}"
    template  = "${var.macstadium_vcenter_vm_template_name}"
  }
}
