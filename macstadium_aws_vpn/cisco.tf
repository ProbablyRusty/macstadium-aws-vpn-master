data "template_file" "cisco_config_file" {
  template = "${file("${path.module}/cisco-config.tmpl")}"

  vars {
    tunnel_1_address        = "${aws_vpn_connection.macstadium_cisco_connection.tunnel1_address}"
    tunnel_2_address        = "${aws_vpn_connection.macstadium_cisco_connection.tunnel2_address}"
    tunnel_1_preshared_key  = "${aws_vpn_connection.macstadium_cisco_connection.tunnel1_preshared_key}"
    tunnel_2_preshared_key  = "${aws_vpn_connection.macstadium_cisco_connection.tunnel2_preshared_key}"
    macstadium_network_addr = "${cidrhost(var.macstadium_cidr, 0)}"
    macstadium_network_mask = "${cidrnetmask(var.macstadium_cidr)}"
    aws_network_addr        = "${cidrhost(var.aws_vpc_cidr, 0)}"
    aws_network_mask        = "${cidrnetmask(var.aws_vpc_cidr)}"
  }
}

resource "null_resource" "cisco_config_file" {
  triggers {
    tunnel_1_address        = "${aws_vpn_connection.macstadium_cisco_connection.tunnel1_address}"
    tunnel_2_address        = "${aws_vpn_connection.macstadium_cisco_connection.tunnel2_address}"
    tunnel_1_preshared_key  = "${aws_vpn_connection.macstadium_cisco_connection.tunnel1_preshared_key}"
    tunnel_2_preshared_key  = "${aws_vpn_connection.macstadium_cisco_connection.tunnel2_preshared_key}"
    macstadium_network_addr = "${cidrhost(var.macstadium_cidr, 0)}"
    macstadium_network_mask = "${cidrnetmask(var.macstadium_cidr)}"
    aws_network_addr        = "${cidrhost(var.aws_vpc_cidr, 0)}"
    aws_network_mask        = "${cidrnetmask(var.aws_vpc_cidr)}"
  }

  provisioner "local-exec" {
    command = "printf '${data.template_file.cisco_config_file.rendered}' > ${path.module}/cisco.config"
  }

  provisioner "local-exec" {
    command = "printf '${data.template_file.cisco_remove_config_file.rendered}' > ${path.module}/cisco.remove.tmp"
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "rm -f ${path.module}/cisco.config"
  }
}

data "template_file" "cisco_remove_config_file" {
  template = "${file("${path.module}/cisco-remove.tmpl")}"

  vars {
    tunnel_1_address = "${aws_vpn_connection.macstadium_cisco_connection.tunnel1_address}"
    tunnel_2_address = "${aws_vpn_connection.macstadium_cisco_connection.tunnel2_address}"
  }
}

resource "null_resource" "cisco_remove_config_file" {
  provisioner "local-exec" {
    command = "printf '${data.template_file.cisco_remove_config_file.rendered}' > ${path.module}/cisco.remove"
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "rm -f ${path.module}/cisco.remove"
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "rm -f ${path.module}/cisco.remove.tmp"
  }
}

resource "null_resource" "cisco_vpn_configuration" {
  depends_on = [
    "aws_vpn_connection.macstadium_cisco_connection",
    "null_resource.cisco_config_file",
    "null_resource.cisco_remove_config_file",
  ]

  triggers {
    tunnel_1_address        = "${aws_vpn_connection.macstadium_cisco_connection.tunnel1_address}"
    tunnel_2_address        = "${aws_vpn_connection.macstadium_cisco_connection.tunnel2_address}"
    tunnel_1_preshared_key  = "${aws_vpn_connection.macstadium_cisco_connection.tunnel1_preshared_key}"
    tunnel_2_preshared_key  = "${aws_vpn_connection.macstadium_cisco_connection.tunnel2_preshared_key}"
    macstadium_network_addr = "${cidrhost(var.macstadium_cidr, 0)}"
    macstadium_network_mask = "${cidrnetmask(var.macstadium_cidr)}"
    aws_network_addr        = "${cidrhost(var.aws_vpc_cidr, 0)}"
    aws_network_mask        = "${cidrnetmask(var.aws_vpc_cidr)}"
  }

  provisioner "local-exec" {
    command = "cd ${path.module}; /usr/bin/expect ${path.module}/cisco-config.exp ${var.cisco_firewall_username} ${var.cisco_firewall_password} ${var.cisco_inside_1_ip_address}"
  }

  provisioner "local-exec" {
    command = "cp ${path.module}/cisco.remove.tmp ${path.module}/cisco.remove"
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "cd ${path.module}; /usr/bin/expect ${path.module}/cisco-remove.exp ${var.cisco_firewall_username} ${var.cisco_firewall_password} ${var.cisco_inside_1_ip_address}"
  }
}
