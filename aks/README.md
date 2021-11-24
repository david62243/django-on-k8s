### Create AKS Cluster

The cluster was created from Azure Portal WebUI.

- Created Resource Group (djaks1)

- Create Kubernetes Service (djaks1)
  - 2 x Standard_DS2_v2
  - AKS 1.21.2
  - Defaults (down the line)



```
az login
```

```
SID="7fb045c9-827d-4edd-a92b-66dcd3420a1e"
RG="djaks2"
CLUSTER="djaks2"
LOCATION="westus3"
```

```
DSV3USED=$(az vm list-usage --subscription ${SID} --location ${LOCATION} -o tsv |  awk -F'\t' '/ DSv3/ {print $1}')
DSV3LIMIT=$(az vm list-usage --subscription ${SID} --location ${LOCATION} -o tsv |  awk -F'\t' '/ DSv3/ {print $2}')
DSV3AVAIL=$((${DSV3LIMIT}-${DSV3USED}))
echo ${DSV3AVAIL}
```

```
az group create --subscription ${SID} --name ${RG} --location ${LOCATION}
```

```
az network vnet create --subscription ${SID} --name ${RG} --resource-group ${RG} --subnet-name AKSNODES --address-prefix 10.0.0.0/8 --subnet-prefix 10.240.0.0/16
```


```
SUBNETID=$(az network vnet subnet show --subscription ${SID} --resource-group ${RG} --vnet-name ${RG} --name AKSNODES --query id -o tsv)
```

Under Subscription -> Usage + quotas

```
cd ~
ssh-keygen -t rsa -b 2048
```

```
COUNT=2
SIZE=Standard_D2s_v3
USER=aks
PUBKEY="/Users/david/aks.pub"
AKS_VERSION=1.21.2
APPID=**REDACTED**
PASSWORD=**REDACTED**
```

```
az aks create \
  --subscription ${SID} \
  --resource-group ${RG} \
  --name ${CLUSTER} \
  --node-count ${COUNT} \
  --node-vm-size ${SIZE} \
  --admin-username ${USER} \
  --ssh-key-value ${PUBKEY} \
  --network-plugin azure \
  --vnet-subnet-id ${SUBNETID} \
  --docker-bridge-address 172.17.0.1/16 \
  --dns-service-ip 10.0.0.10 \
  --service-cidr 10.0.0.0/16 \
  --kubernetes-version ${AKS_VERSION} \
  --service-principal ${APPID} \
  --client-secret ${PASSWORD} \
  --vm-set-type VirtualMachineScaleSets \
  --load-balancer-sku standard \
  --zones 1
```

```
az aks get-credentials --admin --name ${CLUSTER} --resource-group ${RG}
```

```
az aks get-credentials --admin --name ${CLUSTER} --resource-group ${RG} -f ~/djaks2.kubeconfig
```

**NOTE:**  This kubeconfig file is portable.  Anyone who has this file can get to the cluster.  
