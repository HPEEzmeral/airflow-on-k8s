# Airflow on ECP

## Automatic Airflow Cluster creation

Starting from ECP version `5.4.0`, users can create Airflow Cluster automatically without executing any scripts.

Users can create an Airflow Cluster instance per tenant from git repository using ECP UI. Here is a short instruction:
1. Create a new tenant with enabled `ML Ops Project` checkbox. Also you can use existing one.
2. Open created tenant and then open tab `Source Control` on the left panel.
3. After that click button `create` in order to create new source control.
4. In the form you need to fill such required fields:
    * `Configuration Name` should be equal to string `airflow-cluster-dags-repo`. Only such source control, which has got name `airflow-cluster-dags-repo`, will create new Airflow Cluster instance in this tenant.
    * `Repository URL` - public or private git repository, where DAGs are stored.
    * `Branch` - name of the branch in git repository, which you want to use.
    * `Working Directory` - path to directory, where DAGs are placed in git repository.
5. If git is accessible behind the proxy, you also need to fill such fields:
    * `Proxy Protocol` - protocol of the proxy (http or https).
    * `Proxy Host` - hostname (FQDN) of the proxy server.
    * `Proxy Port` - port of the proxy server.
6. If git repository is private, ypu also need to fill such fields:
    * `Username` - username of user, which has got access to this repository.
    * `Email` - email of this user.
    * `Token`/`Password` - token or password of this user.
7. After filling all fields click submit and wait about 5 - 10 minutes.
8. Reload the page and open tab `Workflow Engine` on the left panel in order to open Airflow UI.

> __Note__: Platform version `5.4.0` doesn't allow create source control with such proxy server, which require authentication. In this situation you need to install Airflow Cluster with bootstrap scripts.

## List of images used by Airflow

If you have got an airgap environment, push such images into your docker registry:

- `gcr.io/mapr-252711/airflow:ecp-5.4.0-rc2`
- `gcr.io/mapr-252711/airflow-operator:ecp-5.4.0-rc2`
- `k8s.gcr.io/git-sync/git-sync:v3.3.4`
- `k8s.gcr.io/volume-nfs:0.8`
- `pbweb/airflow-prometheus-exporter:latest`
- `postgres:9.5`
- `bluedata/hpecp-dtap:1.7.0`

## Manual installation

There are some scripts, which you can use to install any Airflow component manually. In all subdirectories you can find `README.md` file. Here is a short description of each subdirectory:
* `airflow-operator-and-base` - main components of Airflow. Without this users cannot create Airflow Cluster.
* `airflow-cluster` - instances of Airflow, which can be launched only once in particular namespace (tenant). This is called Airflow Cluster. After installing this users can schedule their jobs via UI.
* `hpe-imagepull-secrets` - secrets which are used to pull docker images.
* `hpecp-ext-auth-secret` - settings of AD/LDAP authentication on cluster.
