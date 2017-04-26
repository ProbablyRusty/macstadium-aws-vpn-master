provider "aws" {
  region     = "${var.aws_region}"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
}

resource "aws_customer_gateway" "macstadium_cisco" {
  bgp_asn    = 65000
  ip_address = "${var.cisco_wan_ip_address}"
  type       = "ipsec.1"

  tags {
    Name = "macstadium_cisco"
  }
}

resource "aws_vpn_gateway" "aws_vpn_gw" {
  vpc_id = "${var.aws_vpc_id}"

  tags {
    Name = "aws_vpn_gw"
  }
}

resource "aws_vpn_connection" "macstadium_cisco_connection" {
  vpn_gateway_id      = "${aws_vpn_gateway.aws_vpn_gw.id}"
  customer_gateway_id = "${aws_customer_gateway.macstadium_cisco.id}"
  type                = "ipsec.1"
  static_routes_only  = true
}

resource "aws_vpn_connection_route" "macstadium_vpn_route" {
  destination_cidr_block = "${var.macstadium_cidr}"
  vpn_connection_id      = "${aws_vpn_connection.macstadium_cisco_connection.id}"
}

resource "aws_route" "macstadium_vpn_route_table_route" {
  count                  = "${var.count_of_route_tables}"
  destination_cidr_block = "${var.macstadium_cidr}"
  route_table_id         = "${element(split(",", var.aws_vpc_route_table_ids), count.index)}"
  gateway_id             = "${aws_vpn_gateway.aws_vpn_gw.id}"
}
