# Airflow operator

## Requirements

Version of `kubectl` should be 1.14 or above.

## Variables

* `AIRGAP_REGISTRY` - address of docker registry for airgapped env, e.g. `localhost:5000/` (Trailing slash is needed). If env is not airgapped, set empty string as value;

* `AIRFLOW_OPERATOR_NAMESPACE` - name of namespace for Airflow operator. Use `airflowop-system` as default vale;

* `AIRFLOW_OPERATOR_IMAGE_TAG` - tag of Airflow operator docker image. Set new tag to update the operator. Use `ecp-5.3.0-rc3` as default vale.

## Install

All variables should be set into env.

Example of command:

```bash
AIRGAP_REGISTRY="" AIRFLOW_OPERATOR_NAMESPACE="airflowop-system"  AIRFLOW_OPERATOR_IMAGE_TAG="ecp-5.3.0-rc3" kubectl apply -k private-airflow-operator/bootstrap/airflow-operator
```

## Uninstall

In this command replace `airflowop-system` with value, which was set for `AIRFLOW_OPERATOR_NAMESPACE` variable during installation:

```bash
kubectl delete ns airflowop-system && kubectl delete crd airflowbases.airflow.k8s.io  airflowclusters.airflow.k8s.io applications.app.k8s.io && kubectl delete clusterrolebinding airflowop-manager-rolebinding && kubectl delete clusterrole airflowop-manager-role
```
