### Create EKS Cluster

https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html

Install awscli and ekscli.  On Mac this can be done with brew.

#### Create eksctl Config File

The config below assumes you created a key pair and saved the public key (eks.pub) in your home directory.

Create Public Key from Private Key.

```
ssh-keygen -y -f eks > eks.pub
```

```
cat djeks1.yaml
```

```
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: djeks1
  region: us-east-2
  version: "1.21"

nodeGroups:
  - name: ng-1
    ssh:
      allow: true
      publicKeyPath: ~/eks.pub
    instanceType: t2.large
    desiredCapacity: 2
```


```
eksctl create cluster -f djeks1.yaml
```

You'll see a bunch of output as the cluster is created in AWS.  

From AWS Console you can see the new cluster.  

Two nodes in EC2 (t2.large )


### Access Cluster


```
kubectl config current-context
david@djeks1.us-east-2.eksctl.io
```

```
aws eks list-clusters
{
    "clusters": [
        "djeks1"
    ]
}
```

You could pull down the kubectl file to a file.

```
aws eks --region us-east-2 update-kubeconfig --name djeks1  --kubeconfig ~/djeks1.kubeconfig  
```

Security Test: Copied this file to another computer in my house.  

```
kubectl --kubeconfig djeks1.kubeconfig get nodes
```

Returned Unauthorized.   The kubeconfig works only from the computer it was created on.  

On original computer.

```
kubectl --kubeconfig ~/djeks1.kubeconfig get nodes -o wide
NAME                                           STATUS   ROLES    AGE   VERSION               INTERNAL-IP      EXTERNAL-IP     OS-IMAGE         KERNEL-VERSION                CONTAINER-RUNTIME
ip-192-168-30-160.us-east-2.compute.internal   Ready    <none>   17m   v1.21.4-eks-033ce7e   192.168.30.160   3.144.229.19    Amazon Linux 2   5.4.149-73.259.amzn2.x86_64   docker://20.10.7
ip-192-168-53-7.us-east-2.compute.internal     Ready    <none>   17m   v1.21.4-eks-033ce7e   192.168.53.7     18.217.56.141   Amazon Linux 2   5.4.149-73.259.amzn2.x86_64   docker://20.10.7
```

Normally you will not need to ever ssh into a node; however, we added an ssh key so you can login to troubleshoot (explore) if you have the private key.


```
ssh -i ~/eks ec2-user@3.144.229.19
The authenticity of host '3.144.229.19 (3.144.229.19)' can't be established.
ECDSA key fingerprint is SHA256:t2wQjQc6Ym5yy8RYex6276/AkG1cT5b+5aa8oHrFQHg.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '3.144.229.19' (ECDSA) to the list of known hosts.
Last login: Wed Oct 13 23:54:48 2021 from 205.251.233.52

       __|  __|_  )
       _|  (     /   Amazon Linux 2 AMI
      ___|\___|___|

https://aws.amazon.com/amazon-linux-2/
[ec2-user@ip-192-168-30-160 ~]$

cat /proc/cpuinfo (you can see two cores)
free -h (8G of memory)

```

### Install istio

```
kubectl get svc -A
NAMESPACE     NAME         TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)         AGE
default       kubernetes   ClusterIP   10.100.0.1    <none>        443/TCP         30m
kube-system   kube-dns     ClusterIP   10.100.0.10   <none>        53/UDP,53/TCP   30m
```

```
istioctl install --set profile=demo -y
```

You can see the new istio services (svc).   EKS uses an ELB for your gateway.  

```
kubectl get svc -A
NAMESPACE      NAME                   TYPE           CLUSTER-IP       EXTERNAL-IP                                                               PORT(S)                                                                      AGE
default        kubernetes             ClusterIP      10.100.0.1       <none>                                                                    443/TCP                                                                      31m
istio-system   istio-egressgateway    ClusterIP      10.100.181.67    <none>                                                                    80/TCP,443/TCP                                                               35s
istio-system   istio-ingressgateway   LoadBalancer   10.100.140.140   a5ef63781af794862914c953244ddbf7-1535565310.us-east-2.elb.amazonaws.com   15021:30757/TCP,80:31340/TCP,443:30561/TCP,31400:30391/TCP,15443:31594/TCP   35s
istio-system   istiod                 ClusterIP      10.100.119.150   <none>                                                                    15010/TCP,15012/TCP,443/TCP,15014/TCP                                        44s
kube-system    kube-dns               ClusterIP      10.100.0.10      <none>                                                                    53/UDP,53/TCP                                                                31m
```


