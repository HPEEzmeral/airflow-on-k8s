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

if [ -z "$AIRFLOW_OPERATOR_IMAGE_TAG" ]; then
    echo -n "Error during upgrade of Airflow operator and Base: AIRFLOW_OPERATOR_IMAGE_TAG was empty, "
    echo "expected new tag for operator image"
    exit 1
fi

# find namespace of specified name of configmap in arguments
get_namespace_of_cm_by_name() {
    local result exit_code
    result=$(kubectl get cm -A --field-selector metadata.name==$1 --sort-by {.metadata.creationTimestamp} -o jsonpath={.items[0].metadata.namespace})
    exit_code=$?
    if [ $exit_code -ne 0 ] || [ -z "$result" ]; then
        echo "Error during upgrade of Airflow operator and Base: couldn't find namespace for configmap $1" >&2
        return $exit_code
    fi
    echo $result
}

# get namespaces of specified name of configmap in arguments
get_namespaces_of_cm_by_name() {
    local result exit_code
    result=$(kubectl get cm -A --field-selector metadata.name==$1 -o jsonpath={.items[*].metadata.namespace})
    exit_code=$?
    if [ $exit_code -ne 0 ] || [ -z "$result" ]; then
        echo "Error during upgrade of Airflow operator and Base: couldn't find namespaces for configmap $1" >&2
        return $exit_code
    fi
    echo $result
}

# get value from configmap with name passed in 1st argument in namespace passed in 2nd agument by key passed in 3rd argument
get_value_from_cm() {
    local result exit_code
    result=$(kubectl get cm $1 -n $2 -o jsonpath={.data.$3} --allow-missing-template-keys=false)
    exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo "Error during upgrade of Airflow operator and Base: couldn't get value by key $3 from configmap $1 in namespace $2" >&2
        return $exit_code
    fi
    echo $result
}

airflow_operator_cm_name="airflow-operator-common-cm"
airflow_operator_cm_namespace=$(get_namespace_of_cm_by_name $airflow_operator_cm_name) || exit $?

airflow_base_cm_name="airflow-base-common-cm"
airflow_base_cm_namespace=$(get_namespace_of_cm_by_name $airflow_base_cm_name) || exit $?

airflow_cluster_cm_name="airflow-cluster-common-cm"
airflow_cluster_cm_namespaces=$(get_namespaces_of_cm_by_name airflow-cluster-common-cm) || exit $?

AIRGAP_REGISTRY__SETTED_VALUE=$(get_value_from_cm $airflow_operator_cm_name $airflow_operator_cm_namespace AIRGAP_REGISTRY) || exit $?
AIRFLOW_OPERATOR_NAMESPACE__SETTED_VALUE=$(get_value_from_cm $airflow_operator_cm_name $airflow_operator_cm_namespace AIRFLOW_OPERATOR_NAMESPACE) || exit $?
AIRFLOW_CLUSTER_DEFAULT_IMAGE_TAG__SETTED_VALUE=$(get_value_from_cm $airflow_operator_cm_name $airflow_operator_cm_namespace AIRFLOW_CLUSTER_DEFAULT_IMAGE_TAG) || $AIRFLOW_OPERATOR_IMAGE_TAG
AIRFLOW_BASE_NAMESPACE__SETTED_VALUE=$(get_value_from_cm $airflow_base_cm_name $airflow_base_cm_namespace AIRFLOW_BASE_NAMESPACE) || exit $?
AIRFLOW_BASE_IS_POSTGRES__SETTED_VALUE=$(get_value_from_cm $airflow_base_cm_name $airflow_base_cm_namespace AIRFLOW_BASE_IS_POSTGRES) || exit $?

AIRGAP_REGISTRY="${AIRGAP_REGISTRY:-$AIRGAP_REGISTRY__SETTED_VALUE}"
AIRFLOW_OPERATOR_NAMESPACE="$AIRFLOW_OPERATOR_NAMESPACE__SETTED_VALUE"
AIRFLOW_CLUSTER_DEFAULT_IMAGE_TAG="${AIRFLOW_CLUSTER_DEFAULT_IMAGE_TAG:-$AIRFLOW_CLUSTER_DEFAULT_IMAGE_TAG__SETTED_VALUE}"
AIRFLOW_BASE_NAMESPACE="$AIRFLOW_BASE_NAMESPACE__SETTED_VALUE"
AIRFLOW_BASE_IS_POSTGRES="$AIRFLOW_BASE_IS_POSTGRES__SETTED_VALUE"

export AIRGAP_REGISTRY AIRFLOW_OPERATOR_NAMESPACE AIRFLOW_BASE_NAMESPACE AIRFLOW_CLUSTER_DEFAULT_IMAGE_TAG

SCRIPTPATH=$(dirname ${0})

kubectl apply -k ${SCRIPTPATH}/../airflow-operator

kubectl delete airflowbase af-base -n $AIRFLOW_BASE_NAMESPACE

if [ $AIRFLOW_BASE_IS_POSTGRES = "true" ]; then 
    kubectl apply -k ${SCRIPTPATH}/../airflow-base/overlays/postgres
else
    kubectl apply -k ${SCRIPTPATH}/../airflow-base/overlays/mysql
fi

kubectl wait --for=condition=ready pod af-base-postgres-0 -n $AIRFLOW_BASE_NAMESPACE --timeout=300s

for airflow_cluster_cm_namespace in ${airflow_cluster_cm_namespaces}; do
    namespace=$(get_value_from_cm $airflow_cluster_cm_name $airflow_cluster_cm_namespace AIRFLOW_CLUSTER_NAMESPACE) || exit $?
    kubectl rollout restart -n $namespace sts af-cluster-airflowui af-cluster-scheduler af-cluster-worker
done
