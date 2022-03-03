#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator

args = {
    'owner': 'airflow',
    'start_date': datetime.utcnow(),
}

dag = DAG(
    dag_id='dtap_dag_with_bash',
    default_args=args,
    schedule_interval=timedelta(minutes=60),
    tags=['example', 'dtap']
)

def ls(path: str):
    return BashOperator(
        task_id='ls_' + path.replace('/', '_').replace('.', '_') + '_bash_op_dtap',
        bash_command='hadoop fs -ls dtap://TenantStorage/' + path,
        dag=dag
    )

def rm(path: str):
    return BashOperator(
        task_id='rm_' + path.replace('/', '_').replace('.', '_') + '_bash_op_dtap',
        bash_command='hadoop fs -rm -r dtap://TenantStorage/' + path,
        dag=dag
    )

def cat(path: str):
    return BashOperator(
        task_id='cat_' + path.replace('/', '_').replace('.', '_') + '_bash_op_dtap',
        bash_command='hadoop fs -cat dtap://TenantStorage/' + path,
        dag=dag
    )

def mkdir(path: str):
    return BashOperator(
        task_id='mkdir_' + path.replace('/', '_').replace('.', '_') + '_bash_op_dtap',
        bash_command='hadoop fs -mkdir dtap://TenantStorage/' + path,
        dag=dag
    )

def put(path: str, data: str):
    return BashOperator(
        task_id='p_' + path.replace('/', '_').replace('.', '_') + '_d',
        bash_command='echo "' + data + '" | hadoop fs -put - dtap://TenantStorage/' + path,
        dag=dag
    )

def append(path: str, data: str): 
    return BashOperator(
        task_id='append_' + path.replace('/', '_').replace('.', '_') + '_bash_op_dtap',
        bash_command='echo "' + data + '" | hadoop fs -appendToFile - dtap://TenantStorage/' + path,
        dag=dag
    )

ls('') >> mkdir('dtap_test_dir') >> put('dtap_test_dir/test.txt', 'Hello from DAG') >> cat('dtap_test_dir/test.txt') >> rm('dtap_test_dir') >> append('test-dag-af.txt', str(datetime.utcnow()))

if __name__ == "__main__":
    dag.cli()
