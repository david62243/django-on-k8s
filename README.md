

### Dockerize

#### MacBook M1

Possible Problem with Docker Desktop

On MacBook Air (M1) processor I was able to create the Docker files and push them; however, Kubernetes through an error.

Error something like: standard_init_linux.go:219: exec user process caused: exec format error

When I build the same Docker Image on MacBook (Intel Processor) or from Windows 10.  The image works fine.

#### Config

In your Home Directory created django folder

```
mkdir django
```

Modified settings.py

Change BASE_PATH

```
import os
BASE_DIR = os.path.join(os.environ['HOME'],"django")
```

```
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': os.path.join(BASE_DIR,'db.sqlite3'),
    }
}
```

#### Create Django Storage Class

This only needs to be done once on cluster.

```
kubectl apply -f k8s/django_sc.yaml
```

#### Using Template

```
set SUBSTR="s/REPLACE_WITH_NS/apps/;s/REPLACE_WITH_APP_PATH/password-generator/;s/REPLACE_WITH_FQDN/a4iot-dj1019b-c1.westus2.cloudapp.azure.com/"
SUBSTR="s/REPLACE_WITH_NS/apps/;s/REPLACE_WITH_APP_PATH/password-generator/;s/REPLACE_WITH_FQDN/20.106.67.102/"
```

```
sed %SUBSTR% k8s\password-generator-template.yaml > %USERPROFILE%/temp.yaml
sed ${SUBSTR} k8s/password-generator-template.yaml > ~/temp.yaml
```

```
kubectl.exe apply -f  %USERPROFILE%/temp.yaml
kubectl apply -f  ~/temp.yaml
```

**NOTE:** Might be better suited to creating helm chart.  Or scripting the install instead of templating.



#### Create Tar Zip

```
tar cvzf password_generator_application.tgz --exclude *pycache* password_generator_application
```

### Run Server

```
python3 manage.py runserver 8080
```

### Create DockerFiles

#### Create django Docker Image

```
cat docker\Dockerfile.django
FROM alpine:3.14.0

# docker build -t david62243/django:v1.0 . -f docker/Dockerfile.django
# docker push david62243/django:v1.0

RUN apk update && \
    apk add curl python3 py3-pip

RUN pip3 install django

WORKDIR /root
```

#### Create password-generator Image

```
cat docker\Dockerfile
FROM david62243/django:v1.0

# docker build -t david62243/password-generator:v1.0 -f docker/Dockerfile .
# docker push david62243/password-generator:v1.0

RUN adduser -Du 1000 duser

RUN mkdir /home/duser/django

ADD password_generator_application.tgz /home/duser

RUN chown -R 1000:1000 /home/duser

RUN ln -s /usr/bin/python3 /usr/local/bin/python

USER duser
WORKDIR /home/duser
```

#### Run Locally

```
docker run -p 8080:8080  -it --rm david62243/password-generator:v1.0
```

```
python3 password_generator_application/manage.py runserver 0.0.0.0:8080
```

The app is configured to create sqllite database in /home/duser/django folder

Optional: Run this command once after cluster start.  This updates the Database (sqllite) in this case.  

```
python3 password_generator_application/manage.py migrate
```

Both Commands Same Time

```
python3 password_generator/manage.py migrate;python3 password_generator/manage.py runserver 0.0.0.0:8080
```


### Note ssh-agent Windows working with git

Using cmder (https://cmder.net/)

Copy GitLab private key to .ssh/id_rsa

Tried to load the key as name (e.g. gitlabkey from .ssh) didn't work.


lambda> ssh-agent -s
lambda> ssh-add.exe C:\Users\david\.ssh\id_rsa

```
git clone git@gitlab.com:david62243/password-generator.git
```
