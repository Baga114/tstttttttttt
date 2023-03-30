/* Deploy EKS with 2 node groups in VPC A */
resource "aws_iam_role" "eks_cluster" {
  # The name of the role
  name = "eks"

  # The policy that grants an entity permission to assume the role.
  # Used to access AWS resources that you might not normally have access to.
  # The role that Amazon EKS will use to create AWS resources for Kubernetes clusters
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}
# Resource: aws_iam_role_policy_attachment
resource "aws_iam_role_policy_attachment" "amazon_eks_cluster_policy" {
  # The ARN of the policy you want to apply
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"

  # The role the policy should be applied to
  role = aws_iam_role.eks_cluster.name
}

resource "aws_security_group" "sg-cluster" {
  name        = "terraform-eks-sg-cluster"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.vpc_a.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-eks-sg"
  }
}
resource "aws_security_group_rule" "sg-cluster-ingress-workstation-https" {
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 8080
  protocol          = "tcp"
  security_group_id = aws_security_group.sg-cluster.id
  to_port           = 8080
  type              = "ingress"
}
# Resource: aws_eks_cluster
resource "aws_eks_cluster" "eks" {
  # Name of the cluster.
  name = "ek8s"

  # The Amazon Resource Name (ARN) of the IAM role that provides permissions for 
  # the Kubernetes control plane to make calls to AWS API operations on your behalf
  role_arn = aws_iam_role.eks_cluster.arn

  # Desired Kubernetes master version
  version = "1.25"

  vpc_config {
    security_group_ids = [aws_security_group.sg-cluster.id]
    # Indicates whether or not the Amazon EKS private API server endpoint is enabled
    /* endpoint_private_access = true */

    # Indicates whether or not the Amazon EKS public API server endpoint is enabled
    /* endpoint_public_access = true */

    # Must be in at least two different availability zones
    subnet_ids = [
      aws_subnet.public_subnet_a.id,
      aws_subnet.private_subnet_a_1.id,
      aws_subnet.private_subnet_a_2.id,


    ]
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_cluster_policy
  ]
}