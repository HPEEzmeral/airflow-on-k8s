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

AIRFLOW_IMAGE_TAG__CURRENT_VALUE="ecp-5.4.2-rc1"

if [ $AIRFLOW_UPGRADE_TO_CURRENT_VERSION = "true" ]; then
    echo -n "Upgrading to current version: ${AIRFLOW_IMAGE_TAG__CURRENT_VALUE}. Values of env variables "
    echo -n "AIRFLOW_OPERATOR_IMAGE_TAG and AIRFLOW_CLUSTER_DEFAULT_IMAGE_TAG will be equal to "
    echo "${AIRFLOW_IMAGE_TAG__CURRENT_VALUE}, because AIRFLOW_UPGRADE_TO_CURRENT_VERSION is set to true"
    export AIRFLOW_OPERATOR_IMAGE_TAG=$AIRFLOW_IMAGE_TAG__CURRENT_VALUE
    AIRFLOW_CLUSTER_DEFAULT_IMAGE_TAG=$AIRFLOW_IMAGE_TAG__CURRENT_VALUE
elif [ -z "$AIRFLOW_OPERATOR_IMAGE_TAG" ]; then
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

# scale statefulset with specified name passed in 1st arg in namespace passed in 2st arg to specified replicas passed in 3rd arg
scale_sts() {
    local sts_name="$1"
    local namespace="$2"
    local replicas="$3"
    kubectl scale sts -n "$namespace" $sts_name --replicas=$replicas
}

# stop statefulset with specified name passed in 1st arg in namespace passed in 2st arg
stop_sts() {
    scale_sts "$1" "$2" 0
}

# start statefulset with specified name passed in 1st arg in namespace passed in 2st arg
start_sts() {
    scale_sts "$1" "$2" 1
}

# restart statefulset with specified name passed in 1st arg in namespace passed in 2st arg
restart_sts() {
    local sts_name="$1"
    local namespace="$2"
    kubectl rollout restart -n "$namespace" sts $sts_name
}

# wait for pod with specified name passed in 1st arg in namespace passed in 2st arg to be ready
wait_pod_readiness() {
    local pod_name="$1"
    local namespace="$2"
    sleep 5
    for i in {1..60}; do
        kubectl get pod -n "$namespace" $pod_name > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            break
        fi
        sleep 5
    done
    kubectl wait --for=condition=ready pod -n "$namespace" $pod_name --timeout=700s
}

