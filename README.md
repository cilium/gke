# Deploying Cilium on GKE

This directory contains the necessary scripts to deploy GKE cluster with Cilium backed by etcd operator

Due to compatibility problems with Daemonsets running in kube-system namespace in GKE clusters, Cilium is deployed in `cilium` namespace.

Make sure to set your node pools to use kernel new enough to run Cilium.

##Creating 3 node cluster

To create 3 node cluster with Cilium, run `run-gke-w-cilium.sh` script from this repository.
Make sure that `gcloud` and `go` are installed and your $PATH points to $GOPATH/bin directory.

Running this script will cause your account to be billed according to GKE standard billing.

This script will:
1. install `cfssl` and `cfssjson` utilities to your GOPATH
2. create standard cluster in GKE. Script is configured by env variables:
  - `CLUSTER_NAME` (required)
  - `GKE_PROJECT` (required)
  - `GKE_REGION` (defaults to `europe-north1`)
  - `GKE_ZONE` (defaults to `-a`)
  - `GKE_VERSION` (defaults to newest 1.11 version available in zone fetched from gcloud)
  - `ADMIN_USER` (required)
3. create `cilium` namespace
4. create cluster role binding for user `$ADMIN_USER` (your email address that you registered in GCP with)
5. deploy etcd operator
6. deploy Cilium


Now you can validate that Cilium is running properly in your cluster (requires Python>=2.7):
```
curl -sLO releases.cilium.io/tools/cluster-diagnosis.zip
python cluster-diagnosis.zip --namespace cilium
```

###Troubleshooting

If Cilium and etcd pods don't come up it's most possibly a problem with etcd operator. Remove and reapply operator manifest to fix this, Cilium should come up when etcd cluster is up.

```
kubectl delete -f etcd/cilium-etcd-cluster.yaml
kubectl apply -f etcd/cilium-etcd-cluster.yaml
```

##Deploying Cilium in custom cluster

If you already have a GKE cluster in which you want to deploy Cilium, comment out all lines that begin with `gcloud` in `run-gke-w-cilium.sh`, then run the script. You may also want to comment out `kubectl create clusterrolebinding cluster-admin-binding --clusterrole cluster-admin --user $ADMIN_USER`, depending on your setup.

If you already have a GKE cluster with etcd cluster running, which you would like to back your Cilium deployment make sure to edit `cilium-deployment.yaml` properly:
* change `etcd-config` field in `cilium-config` configmap to match your etcd address
* if you want tls to be used in etcd connection, make sure that `ca-file`, `key-file` and `cert-file` fields are pointing to proper files mounted into Cilium pod.
