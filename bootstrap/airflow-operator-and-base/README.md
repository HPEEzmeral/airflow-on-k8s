# Airflow operator & AirflowBase

## Requirements

Version of `kubectl` should be 1.14 or above.

## Variables

* `AIRGAP_REGISTRY` - address of docker registry for airgapped env, e.g. `localhost:5000/` (Trailing slash is needed). If env is not airgapped, set empty string as value;

* `AIRFLOW_OPERATOR_NAMESPACE` - name of namespace for Airflow operator. Use `airflowop-system` as default vale;

* `AIRFLOW_OPERATOR_IMAGE_TAG` - tag of Airflow operator docker image. Set new tag to update the operator. Use `ecp-5.5.1-rc1` as default vale;

* `AIRFLOW_BASE_NAMESPACE` - name of namespace for AirflowBase. Use `airflow-base` as default vale;

* `AIRFLOW_CLUSTER_DEFAULT_IMAGE_TAG` - tag of Airflow docker image. This tag is used, when operator creates new AirflowCluster from Source Control, which is created by HCP UI. Use `ecp-5.5.1-rc1` as default value. If specified value is empty it will be equal to `AIRFLOW_OPERATOR_IMAGE_TAG`;

* `AIRFLOW_UPGRADE_TO_CURRENT_VERSION` - variable which is used only for upgrade scenario by upgrade.sh script. If value equals `true`, Airflow Operator and Base together with all Airflow Clusters will be upgraded to the tag `ecp-5.5.1-rc1`. Otherwise, the tag in `AIRFLOW_OPERATOR_IMAGE_TAG` environment variable will be used. The default value is `false`.

## Install

All variables should be set into env.

We can choose which database will be used by AirflowBase. _(Currently MySQL is not supported)_

### Install with shell script

We can install Airflow operator & AirflowBase by executing such shell script:

```bash
/bin/sh airflow-on-k8s/bootstrap/airflow-operator-and-base/install.sh
```

We can customize installation with the same env variables, as above.

To install AirflowBase with PostgreSQL we need to set `AIRFLOW_BASE_IS_POSTGRES` env variable with `true` value (this is a default value). If otherwise is specified, AirflowBase with MySQL will be installed.

If needed env variables aren't provided, default values will be used. 

## Upgrade

We can upgrade Airflow operator & AirflowBase by executing such shell script:

```bash
AIRFLOW_OPERATOR_IMAGE_TAG="<place_here_new_tag>" /bin/sh airflow-on-k8s/bootstrap/airflow-operator-and-base/upgrade.sh
```

We need to pass new tag of Airflow operator in `AIRFLOW_OPERATOR_IMAGE_TAG` env variable. If this env variable is not set and `AIRFLOW_UPGRADE_TO_CURRENT_VERSION` env variable doesn't equal `true`, script will be failed with error. Also we can pass `AIRGAP_REGISTRY` env variable to override previous settings.

Instead of setting `AIRFLOW_OPERATOR_IMAGE_TAG` env variable, we can set `AIRFLOW_UPGRADE_TO_CURRENT_VERSION` with value `true`, which will upgrade Airflow operator, Airflow Base and all Airflow Clusters to the tag `ecp-5.5.1-rc1`.

## Uninstall

In this command replace `airflow-base` with value, which was set for `AIRFLOW_BASE_NAMESPACE` variable during installation, and replcae `airflowop-system` with value, which was set for `AIRFLOW_OPERATOR_NAMESPACE` variable during installation:

```bash
kubectl delete airflowbase af-base -n airflow-base && kubectl delete ns airflow-base && kubectl delete ns airflowop-system && kubectl delete crd airflowbases.airflow.hpe.com  airflowclusters.airflow.hpe.com applications.app.k8s.io && kubectl delete clusterrolebinding airflowop-manager-rolebinding && kubectl delete clusterrole airflowop-manager-role
```

### Uninstall with shell script

We can uninstall Airflow operator & AirflowBase by executing such shell script:

```bash
/bin/sh airflow-on-k8s/bootstrap/airflow-operator-and-base/uninstall.sh
```

We need to set `AIRFLOW_OPERATOR_NAMESPACE` and `AIRFLOW_BASE_NAMESPACE` variables, if their values were different from default ones during installation.
