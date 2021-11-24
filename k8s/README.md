### Create Helm

```
helm create password-generator
```

#### Deleted Deployment

Created virtualservice.yaml in templates.


Create statefulset.yaml in templates.   Excluded readiness and health probes for now.

#### Deploy


```
helm3 upgrade --wait --timeout=600s --create-namespace --namespace apps2 --install passgen password-generator
```


#### Delete Helm Chart

```
helm -n apps2 delete passgen
```


#### Deploy (custom env)

```
cat env.yaml
```

```
env:
  fqdn: "djeks1.jennings.solutions"
  app_path: "passgen"
```

```
helm3 upgrade --wait --timeout=600s --create-namespace --namespace apps2 --install --values env.yaml passgen password-generator
```

### Deploy with Params

```
FQDN=djaks2.jennings.solutions
APP_PATH=passgen
```

```
helm3 upgrade --wait --timeout=600s --create-namespace --namespace apps2 --install \
  --set "env.fqdn=${FQDN}" \
  --set "env.app_path=${APP_PATH}" \
  passgen password-generator
```

```
FQDN=djeks1.jennings.solutions
APP_PATH=testapp
SC=django-sc2
```

```
helm3 upgrade --wait --timeout=600s --create-namespace --namespace apps --install \
  --set "env.fqdn=${FQDN}" \
  --set "env.app_path=${APP_PATH}" \
  --set "persistence.storageClass=${SC}" \
  testapp password-generator
```
