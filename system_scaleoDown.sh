#!/bin/bash

# Define the system namespace
SYSTEM_NAMESPACE="system"

# Fetch EKS cluster names
clusters=$(curl -s "cmdb.a2org.com/cluster" | jq -r '.[]')

# Iterate over each cluster
for cluster in $clusters; do
    echo "Processing cluster: $cluster"

    # Fetch protected namespaces for the current cluster
    protected_namespaces=$(curl -s "nonprod.a2org.com/clusternamespace" | jq -r --arg cluster "$cluster" '.[] | select(.cluster == $cluster) | .namespace')

    if [[ -n "$protected_namespaces" ]]; then
        echo "Cluster $cluster has protected namespaces: $protected_namespaces"
        echo "Skipping scale-down of the 'system' namespace for this cluster."
        continue
    else
        echo "No protected namespaces for cluster $cluster. Proceeding to scale down the 'system' namespace."
    fi

    # Scale down all deployments in the 'system' namespace
    echo "Scaling down all deployments in namespace: $SYSTEM_NAMESPACE of cluster: $cluster"
    deployments=$(kubectl --context="$cluster" -n "$SYSTEM_NAMESPACE" get deployments -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
    if [[ -n "$deployments" ]]; then
        for deployment in $deployments; do
            kubectl --context="$cluster" -n "$SYSTEM_NAMESPACE" scale deployment "$deployment" --replicas=0
            echo "Scaled down deployment: $deployment in namespace: $SYSTEM_NAMESPACE of cluster: $cluster"
        done
    else
        echo "No deployments found in namespace: $SYSTEM_NAMESPACE of cluster: $cluster"
    fi
done

echo "Scale-down of 'system' namespace completed."
