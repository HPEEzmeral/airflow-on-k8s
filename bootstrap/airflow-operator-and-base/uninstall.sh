#!/bin/sh
#   Copyright 2021 Hewlett Packard Enterprise Development LP
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

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
