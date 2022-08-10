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

if [ -z "$AIRFLOW_CLUSTER_IMAGE_TAG" ]; then
    echo -n "Error during upgrade of Airflow Cluster: AIRFLOW_CLUSTER_IMAGE_TAG was empty, "
    echo "expected new tag for airflow image"
    exit 1
elif [ -z "$AIRFLOW_CLUSTER_NAMESPACE" ]; then
    echo -n "Error during upgrade of Airflow Cluster: AIRFLOW_CLUSTER_NAMESPACE was empty, "
    echo "expected name of namespace, where desired to upgrade Airflow Cluster is located"
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

# get value from configmap with name passed in 1st argument in namespace passed in 2nd agument by key passed in 3rd argument, 4th argument enables silent mode if set to true
get_value_from_cm() {
    local result exit_code
    if [ ${4:-false} = "true" ]; then
        result=$(kubectl get cm $1 -n $2 -o jsonpath={.data.$3} --allow-missing-template-keys=false 2> /dev/null)
    else
        result=$(kubectl get cm $1 -n $2 -o jsonpath={.data.$3} --allow-missing-template-keys=false)
    fi
    exit_code=$?
    if [ $exit_code -ne 0 ]; then
        if [  ${4:-false} != "true" ]; then
            echo "Error during upgrade of Airflow operator and Base: couldn't get value by key $3 from configmap $1 in namespace $2" >&2
        fi
        return $exit_code
    fi
    echo $result
}

# Read secret string into 1st argument
read_secret() {
    # Disable echo.
    stty -echo

    # Set up trap to ensure echo is enabled before exiting if the script
    # is terminated while echo is disabled.
    trap 'stty echo' EXIT

    # Read secret.
    read "$@"

    # Enable echo.
    stty echo
    trap - EXIT

    # Print a newline because the newline entered by the user after
    # entering the passcode is not echoed. This ensures that the
    # next line of output begins at a new line.
    echo
}

airflow_cluster_cm_name="airflow-cluster-common-cm"
airflow_cluster_cm_namespace=$AIRFLOW_CLUSTER_NAMESPACE

AIRGAP_REGISTRY__SETTED_VALUE=$(get_value_from_cm $airflow_cluster_cm_name $airflow_cluster_cm_namespace AIRGAP_REGISTRY) || exit $?
AIRFLOW_BASE_NAMESPACE__SETTED_VALUE=$(get_value_from_cm $airflow_cluster_cm_name $airflow_cluster_cm_namespace AIRFLOW_BASE_NAMESPACE) || exit $?
AIRFLOW_GIT_REPO_URL__SETTED_VALUE=$(get_value_from_cm $airflow_cluster_cm_name $airflow_cluster_cm_namespace AIRFLOW_GIT_REPO_URL) || exit $?
AIRFLOW_GIT_REPO_BRANCH__SETTED_VALUE=$(get_value_from_cm $airflow_cluster_cm_name $airflow_cluster_cm_namespace AIRFLOW_GIT_REPO_BRANCH) || exit $?
AIRFLOW_GIT_REPO_SUBDIR__SETTED_VALUE=$(get_value_from_cm $airflow_cluster_cm_name $airflow_cluster_cm_namespace AIRFLOW_GIT_REPO_SUBDIR) || exit $?
GIT_PROXY_HTTP__SETTED_VALUE=$(get_value_from_cm $airflow_cluster_cm_name $airflow_cluster_cm_namespace GIT_PROXY_HTTP) || exit $?
GIT_PROXY_HTTPS__SETTED_VALUE=$(get_value_from_cm $airflow_cluster_cm_name $airflow_cluster_cm_namespace GIT_PROXY_HTTPS) || exit $?
AIRFLOW_GIT_REPO_USER__SETTED_VALUE=$(get_value_from_cm $airflow_cluster_cm_name $airflow_cluster_cm_namespace AIRFLOW_GIT_REPO_USER true)
AIRFLOW_GIT_REPO_USER__IS_NOT_SET=$?
AIRFLOW_GIT_REPO_CRED_SECRET_NAME__SETTED_VALUE=$(get_value_from_cm $airflow_cluster_cm_name $airflow_cluster_cm_namespace AIRFLOW_GIT_REPO_CRED_SECRET_NAME true)
AIRFLOW_GIT_REPO_CRED_SECRET_NAME__IS_NOT_SET=$?
GIT_CERT_SECRET_NAME__SETTED_VALUE=$(get_value_from_cm $airflow_cluster_cm_name $airflow_cluster_cm_namespace GIT_CERT_SECRET_NAME true) || GIT_CERT_SECRET_NAME__SETTED_VALUE=""

