#!/bin/sh

AIRFLOW_CLUSTER_NAMESPACE__DEFAULT_VALUE="default"

AIRFLOW_CLUSTER_NAMESPACE="${AIRFLOW_CLUSTER_NAMESPACE:-$AIRFLOW_CLUSTER_NAMESPACE__DEFAULT_VALUE}"

kubectl delete airflowcluster af-cluster -n ${AIRFLOW_CLUSTER_NAMESPACE}
kubectl delete cm airflow-cluster-common-cm -n ${AIRFLOW_CLUSTER_NAMESPACE}
kubectl delete secret hpe-imagepull-secrets -n ${AIRFLOW_CLUSTER_NAMESPACE}
