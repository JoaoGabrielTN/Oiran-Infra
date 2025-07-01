import numpy as np
import requests
import json 


queries = ['100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)', 
           '(node_memory_MemTotal_bytes - node_memory_MemFree_bytes - node_memory_Cached_bytes - node_memory_Buffers_bytes) / node_memory_MemTotal_bytes']
PROMETHEUS_URL = "http://host.docker.internal:9090"

def query_prometheus(query):
    response = requests.get(
        f"{PROMETHEUS_URL}/api/v1/query",
        params={"query": query}
    )
    return response.json()

def obsevation(data_stack):
    obs = []
    for data in data_stack:
        aux = []
        for val in data['data']['result']:
            aux.append(val['value'][1])
        obs.append(aux)
    return obs

data_stack = [query_prometheus(query) for query in queries]
obs = obsevation(data_stack)
obs = np.asarray(obs)
obs = obs.T
np.save('/app/output/observation.npy', obs)