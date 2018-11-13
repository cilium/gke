#!/bin/bash

CLUSTER_NAME="${CLUSTER_NAME:-default-cluster}"
GKE_PROJECT="${GKE_PROJECT:-default-project}"
GKE_REGION="${GKE_REGION:-europe-north1}"
GKE_ZONE="${GKE_ZONE:--a}"

go get -u -v github.com/cloudflare/cfssl/cmd/cfssl
go get -u -v github.com/cloudflare/cfssl/cmd/cfssljson

gcloud beta container --project $GKE_PROJECT clusters create $CLUSTER_NAME --zone $GKE_REGION$GKE_ZONE --username "admin" --cluster-version "1.11.2-gke.15" --machine-type "n1-standard-1" --image-type "COS_CONTAINERD" --disk-type "pd-standard" --disk-size "100" --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" --num-nodes "3" --no-enable-cloud-logging --no-enable-cloud-monitoring --network "projects/$GKE_PROJECT/global/networks/default" --subnetwork "projects/$GKE_PROJECT/regions/$GKE_REGION/subnetworks/default" --addons HorizontalPodAutoscaling,HttpLoadBalancing --no-enable-autoupgrade --no-enable-autorepair

gcloud container clusters get-credentials standard-cluster-1 --zone $GKE_REGION$GKE_ZONE --project $GKE_PROJECT

until kubectl get pods; do sleep 1; done

kubectl create ns cilium
kubectl create clusterrolebinding cluster-admin-binding --clusterrole cluster-admin --user $ADMIN_USER

./tls/certs/gen-cert.sh cluster.local
./tls/deploy-certs.sh

kubectl create -f 00-crd-etcd.yaml

until kubectl apply -f cilium-etcd-cluster.yaml; do sleep 1; done

kubectl apply -f .
kubectl -n kube-system delete pod -l k8s-app=kube-dns
