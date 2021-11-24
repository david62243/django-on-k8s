

- Create vpc
- Add Subnet(s)
- Create Default Subnets


I deleted the default gateways for 172.31.0.0

aws ec2 create-default-subnet --availability-zone us-east-2a
aws ec2 create-default-subnet --availability-zone us-east-2b
aws ec2 create-default-subnet --availability-zone us-east-2c

Allow Access from EKS to EC2 instances

Web Server Running on 10.202.10.223

EKS running in it's private space (192.168.x.x)
- Created Peering Connection Between Two VPC's
- Added Routes to eksctl-djeks2-cluster/PublicRouteTable
  10.202.0.0/16  route to Peering Connection
- On rtb for 10.202
  192.168.0.0/16 route to Peering Connection
- Updated SG to allow port 80 from Everywhere

Voila: I can now curl to web server.  

kubectl exec -it ubuntu-deployment-58f446dd98-qcpxt  -- bash

curl 10.202.10.223

The part I was missing was the Routing Table

Routing Table was also needed to connect all traffic out to Internet Gateway (This was needed for ssh to work)
