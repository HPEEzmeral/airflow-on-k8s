#!/bin/sh

AIRFLOW_OPERATOR_NAMESPACE__DEFAULT_VALUE="airflowop-system"
AIRFLOW_BASE_NAMESPACE__DEFAULT_VALUE="airflow-base"

AIRFLOW_OPERATOR_NAMESPACE="${AIRFLOW_OPERATOR_NAMESPACE:-$AIRFLOW_OPERATOR_NAMESPACE__DEFAULT_VALUE}"
AIRFLOW_BASE_NAMESPACE="${AIRFLOW_BASE_NAMESPACE:-$AIRFLOW_BASE_NAMESPACE__DEFAULT_VALUE}"

kubectl delete airflowbase af-base -n $AIRFLOW_BASE_NAMESPACE
kubectl delete ns $AIRFLOW_BASE_NAMESPACE
kubectl delete ns $AIRFLOW_OPERATOR_NAMESPACE
kubectl delete crd airflowbases.airflow.k8s.io airflowclusters.airflow.k8s.io applications.app.k8s.io
kubectl delete clusterrolebinding airflowop-manager-rolebinding
kubectl delete clusterrole airflowop-manager-role
