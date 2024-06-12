#!/bin/bash

function delete_pods_by_status {
    local namespace="$1"
    local status="$2"
    kubectl -n "$namespace" get pods | grep "$status" | awk '{print $1}' | xargs kubectl -n "$namespace" delete pods
}

#ERROR
delete_pods_by_status "default" "Error"
delete_pods_by_status "cncp-system" "Error"
delete_pods_by_status "metallb-system" "Error"
delete_pods_by_status "kubernetes-dashboard" "Error"
delete_pods_by_status "openebs" "Error"
delete_pods_by_status "kube-system" "Error"
delete_pods_by_status "cncp-production" "Error"

#completed
delete_pods_by_status "default" "Completed"
delete_pods_by_status "cncp-system" "Completed"
delete_pods_by_status "metallb-system" "Completed"
delete_pods_by_status "kubernetes-dashboard" "Completed"
delete_pods_by_status "openebs" "Completed"
delete_pods_by_status "kube-system" "Completed"
delete_pods_by_status "cncp-production" "Completed"