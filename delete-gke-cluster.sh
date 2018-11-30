#!/bin/bash

CLUSTER_NAME="${CLUSTER_NAME:-default-cluster}"
GKE_PROJECT="${GKE_PROJECT:-default-project}"
GKE_REGION="${GKE_REGION:-europe-north1}"
GKE_ZONE="${GKE_ZONE:--a}"

gcloud beta container --project $GKE_PROJECT clusters delete $CLUSTER_NAME --zone $GKE_REGION$GKE_ZONE