```
kubectl label namespace default istio-injection=enabled
```

```
cd ~/istio-1.11.4
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
```


```
export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
echo ${INGRESS_HOST}
echo ${INGRESS_PORT}
echo ${SECURE_INGRESS_PORT}
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
echo "http://$GATEWAY_URL/productpage"
http://aeb97a0003fb246b19843699bcb34e3b-123607724.us-east-2.elb.amazonaws.com:80/productpage

```

**NOTE:** First install attempt failed.  Uninstalled and tried again and it worked.  Followed: https://istio.io/latest/docs/setup/getting-started/#uninstall to uninstall.


##### DNS Entry

Added a A record on AWS Route 53 for djeks1.jennings.solutions.  

Updated helm with new env.yaml

##### Create k8s Secret

```
kubectl -n istio-system create secret tls tls-secret \
    --cert=/Users/david/lets-encrypt/config/live/jennings.solutions/cert.pem \
    --key=/Users/david/lets-encrypt/config/live/jennings.solutions/privkey.pem
```


##### Modify Gateway

Added the following Stanza.

```
- hosts:
  - djaks1.jennings.solutions
  port:
    name: https
    number: 443
    protocol: HTTPS
  tls:
    credentialName: tls-secret
    maxProtocolVersion: TLSV1_3
    minProtocolVersion: TLSV1_2
    mode: SIMPLE
```


#### Create EFS Policy

This only needs to be done once in AWS.

```
curl -S https://raw.githubusercontent.com/kubernetes-sigs/aws-efs-csi-driver/v1.2.0/docs/iam-policy-example.json -o iam-policy.json
```

```
aws iam create-policy \
  --policy-name EFSCSIControllerIAMPolicy \
  --policy-document file://iam-policy.json
```


```
{
    "Policy": {
        "PolicyName": "EFSCSIControllerIAMPolicy",
        "PolicyId": "ANPA4OVZU3DJIZQEC6QNY",
        "Arn": "arn:aws:iam::856161573074:policy/EFSCSIControllerIAMPolicy",
        "Path": "/",
        "DefaultVersionId": "v1",
        "AttachmentCount": 0,
        "PermissionsBoundaryUsageCount": 0,
        "IsAttachable": true,
        "CreateDate": "2021-10-31T11:47:02+00:00",
        "UpdateDate": "2021-10-31T11:47:02+00:00"
    }
}
```


### Associate EFS Policy with Cluster

The following command was needed before I could create iamserviceaccount

```
eksctl utils associate-iam-oidc-provider --region=us-east-2 --cluster=djeks1 --approve
```

**NOTE:** Policy ARN from Above

```
eksctl create iamserviceaccount \
  --cluster=djeks1 \
  --region us-east-2 \
  --namespace=kube-system \
  --name=efs-csi-controller-sa \
  --override-existing-serviceaccounts \
  --attach-policy-arn=arn:aws:iam::856161573074:policy/EFSCSIControllerIAMPolicy \
  --approve
```


### Install CSI Driver for EFS

```
kubectl kustomize "github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.3" > driver13.yaml
```

#### Delete the service account created in step 1.

```
vi driver13.yaml
```

```
efs-csi-controller-sa
```

#### Apply the Driver

```
kubectl apply -f driver13.yaml
```


### Create EFS from AWS Web UI


Name: djeks1
VPC: One for djeks1
Regional

Click Customize

Network Access: Add Security Groups for Cluster and nodegroup (Same ones that are attached to EC2 instances for the EKS)

```
fs-06046c0d0aebcfd80
```

### Create Storage Class

```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: django-sc
parameters:
  directoryPerms: "700"
  fileSystemId: fs-06046c0d0aebcfd80
  provisioningMode: efs-ap
provisioner: efs.csi.aws.com
```

```
kubectl apply -f django_sc_eks.yaml
```

### Metric Server

```
https://docs.aws.amazon.com/eks/latest/userguide/metrics-server.html
```


