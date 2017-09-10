import pytest
import random
import subprocess

import ray

def start_redis(num_retries=20):
    retry_counter = 0
    while retry_counter < num_retries:
        port = random.randint(10000, 65535)
        p = subprocess.Popen(["redis-server", "--port", str(port)])
        if p.poll() is None:
            break
    if retry_counter == num_retries:
        raise Exception("Couldn't start Redis.")
    return port, p

def f():
    return 42

def test_function_register_retrieve():
    port, p = start_redis()
    client = ray.connect_gcs("127.0.0.1", port)
    job_id = ray.JobID.from_random()
    function_id = ray.FunctionID.from_random()
    client.register_function(job_id, function_id, f, f)
    name, func = client.retrieve_function(job_id, function_id)
    assert func() == 42
    p.kill()
