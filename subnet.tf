resource "aws_subnet" "public" {
    count = length(var.cidr_block_subnet)
    vpc_id = aws_vpc.qa.id
    cidr_block = element(var.cidr_block_subnet,count.index+1)
    availability_zone = element(var.azs,count.index+1)
    map_public_ip_on_launch = true
    tags = {
        "Name" = "${var.vpc_name}-public${count.index+1}"
    }
  
}
resource "aws_route_table" "qa-rt" {
    vpc_id = aws_vpc.qa.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
    tags = {
        "Name" = "${var.vpc_name}-rt"
    }
  
}

resource "aws_route_table_association" "association" {
    count = length(var.cidr_block_subnet)
    subnet_id = element(aws_subnet.public.*.id,count.index+1)
    route_table_id = aws_route_table.qa-rt.id
  
}

resource "aws_security_group" "qa-sg" {
    vpc_id = aws_vpc.qa.id
    name = "allow all rules"
    description = "crate security groups for qa"
    tags = {
        "Name" = "${var.vpc_name}-sg"
    }  
    ingress  {
        description = "allow all inbound rules"
        to_port= 0
        from_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress  {
        description = "allow all outbound rules"
        to_port= 0
        from_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "qa-server" {
    count = 3
    ami = "ami-0f9ce67dcf718d332"
    instance_type = "t2.micro"
    key_name = "krishika"
    vpc_security_group_ids = [aws_security_group.qa-sg.id]
    subnet_id = element(aws_subnet.public.*.id,count.index+1)
    associate_public_ip_address = true
    user_data = <<-EOF
    #!/bin/bash
    yum update -y
    amazon-linux-extras install nginx1.12 -y
    service nginx start
    echo "<div><h1>PUBLIC-SERVER</h1></div>" >> /usr/share/nginx/html/index.html
    EOF
    tags = {
        "Name" = "${var.vpc_name}-SERVER"
    }
    
  
}
