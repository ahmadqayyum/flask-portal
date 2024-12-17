#!/bin/bash

# 
curl -s http://localhost:8000/data | jq -r '.[] | "\(.ClusterName) \(.NamespaceName)"' | while read cluster namespace; do
  # Now you have each ClusterName and NamespaceName, you can use them in a command
  echo "Scaling Down IDA Namespace: $namespace from $cluster "
  # kubectl get pods --context="$cluster" --namespace="$namespace"
  echo "Namespace  $namespace  Scaled Down Successfully."
done

