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

if [ -z "$AIRFLOW_GIT_REPO_URL" ]; then
    echo -n "Error during installation of AirflowCluster: AIRFLOW_GIT_REPO_URL was empty, "
    echo "expected URL of git repository"
    exit 1
fi

AIRGAP_REGISTRY__DEFAULT_VALUE=""
AIRFLOW_CLUSTER_NAMESPACE__DEFAULT_VALUE="default"
AIRFLOW_CLUSTER_IMAGE_TAG__DEFAULT_VALUE="ecp-5.5.0-rc1"
AIRFLOW_BASE_NAMESPACE__DEFAULT_VALUE="airflow-base"
AIRFLOW_GIT_REPO_BRANCH__DEFAULT_VALUE=""
AIRFLOW_GIT_REPO_SUBDIR__DEFAULT_VALUE=""
GIT_PROXY_HTTP__DEFAULT_VALUE=""
GIT_PROXY_HTTPS__DEFAULT_VALUE=""
GIT_CERT_SECRET_NAME__DEFAULT_VALUE=""

if [ ! -z "$AIRGAP_REGISTRY" ] && ! expr "$AIRGAP_REGISTRY" : '^.*\/$' 1>/dev/null ; then
    AIRGAP_REGISTRY=${AIRGAP_REGISTRY}"/"
fi

AIRGAP_REGISTRY="${AIRGAP_REGISTRY:-$AIRGAP_REGISTRY__DEFAULT_VALUE}"
AIRFLOW_CLUSTER_NAMESPACE="${AIRFLOW_CLUSTER_NAMESPACE:-$AIRFLOW_CLUSTER_NAMESPACE__DEFAULT_VALUE}"
AIRFLOW_CLUSTER_IMAGE_TAG="${AIRFLOW_CLUSTER_IMAGE_TAG:-$AIRFLOW_CLUSTER_IMAGE_TAG__DEFAULT_VALUE}"
AIRFLOW_BASE_NAMESPACE="${AIRFLOW_BASE_NAMESPACE:-$AIRFLOW_BASE_NAMESPACE__DEFAULT_VALUE}"
AIRFLOW_GIT_REPO_BRANCH="${AIRFLOW_GIT_REPO_BRANCH:-$AIRFLOW_GIT_REPO_BRANCH__DEFAULT_VALUE}"
AIRFLOW_GIT_REPO_SUBDIR="${AIRFLOW_GIT_REPO_SUBDIR:-$AIRFLOW_GIT_REPO_SUBDIR__DEFAULT_VALUE}"
GIT_PROXY_HTTP="${GIT_PROXY_HTTP:-$GIT_PROXY_HTTP__DEFAULT_VALUE}"
GIT_PROXY_HTTPS="${GIT_PROXY_HTTPS:-$GIT_PROXY_HTTPS__DEFAULT_VALUE}"
GIT_CERT_SECRET_NAME="${GIT_CERT_SECRET_NAME:-$GIT_CERT_SECRET_NAME__DEFAULT_VALUE}"

export AIRGAP_REGISTRY AIRFLOW_CLUSTER_NAMESPACE AIRFLOW_CLUSTER_IMAGE_TAG AIRFLOW_BASE_NAMESPACE \
    AIRFLOW_GIT_REPO_BRANCH AIRFLOW_GIT_REPO_SUBDIR GIT_PROXY_HTTP GIT_PROXY_HTTPS GIT_CERT_SECRET_NAME

SCRIPTPATH=$(dirname ${0})

# Read secret string
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

# Check if selected namespace has got appropriate tenant resource
check_if_tenant_exists() {
    TENANT_NAMESPACE="$(kubectl get hpecptenant -n hpecp -o jsonpath=\'{.items[?\(@.spec.namespaceName==\"${AIRFLOW_CLUSTER_NAMESPACE}\"\)].spec.namespaceName}\' 2> /dev/null)"

    if [ "$TENANT_NAMESPACE" != "'$AIRFLOW_CLUSTER_NAMESPACE'" ]; then
        echo -n "ERROR: Current namespace '${AIRFLOW_CLUSTER_NAMESPACE}' does not have a corresponding tenant resource. "
        echo -n "Main DAGs functionality will not work as expected, because of DataTap feature. "
        echo "It's recommended to create a tenant and after that install Airflow Cluster in that namespace."
        exit 1
    fi
}

# Check if secret with needed authentication data is present in selected namespace
check_if_auth_secret_exists() {
    AUTH_SECRET_NAME="hpecp-ext-auth-secret"
    AUTH_SECRET_IN_NAMESPACE="$(kubectl get secret ${AUTH_SECRET_NAME} -n ${AIRFLOW_CLUSTER_NAMESPACE} -o jsonpath=\'{.metadata.name}\' 2> /dev/null)"

    if [ "$AUTH_SECRET_IN_NAMESPACE" != "'$AUTH_SECRET_NAME'" ]; then
        echo -n "ERROR: Current namespace '${AIRFLOW_CLUSTER_NAMESPACE}' does not have a '${AUTH_SECRET_NAME}' secret resource. "
        echo -n "The root cause can be that the current namespace does not have a corresponding tenant resource "
        echo "or current cluster is not configured with AD/LDAP authentication. Please, fix the issue and try again."
        echo "TIP: To create needed secret manually, please refer to the '../hpecp-ext-auth-secret/README.md' instruction file." 
        exit 1
    fi
}

check_if_tenant_exists
check_if_auth_secret_exists

if [ -z "$AIRFLOW_GIT_REPO_USER" ] && [ -z "$AIRFLOW_GIT_REPO_CRED_SECRET_NAME" ]; then 
    kubectl apply -k ${SCRIPTPATH}/overlays/public-repo
elif [ -z "$AIRFLOW_GIT_REPO_USER" ]; then
    echo -n "Error during installation of AirflowCluster: AIRFLOW_GIT_REPO_USER is empty, "
    echo -n "expected username of git repository when env variable "
    echo "AIRFLOW_GIT_REPO_CRED_SECRET_NAME was passed"
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
