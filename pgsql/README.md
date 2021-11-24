#### PostgreSQL Helm


```
https://github.com/helm/charts/tree/master/stable/postgresql
https://github.com/bitnami/charts/
```

```
https://bitnami.com/
```

helm repo add bitnami https://charts.bitnami.com/bitnami

Not sure helm is the best route.

### Kubegres

https://www.postgresql.org/about/news/kubegres-is-available-as-open-source-2197/


#### Install Operator

https://www.kubegres.io/doc/getting-started.html

```
kubectl apply -f https://raw.githubusercontent.com/reactive-tech/kubegres/v1.12/kubegres.yaml
```

```
kubectl create ns db
```

#### Create Secret
Update the yaml to have a secret.

```
kubectl apply -f pgsql/my-postgres-secret.yaml
```

#### Create

```
kubectl apply -f pgsql/my-postgres.yaml
```

#### Installed PgAdmin for Mac.  

https://www.postgresql.org/ftp/pgadmin/pgadmin4/v6.1/macos/


```
kubectl port-forward svc/mypostgres 543
```

From PGAdmin I was able to login to the server using localhost via the kubectl tunnel.  

This was the easiest install of PostgreSQL I've ever done.

```
docker run -it --name pg-client ubuntu:20.04
apt update
apt install
apt install postgresql-client
```

```
psql -h host.docker.internal -U postgres -W
```

Provided password and I was able to connect via localhost.  Magic like.
