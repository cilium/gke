#!/bin/bash

CLUSTER_NAME="${CLUSTER_NAME:-default-cluster}"
GKE_PROJECT="${GKE_PROJECT:-default-project}"
GKE_REGION="${GKE_REGION:-europe-north1}"
GKE_ZONE="${GKE_ZONE:--a}"

gcloud container clusters get-credentials $CLUSTER_NAME --zone $GKE_REGION$GKE_ZONE --project $GKE_PROJECT