AIRGAP_REGISTRY="${AIRGAP_REGISTRY:-$AIRGAP_REGISTRY__SETTED_VALUE}"
AIRFLOW_BASE_NAMESPACE="$AIRFLOW_BASE_NAMESPACE__SETTED_VALUE"
AIRFLOW_GIT_REPO_URL="${AIRFLOW_GIT_REPO_URL:-$AIRFLOW_GIT_REPO_URL__SETTED_VALUE}"
AIRFLOW_GIT_REPO_BRANCH="${AIRFLOW_GIT_REPO_BRANCH:-$AIRFLOW_GIT_REPO_BRANCH__SETTED_VALUE}"
AIRFLOW_GIT_REPO_SUBDIR="${AIRFLOW_GIT_REPO_SUBDIR:-$AIRFLOW_GIT_REPO_SUBDIR__SETTED_VALUE}"
GIT_PROXY_HTTP="${GIT_PROXY_HTTP:-$GIT_PROXY_HTTP__SETTED_VALUE}"
GIT_PROXY_HTTPS="${GIT_PROXY_HTTPS:-$GIT_PROXY_HTTPS__SETTED_VALUE}"
GIT_CERT_SECRET_NAME="${GIT_CERT_SECRET_NAME:-$GIT_CERT_SECRET_NAME__SETTED_VALUE}"

export AIRGAP_REGISTRY AIRFLOW_BASE_NAMESPACE AIRFLOW_GIT_REPO_BRANCH AIRFLOW_GIT_REPO_SUBDIR GIT_PROXY_HTTP GIT_PROXY_HTTPS AIRFLOW_GIT_REPO_URL GIT_CERT_SECRET_NAME

SCRIPTPATH=$(dirname ${0})

if [ ${AIRFLOW_CLUSTER_UPGRADE_SET_NEW_GIT_CRED:-false} = "true" ]; then
    if [ -z "$AIRFLOW_GIT_REPO_USER" ] && [ -z "$AIRFLOW_GIT_REPO_CRED_SECRET_NAME" ]; then 
        kubectl apply -k ${SCRIPTPATH}/overlays/public-repo
    elif [ -z "$AIRFLOW_GIT_REPO_USER" ]; then
        echo -n "Error during upgrade of AirflowCluster: AIRFLOW_GIT_REPO_USER is empty, "
        echo -n "expected username of git repository when env variable "
        echo "AIRFLOW_GIT_REPO_CRED_SECRET_NAME was passed and AIRFLOW_CLUSTER_UPGRADE_SET_NEW_GIT_CRED is true"
        exit 1
    elif [ -z "$AIRFLOW_GIT_REPO_CRED_SECRET_NAME" ]; then
        echo -n "Enter cred of git repository: "
        read_secret password
        export AIRFLOW_GIT_REPO_USER password
        kubectl apply -k ${SCRIPTPATH}/overlays/private-repo-password
        unset password
    else
        export AIRFLOW_GIT_REPO_USER AIRFLOW_GIT_REPO_CRED_SECRET_NAME
        kubectl apply -k ${SCRIPTPATH}/overlays/private-repo-secret
    fi
else
    unset AIRFLOW_GIT_REPO_USER AIRFLOW_GIT_REPO_CRED_SECRET_NAME
    if [ $AIRFLOW_GIT_REPO_USER__IS_NOT_SET -ne 0 ] && [ $AIRFLOW_GIT_REPO_CRED_SECRET_NAME__IS_NOT_SET -ne 0 ]; then
        kubectl apply -k ${SCRIPTPATH}/overlays/public-repo
    elif [ $AIRFLOW_GIT_REPO_USER__IS_NOT_SET -eq 0 ] && [ $AIRFLOW_GIT_REPO_CRED_SECRET_NAME__IS_NOT_SET -eq 0 ]; then
        AIRFLOW_GIT_REPO_USER=$AIRFLOW_GIT_REPO_USER__SETTED_VALUE
        AIRFLOW_GIT_REPO_CRED_SECRET_NAME=$AIRFLOW_GIT_REPO_CRED_SECRET_NAME__SETTED_VALUE
        export AIRFLOW_GIT_REPO_USER AIRFLOW_GIT_REPO_CRED_SECRET_NAME
        kubectl apply -k ${SCRIPTPATH}/overlays/private-repo-secret
    else      
        echo "Error during upgrade of AirflowCluster: previous install was broken"
        exit 1
    fi
fi