```
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

```
kubectl top nodes
```


### Delete Cluster  

EKS Delete fails if istio is running; fails because it would violate disruption budget.


```
kubectl -n istio-system scale deployment istio-egressgateway --replicas=0
kubectl -n istio-system scale deployment istio-ingressgateway --replicas=0
kubectl -n istio-system scale deployment istiod --replicas=0
```


```
eksctl delete cluster --name djeks1
```

Still Failed.

```
2021-11-09 09:50:47 [ℹ]  waiting for CloudFormation stack "eksctl-djeks1-nodegroup-ng-1"
2021-11-09 09:50:48 [✖]  unexpected status "DELETE_FAILED" while waiting for CloudFormation stack "eksctl-djeks1-nodegroup-ng-1"
2021-11-09 09:50:48 [ℹ]  fetching stack events in attempt to troubleshoot the root cause of the failure
2021-11-09 09:50:48 [✖]  AWS::CloudFormation::Stack/eksctl-djeks1-nodegroup-ng-1: DELETE_FAILED – "The following resource(s) failed to delete: [SG]. "
2021-11-09 09:50:48 [✖]  AWS::EC2::SecurityGroup/SG: DELETE_FAILED – "resource sg-0e8976ea0b10da1dd has a dependent object (Service: AmazonEC2; Status Code: 400; Error Code: DependencyViolation; Request ID: bfcf639e-5916-41a0-b11c-0bba493f97f2; Proxy: null)"
2021-11-09 09:50:48 [ℹ]  1 error(s) occurred while deleting cluster with nodegroup(s)
2021-11-09 09:50:48 [✖]  waiting for CloudFormation stack "eksctl-djeks1-nodegroup-ng-1": ResourceNotReady: failed waiting for successful resource state
```

Deleted EKS from AWS Console.


### djeks2

EKS requires two subnets in two zones.  

```
2021-11-09 11:56:40 [✖]  unexpected status "ROLLBACK_IN_PROGRESS" while waiting for CloudFormation stack "eksctl-djeks2-cluster"
2021-11-09 11:56:40 [ℹ]  fetching stack events in attempt to troubleshoot the root cause of the failure
2021-11-09 11:56:40 [!]  AWS::IAM::Role/ServiceRole: DELETE_IN_PROGRESS
2021-11-09 11:56:40 [!]  AWS::EC2::SecurityGroup/ControlPlaneSecurityGroup: DELETE_IN_PROGRESS
2021-11-09 11:56:40 [!]  AWS::IAM::Policy/PolicyELBPermissions: DELETE_IN_PROGRESS
2021-11-09 11:56:40 [!]  AWS::EC2::SecurityGroupIngress/IngressInterNodeGroupSG: DELETE_IN_PROGRESS
2021-11-09 11:56:40 [!]  AWS::IAM::Policy/PolicyCloudWatchMetrics: DELETE_IN_PROGRESS
2021-11-09 11:56:40 [✖]  AWS::IAM::Policy/PolicyELBPermissions: CREATE_FAILED – "Resource creation cancelled"
2021-11-09 11:56:40 [✖]  AWS::IAM::Policy/PolicyCloudWatchMetrics: CREATE_FAILED – "Resource creation cancelled"
2021-11-09 11:56:40 [✖]  AWS::EKS::Cluster/ControlPlane: CREATE_FAILED – "Resource handler returned message: \"Subnets specified must be in at least two different AZs (Service: Eks, Status Code: 400, Request ID: 5c97a8dd-9d0c-4a3b-b83d-7885ce29179f, Extended Request ID: null)\" (RequestToken: 1df99d21-28ec-6090-7ab3-c0907e2b94f5, HandlerErrorCode: InvalidRequest)"
2021-11-09 11:56:40 [!]  1 error(s) occurred and cluster hasn't been created properly, you may wish to check CloudFormation console
2021-11-09 11:56:40 [ℹ]  to cleanup resources, run 'eksctl delete cluster --region=us-east-2 --name=djeks2'
2021-11-09 11:56:40 [✖]  ResourceNotReady: failed waiting for successful resource state
Error: failed to create cluster "djeks2"
```

aws configure --profile myaws
export AWS_PROFILE=myaws
