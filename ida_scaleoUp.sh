#!/bin/bash

# Define built-in namespaces to exclude
BUILT_IN_NAMESPACES=("kube-system" "kube-public" "kube-node-lease" "default" "system")

# Fetch EKS cluster names
clusters=$(curl -s "cmdb.a2org.com/cluster" | jq -r '.[]')

# Iterate over each cluster
for cluster in $clusters; do
    echo "Processing cluster: $cluster"
    
    # Fetch all namespaces in the cluster
    namespaces=$(kubectl --context="$cluster" get namespaces -o jsonpath='{.items[*].metadata.name}')
    
    for namespace in $namespaces; do
        # Skip built-in namespaces
        if [[ " ${BUILT_IN_NAMESPACES[@]} " =~ " ${namespace} " ]]; then
            echo "Skipping built-in namespace: $namespace"
            continue
        fi

        # Check if namespace is marked to not scale down
        check=$(curl -s "nonprod.a2org.com/clusternamespace" | jq -r --arg cluster "$cluster" --arg namespace "$namespace" '.[] | select(.cluster == $cluster and .namespace == $namespace)')
        
        if [[ -n "$check" ]]; then
            echo "Skipping protected namespace: $namespace in cluster: $cluster"
            continue
        fi

        # Scale down all deployments in the namespace
        echo "Scaling down all deployments in namespace: $namespace of cluster: $cluster"
        deployments=$(kubectl --context="$cluster" -n "$namespace" get deployments -o jsonpath='{.items[*].metadata.name}')
        for deployment in $deployments; do
            kubectl --context="$cluster" -n "$namespace" scale deployment "$deployment" --replicas=0
        done
    done
done

echo "Scaling down completed."
