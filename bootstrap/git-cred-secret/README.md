# Git cred secret

## Requirements

* version of `kubectl` should be 1.14 or above;

## Variables

* `password` - password of git repository.

## Install


All variables should be set into env.

In this command replace `default` with name of namespace, where secret should be installed:

```bash
password="12345" kubectl apply -k private-airflow-operator/bootstrap/git-cred-secret -n default
```

## Uninstall

In this command replace `default` with name of namespace, where secret was installed:

```bash
kubectl delete secret airflow-gitrepo-password -n default
```
