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
from airflow.operators.python import PythonOperator
from pprint import pprint
from pyarrow import fs
import os

args = {
    'owner': 'airflow',
    'start_date': datetime.utcnow(),
}

dag = DAG(
    dag_id='dtap_dag_with_python',
    default_args=args,
    schedule_interval=timedelta(minutes=60),
    tags=['example', 'dtap']
)

def make_test_dtap_operations(ds, **kwargs):
    """Print the Airflow context and ds variable from the context."""
    pprint(kwargs)
    print(ds)
    
    dtapfs = fs.HadoopFileSystem.from_uri("dtap://TenantStorage")
    
    files = dtapfs.get_file_info(fs.FileSelector("/", recursive=True))
    print("All files traversal:")
    pprint(files)
    print()

    print("Creating text file...")
    dtapfs.create_dir('/test_python/')

    with dtapfs.open_output_stream('/test_python/test_check.txt') as f:
        f.write("Hello from this new file created by python operator!".encode('utf-8'))
    print()

    print("Reading created text file:")
    with dtapfs.open_input_file('/test_python/test_check.txt') as f:
        data = f.read()
        print(data.decode("utf-8"))
    print()

    print("Removing directory...")
    dtapfs.delete_dir('/test_python/')
    print()

    print("Appending file...")
    with dtapfs.open_append_stream('/test_python_arrow.txt') as f:
        f.write((str(datetime.utcnow()) + " arrow").encode('utf-8'))

    with dtapfs.open_input_file('/test_python_arrow.txt') as f:
        data = f.read()
        ret = data.decode("utf-8")

    return ret

first = PythonOperator(
    task_id='test_dtap_operations_python',
    python_callable=make_test_dtap_operations,
    dag=dag
)


def check_hadoop(ds, **kwargs):
    """Print the Airflow context and ds variable from the context."""
    pprint(kwargs)
    print(ds)

    return os.system("hadoop fs -ls dtap://TenantStorage/")

second = PythonOperator(
    task_id='test_dtap_operations_hadoop_from_python',
    python_callable=check_hadoop,
    dag=dag
)

first >> second