# stop all statefulsets of all AirflowClusters in all namespaces
stop_all_airflow_clusters() {
    for airflow_cluster_cm_namespace in ${airflow_cluster_cm_namespaces}; do
        namespace=$(get_value_from_cm $airflow_cluster_cm_name $airflow_cluster_cm_namespace AIRFLOW_CLUSTER_NAMESPACE) || exit $?
        stop_sts "af-cluster-airflowui af-cluster-scheduler" $namespace
    done
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

AIRFLOW_DB_SQL_PASSWORD=$(kubectl get secret -n $AIRFLOW_BASE_NAMESPACE af-base-sql -o jsonpath='{.data.password}' | base64 --decode)
AIRFLOW_DB_SQL_ROOTPASSWORD=$(kubectl get secret -n $AIRFLOW_BASE_NAMESPACE af-base-sql -o jsonpath='{.data.rootpassword}' | base64 --decode)

export AIRGAP_REGISTRY AIRFLOW_OPERATOR_NAMESPACE AIRFLOW_BASE_NAMESPACE AIRFLOW_CLUSTER_DEFAULT_IMAGE_TAG

SCRIPTPATH=$(dirname ${0})

printf "\nStarting upgrade of Airflow ...\n\n"

echo "Stopping operator and all AirflowClusters ..."
stop_sts airflowop-controller-manager $AIRFLOW_OPERATOR_NAMESPACE
stop_all_airflow_clusters
echo

echo "Dumping database ..."
kubectl exec -n $AIRFLOW_BASE_NAMESPACE af-base-postgres-0 -- bash -c "pg_dumpall -c --if-exists -U postgres -f dump.sql"
kubectl cp $AIRFLOW_BASE_NAMESPACE/af-base-postgres-0:dump.sql /tmp/dump.sql
kubectl exec -n $AIRFLOW_BASE_NAMESPACE af-base-postgres-0 -- bash -c "rm dump.sql"
echo

echo "Applying new Airflow Operator ..."
kubectl apply -k ${SCRIPTPATH}/../airflow-operator
echo

echo "Starting and restaring operator ..."
start_sts airflowop-controller-manager $AIRFLOW_OPERATOR_NAMESPACE
restart_sts airflowop-controller-manager $AIRFLOW_OPERATOR_NAMESPACE
echo

echo "Waiting for Airflow Operator to be ready ..."
wait_pod_readiness airflowop-controller-manager-0 $AIRFLOW_OPERATOR_NAMESPACE
echo

echo "Deleting AirflowBase namespace ..."
kubectl delete ns $AIRFLOW_BASE_NAMESPACE
echo

echo "Applying new AirflowBase ..."
if [ $AIRFLOW_BASE_IS_POSTGRES = "true" ]; then 
    kubectl apply -k ${SCRIPTPATH}/../airflow-base/overlays/postgres
else
    kubectl apply -k ${SCRIPTPATH}/../airflow-base/overlays/mysql
fi
echo

echo "Restoring passwords for database in secret and restarting databse ..."
kubectl create secret generic -n $AIRFLOW_BASE_NAMESPACE af-base-sql \
    --from-literal=password="$AIRFLOW_DB_SQL_PASSWORD" --from-literal=rootpassword="$AIRFLOW_DB_SQL_ROOTPASSWORD" \
    --dry-run=client -o yaml | kubectl apply -f -
restart_sts af-base-postgres $AIRFLOW_BASE_NAMESPACE
echo

echo "Waiting for database to be ready ..."
wait_pod_readiness af-base-postgres-0 $AIRFLOW_BASE_NAMESPACE
echo

echo "Stopping operator and all AirflowClusters ..."
stop_sts airflowop-controller-manager $AIRFLOW_OPERATOR_NAMESPACE
stop_all_airflow_clusters
echo

echo "Loading dump into database ..."
kubectl cp /tmp/dump.sql $AIRFLOW_BASE_NAMESPACE/af-base-postgres-0:dump.sql
kubectl exec -n $AIRFLOW_BASE_NAMESPACE af-base-postgres-0 -- bash -c "psql -U postgres -f dump.sql && rm dump.sql"
kubectl exec -n $AIRFLOW_BASE_NAMESPACE af-base-postgres-0 -- bash -c "psql -U postgres -c \"ALTER USER postgres WITH PASSWORD '$AIRFLOW_DB_SQL_ROOTPASSWORD';\""
rm /tmp/dump.sql
echo

echo "Starting operator ..."
start_sts airflowop-controller-manager $AIRFLOW_OPERATOR_NAMESPACE
echo

echo "Upgrading and restarting all AirflowClusters ..."
for airflow_cluster_cm_namespace in ${airflow_cluster_cm_namespaces}; do
    namespace=$(get_value_from_cm $airflow_cluster_cm_name $airflow_cluster_cm_namespace AIRFLOW_CLUSTER_NAMESPACE) || exit $?
    AIRFLOW_CLUSTER_IMAGE_TAG="${AIRFLOW_CLUSTER_DEFAULT_IMAGE_TAG}" AIRFLOW_CLUSTER_NAMESPACE="${namespace}" ${SCRIPTPATH}/../airflow-cluster/upgrade.sh
    kubectl create secret generic -n $namespace af-cluster-airflowui \
        --from-literal=rootpassword="$AIRFLOW_DB_SQL_ROOTPASSWORD" --dry-run=client -o yaml | kubectl apply -f -
    db_user=$(kubectl get airflowcluster -n $namespace af-cluster -o jsonpath='{.spec.scheduler.dbuser}')
    db_password=$(kubectl get secret -n $namespace af-cluster-airflowui -o jsonpath='{.data.password}' | base64 --decode)
    kubectl exec -n $AIRFLOW_BASE_NAMESPACE af-base-postgres-0 -- bash -c "createdb -U postgres $db_user || true"
    kubectl exec -n $AIRFLOW_BASE_NAMESPACE af-base-postgres-0 -- bash -c "psql -U postgres -c \"ALTER USER $db_user WITH PASSWORD '$db_password';\""
    start_sts "af-cluster-airflowui af-cluster-scheduler" $namespace
    restart_sts "af-cluster-airflowui af-cluster-scheduler" $namespace
done
echo

echo "Airflow upgrade done"
