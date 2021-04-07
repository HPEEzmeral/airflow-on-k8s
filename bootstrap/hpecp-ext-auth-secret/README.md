# LDAP secret

## Requirements

* version of `kubectl` should be 1.14 or above;

* namesapce `hpecp` should exists. If not, refer to instructions in `Install` section to fix it.

* LDAP or AD server

* bind type: searh bind

* protocols: LDAP or LDAPS

## Variables

* `auth_service_locations` - address of LDAP or AD server, e.g. `127.0.0.1:383`;

* `base_dn` - base DN, e.g. `ou=users,dc=example,dc=com`;

* `bind_dn` - bind DN, e.g. `cn=admin,dc=example,dc=com`;

* `bind_pwd` - bind password, e.g. `admin`;

* `user_attr` - user attribute, e.g. `uid`.

## Install

If namespace `hpecp` doesn't exists, create it with such commnad:

```bash
kubectl create ns hpecp
```

All variables should be set into env.

Example of command:

```bash
auth_service_locations="127.0.0.1:383" base_dn="ou=users,dc=example,dc=com" bind_dn="cn=admin,dc=example,dc=com" bind_pwd="admin" user_attr="uid" kubectl apply -k private-airflow-operator/bootstrap/hpecp-ext-auth-secret
```

## Uninstall

Execute such command:

```bash
kubectl delete secret hpecp-ext-auth-secret -n hpecp
```
