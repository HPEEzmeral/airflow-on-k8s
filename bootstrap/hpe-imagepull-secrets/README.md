# HPE imagepull secret

## Requirements

* version of `kubectl` should be 1.14 or above;

## Install

In this command replace `default` with name of namespace, where secret should be installed:

```bash
kubectl apply -k private-airflow-operator/bootstrap/hpe-imagepull-secrets -n default
```

## Uninstall

In this command replace `default` with name of namespace, where secret was installed:

```bash
kubectl delete secret hpe-imagepull-secrets -n default
```
