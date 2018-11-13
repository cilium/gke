Deploying Cilium on GKE
=======================

This directory contains the necessary scripts to deploy GKE cluster with Cilium backed by etcd operator

Due to compatibility problems with Daemonsets running in kube-system namespace in GKE clusters, Cilium is deployed in `cilium` namespace.

Make sure to set your node pools to use kernel new enough to run Cilium.

Creating 3 node cluster
-----------------------

To create 3 node cluster with Cilium, run `run.sh` script from this repository.
Make sure that `gcloud` and `go` are installed and your $PATH points to $GOPATH/bin directory.

This script will:
1. install `cfssl` and `cfssjson` utilities to your GOPATH
2. create standard container in GKE. Script is configured by env variables:
  - `CLUSTER_NAME`
  - `GKE_PROJECT`
  - `GKE_REGION`
  - `GKE_ZONE`
  - `ADMIN_USER`
3. create `cilium` namespace
4. create cluster role binding for user `$ADMIN_USER` (your email address that you registered in GCP with)
5. deploy etcd operator
6. deploy Cilium

Deploying Cilium in custom cluster
----------------------------------

If you already have a GKE cluster in which you want to deploy Cilium, comment out all lines that begin with `gcloud` in `run.sh`, then run the script. You may also want to comment out `kubectl create clusterrolebinding cluster-admin-binding --clusterrole cluster-admin --user $ADMIN_USER`, depending on your setup.
