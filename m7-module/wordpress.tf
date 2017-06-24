provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "./vpc"
}

data "template_file" "wordpress-init" {
  template = "${file("wordpress-init.sh.tpl")}"

  vars {
    db_password = "${var.db_password}"
  }
}

resource "aws_instance" "webserver" {
  ami           = "${var.ami}"
  instance_type = "t2.micro"
  user_data     =  "${data.template_file.wordpress-init.rendered}" # "${file("wordpress-init.sh")}"
  vpc_security_group_ids = ["${aws_security_group.webserver.id}"]
  key_name      = "awittig"
  subnet_id     = "${module.vpc.subnet_id}"
}

resource "aws_security_group" "webserver" {
  name        = "wordpress"
  description = "Allowing HTTP and SSH access."
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol  = "tcp"
    from_port = 80
    to_port   = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_eip" "ip" {
  instance = "${aws_instance.webserver.id}"
}

output "ip" {
  value = "${aws_eip.ip.public_ip}"
}
