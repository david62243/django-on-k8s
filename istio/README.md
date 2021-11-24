### Install Istio

Istio Web Site.  https://istio.io/latest/docs/setup/

#### Download

```
curl -LO https://github.com/istio/istio/releases/download/1.11.4/istio-1.11.4-osx.tar.gz
```

```
sudo cp istio-1.11.4/bin/istioctl /usr/local/bin/
```

```
istioctl version
no running Istio pods in "istio-system"
1.11.4
```

#### Demo Istio

```
istioctl install --set profile=demo -y
kubectl label namespace default istio-injection=enabled
```

```
cd istio-1.11.4
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
```

```
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
```


#### Enable SSL


##### Reference

https://marcincuber.medium.com/lets-encrypt-generating-wildcard-ssl-certificate-using-certbot-ae1c9484c101

##### Installs

Already had awscli installed.

```
brew install certbot
```


```
certbot certonly --manual \
  --config-dir lets-encrypt/config \
  --work-dir lets-encrypt/work \
  --logs-dir lets-encrypt/logs \
  --preferred-challenges=dns \
  --email david62243@yahoo.com \
  --server https://acme-v02.api.letsencrypt.org/directory \
  --agree-tos \
  --manual-public-ip-logging-ok \
  -d "*.jennings.solutions"
```

```
Saving debug log to /Users/david/lets-encrypt/logs/letsencrypt.log

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Would you be willing, once your first certificate is successfully issued, to
share your email address with the Electronic Frontier Foundation, a founding
partner of the Let's Encrypt project and the non-profit organization that
develops Certbot? We'd like to send you email about our work encrypting the web,
EFF news, campaigns, and ways to support digital freedom.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
(Y)es/(N)o: N
Account registered.
Requesting a certificate for *.jennings.solutions

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Please deploy a DNS TXT record under the name:

_acme-challenge.jennings.solutions.

with the following value:

QUFit-DnlypN653p3bMYXMrX9uvYXZFYFN85aiL_pc4

Before continuing, verify the TXT record has been deployed. Depending on the DNS
provider, this may take some time, from a few seconds to multiple minutes. You can
check if it has finished deploying with aid of online tools, such as the Google
Admin Toolbox: https://toolbox.googleapps.com/apps/dig/#TXT/_acme-challenge.jennings.solutions.
Look for one or more bolded line(s) below the line ';ANSWER'. It should show the
value(s) you've just added.

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Press Enter to Continue
```

##### From Route 53 Added TXT Record

Then

Press Enter

```
Successfully received certificate.
Certificate is saved at: /Users/david/lets-encrypt/config/live/jennings.solutions/fullchain.pem
Key is saved at:         /Users/david/lets-encrypt/config/live/jennings.solutions/privkey.pem
This certificate expires on 2022-01-26.
These files will be updated when the certificate renews.

NEXT STEPS:
- This certificate will not be renewed automatically. Autorenewal of --manual certificates requires the use of an authentication hook script (--manual-auth-hook) but one was not provided. To renew this certificate, repeat this same certbot command before the certificate's expiry date.

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
If you like Certbot, please consider supporting our work by:
 * Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
 * Donating to EFF:                    https://eff.org/donate-le
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
```

##### Create A Record  

Using the IP from Kubernetes.


```
kubectl -n istio-system get svc
NAME                   TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)                                                                      AGE
istio-egressgateway    ClusterIP      10.0.166.137   <none>          80/TCP,443/TCP                                                               6h26m
istio-ingressgateway   LoadBalancer   10.0.55.228    20.106.67.102   15021:32321/TCP,80:32232/TCP,443:31860/TCP,31400:30697/TCP,15443:31380/TCP   6h26m
istiod                 ClusterIP      10.0.174.24    <none>          15010/TCP,15012/TCP,443/TCP,15014/TCP                                        6h26m
```

Create A Record

```
djaks1.jennings.solutions   A   20.106.67.102
```

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
