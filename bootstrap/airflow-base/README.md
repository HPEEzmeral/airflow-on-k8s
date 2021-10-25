# AirflowBase

## Requirements

* version of `kubectl` should be 1.14 or above;

* Airflow operator should be in running state.

## Variables

* `AIRGAP_REGISTRY` - address of docker registry for airgapped env, e.g. `localhost:5000/` (Trailing slash is needed). If env is not airgapped, set empty string as value;

* `AIRFLOW_BASE_NAMESPACE` - name of namespace for AirflowBase. Use `airflow-base` as default vale.

## Install

All variables should be set into env.

We can choose which database will be used by AirflowBase. _(Currently MySQL is not supported)_

* AirflowBase with `PostgreSQL` database 

    Example of command:

    ```bash
    AIRGAP_REGISTRY="" AIRFLOW_BASE_NAMESPACE="airflow-base" kubectl apply -k airflow-on-k8s/bootstrap/airflow-base/overlays/postgres
    ```

* AirflowBase with `MySQL` database 

    Example of command:

    ```bash
    AIRGAP_REGISTRY="" AIRFLOW_BASE_NAMESPACE="airflow-base" kubectl apply -k airflow-on-k8s/bootstrap/airflow-base/overlays/mysql
    ```

## Uninstall

In this command replace `airflow-base` with value, which was set for `AIRFLOW_BASE_NAMESPACE` variable during installation:

```bash
kubectl delete airflowbase af-base -n airflow-base && kubectl delete ns airflow-base
```
