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

AIRGAP_REGISTRY__DEFAULT_VALUE=""
AIRFLOW_OPERATOR_NAMESPACE__DEFAULT_VALUE="airflowop-system"
AIRFLOW_OPERATOR_IMAGE_TAG__DEFAULT_VALUE="ecp-5.4.2-rc1"
AIRFLOW_BASE_NAMESPACE__DEFAULT_VALUE="airflow-base"
AIRFLOW_BASE_IS_POSTGRES__DEFAULT_VALUE="true"

if [ ! -z "$AIRGAP_REGISTRY" ] && ! expr "$AIRGAP_REGISTRY" : '^.*\/$' 1>/dev/null ; then
    AIRGAP_REGISTRY=${AIRGAP_REGISTRY}"/"
fi

AIRGAP_REGISTRY="${AIRGAP_REGISTRY:-$AIRGAP_REGISTRY__DEFAULT_VALUE}"
AIRFLOW_OPERATOR_NAMESPACE="${AIRFLOW_OPERATOR_NAMESPACE:-$AIRFLOW_OPERATOR_NAMESPACE__DEFAULT_VALUE}"
AIRFLOW_OPERATOR_IMAGE_TAG="${AIRFLOW_OPERATOR_IMAGE_TAG:-$AIRFLOW_OPERATOR_IMAGE_TAG__DEFAULT_VALUE}"
AIRFLOW_BASE_NAMESPACE="${AIRFLOW_BASE_NAMESPACE:-$AIRFLOW_BASE_NAMESPACE__DEFAULT_VALUE}"
AIRFLOW_BASE_IS_POSTGRES="${AIRFLOW_BASE_IS_POSTGRES:-$AIRFLOW_BASE_IS_POSTGRES__DEFAULT_VALUE}"

if [ -z "$AIRFLOW_CLUSTER_DEFAULT_IMAGE_TAG" ] ; then
    AIRFLOW_CLUSTER_DEFAULT_IMAGE_TAG=${AIRFLOW_OPERATOR_IMAGE_TAG}
fi

export AIRGAP_REGISTRY AIRFLOW_OPERATOR_NAMESPACE AIRFLOW_OPERATOR_IMAGE_TAG AIRFLOW_BASE_NAMESPACE AIRFLOW_CLUSTER_DEFAULT_IMAGE_TAG

SCRIPTPATH=$(dirname ${0})

kubectl apply -k ${SCRIPTPATH}/../airflow-operator

if [ $AIRFLOW_BASE_IS_POSTGRES = "true" ]; then 
    kubectl apply -k ${SCRIPTPATH}/../airflow-base/overlays/postgres
else
    kubectl apply -k ${SCRIPTPATH}/../airflow-base/overlays/mysql
fi
