# Create a security group for the EC2 instance
resource "aws_security_group" "instance_security_group" {
  name_prefix = "instance-sg"
  vpc_id      = aws_vpc.vpc_b.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# Launch an EC2 instance in the private subnet

resource "aws_instance" "my_instance2" {
  ami                    = "ami-0557a15b87f6559cf" # Change to your desired AMI
  instance_type          = "t2.micro"              # Change to your desired instance type
  vpc_security_group_ids = [aws_security_group.instance_security_group.id]
  subnet_id              = aws_subnet.private_subnet_b_1.id
  key_name               = "jan2023"


  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install -y nginx
    sudo systemctl start nginx
    mkdir -p /etc/nginx/ssl
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/nginx.key -out /etc/nginx/ssl/nginx.crt -subj "/CN=example.com"
    echo "<html><body><h1>Hello, world!</h1></body></html>" > /usr/share/nginx/html/test2.htm
    cat <<-EOF_NGINX > /etc/nginx/conf.d/default.conf
        server {
          listen 443 ssl;
          server_name example.com;

          ssl_certificate /etc/nginx/ssl/nginx.crt;
          ssl_certificate_key /etc/nginx/ssl/nginx.key;

          location /test2 {
            root /usr/share/nginx/html;
            index test2.htm;
          }
        }
      EOF_NGINX
      systemctl enable nginx
      systemctl start nginx
      EOF

  tags = {
    Name = "vpc-b-instance"
  }
}