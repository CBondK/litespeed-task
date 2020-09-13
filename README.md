# Task for the Cloud team


## Components
  - Litespeed webserver
  - MySQL database
  - WordPress

### Litespeed webserver

The webserver details for monitoring can be retrieved via the exposed 7080 port. For example, the following cURL requests may be used:
```
curl -iu $ADMIN_USER:ADMIN_PASS http://localhost:7080/status?rpt=summary -kL

curl -iu $ADMIN_USER:ADMIN_PASS http://localhost:7080/status?rpt=detail-kL
```

By default, the link is accessible only from localhost. For advanced use cases, it is possible to define the subnet of allowed remote addresses for such requests. In this case, the subnet should be defined via a .env file, for example:
```
ALLOWED_SUB='0.0.0.0/0'
```

### MySQL database
In order to get the webserver working properly, it is required to deploy the database server. In our case, there is the mariadb:10.5.5 Docker image used. Using docker-compose.yml will also create a volume for the database which allows saving the Wordpress database data after container recreation.

### Wordpress

The built image also contains installed Wordpress as well as the required LiteSpeed Cache plugin. However, it will be required to create a WP user once the containers are up and runnings.

## Deployment

There are two scenarios of the deployment:

1. Standalone Docker image built via a separate Dockerfile.
2. Using docker-compose in order to put the stack together automatically.

__Please note that for successful deployment, it will be required to create the ".env" file with the obligatory variables.__

The list of the obligatory/optional variables along with examples of values given below:
```
MYSQL_DATABASE=wordpress       # obligatory
MYSQL_ROOT_PASSWORD=password   # obligatory
MYSQL_USER=wordpress           # obligatory
MYSQL_PASSWORD=password        # obligatory
PHP_VER=lsphp73                # obligatory
DOMAIN=localhost
ADMIN_USER=const
ADMIN_PASS=qwerty1234
LSWS_VER=5.0
LSWS_SUBVER=5.4.9
```

This will allow extending the available options for deployment and will give us more dynamic provisioning.

In case the optional values are not explicitly set, the default ones will be generated. The default Admin useername and password will be printed during image provisioning.

____Please note that it is obligatory to place the trial.key to the directory where Dockerfile is located.____

#### 1. Standalone Litespeed image build.

```
----> git clone https://github.com/CBondK/litespeed-task.git && cd litespeed-task
# place .env & trial.key to litespeed-task dir
----> source .env
# Please note that there should be a MySQL server up and running with the correct connection details specified in .env
----> docker build . -t lsws-box:1.5 --build-arg PHP_VER=$PHP_VER
# Specified PHP version will be fetched from .env in this directory
----> docker run -d -p 443:443 -p 80:80 -p 7080:7080  lsws-box:1.5
```

#### 2. Complete stack via docker-compose.

```
----> git clone https://github.com/CBondK/litespeed-task.git && cd litespeed-task
# it is also needed to place .env & trial.key to litespeed-task dir so that the build args are picked up automatically by docker-compose
----> docker-compose up -d
```


*The deployment process has been tested on the Google Cloud platform and local host machine.*

Reference: https://www.litespeedtech.com/docs/webserver
