provider "aws" {
  region     = "${var.aws_region}"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
}

data "aws_ami" "amazon_linux_ami" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_vpc" "aws_vpc" {
  count = "${var.create_vpc}"

  cidr_block = "${var.aws_vpc_cidr}"
}

resource "aws_internet_gateway" "aws_igw" {
  count = "${var.create_vpc}"

  vpc_id = "${aws_vpc.aws_vpc.id}"
}

resource "aws_subnet" "aws_subnet" {
  count = "${var.create_vpc}"

  vpc_id            = "${aws_vpc.aws_vpc.id}"
  cidr_block        = "${cidrsubnet(var.aws_vpc_cidr, 8, 0)}"
  availability_zone = "${join("", list(var.aws_region, "a"))}"
}

resource "aws_route_table" "aws_vpc_route_table" {
  count = "${var.create_vpc}"

  vpc_id = "${aws_vpc.aws_vpc.id}"
}

resource "aws_route" "default_route" {
  count = "${var.create_vpc}"

  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = "${aws_route_table.aws_vpc_route_table.id}"
  gateway_id             = "${aws_internet_gateway.aws_igw.id}"
}

resource "aws_route_table_association" "aws_vpc_route_table_association" {
  count = "${var.create_vpc}"

  subnet_id      = "${aws_subnet.aws_subnet.id}"
  route_table_id = "${aws_route_table.aws_vpc_route_table.id}"
}

resource "aws_security_group" "aws_test_sg" {
  count = "${var.create_vpc}"

  name        = "aws_test_sg"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.aws_vpc.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.aws_vpc_cidr}", "${var.macstadium_cidr}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "macstadium_aws_key" {
  count = "${var.create_vpc}"

  depends_on = ["null_resource.macstadium_aws_key"]
  key_name   = "macstadium_aws_key"
  public_key = "${file("${path.module}/macstadium_aws_key.pub")}"
}

resource "null_resource" "macstadium_aws_key" {
  count = "${var.create_vpc}"

  provisioner "local-exec" {
    command = "rm -f ${replace(path.module, "/[ ]/", "\\ ")}/macstadium_aws_key*"
  }

  provisioner "local-exec" {
    command = "rm -f ${replace(path.root, "/[ ]/", "\\ ")}/macstadium_aws_key*"
  }

  provisioner "local-exec" {
    command = "ssh-keygen -t rsa  -N '' -C 'macstadium_aws_key' -f ${replace(path.module, "/[ ]/", "\\ ")}/macstadium_aws_key"
  }

  provisioner "local-exec" {
    command = "mv ${replace(path.module, "/[ ]/", "\\ ")}/macstadium_aws_key ${replace(path.root, "/[ ]/", "\\ ")}/macstadium_aws_key"
  }

  provisioner "local-exec" {
    command = "chmod 600 ${replace(path.root, "/[ ]/", "\\ ")}/macstadium_aws_key"
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "rm -f ${replace(path.root, "/[ ]/", "\\ ")}/macstadium_aws_key"
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "echo PLACEHOLDER > ${replace(path.module, "/[ ]/", "\\ ")}/macstadium_aws_key.pub"
  }
}

resource "aws_instance" "aws_test_instance" {
  count = "${var.create_vpc == "0" ? "0" : var.number_of_test_instances}"

  ami                         = "${data.aws_ami.amazon_linux_ami.id}"
  instance_type               = "t2.nano"
  private_ip                  = "${cidrhost(aws_subnet.aws_subnet.cidr_block, count.index + 12)}"
  subnet_id                   = "${aws_subnet.aws_subnet.id}"
  vpc_security_group_ids      = ["${aws_security_group.aws_test_sg.id}"]
  associate_public_ip_address = true
  key_name                    = "${aws_key_pair.macstadium_aws_key.key_name}"

  tags {
    Name = "aws-test-${count.index + 1}"
  }
}

output "aws_vpc_id" {
  value = ["${aws_vpc.aws_vpc.*.id}"]
}

output "aws_vpc_route_table_id" {
  value = ["${aws_route_table.aws_vpc_route_table.*.id}"]
}
