# Deploying Cilium on GKE

This is a guide on how to set up Cilium on [Google GKE](https://cloud.google.com/kubernetes-engine/).

## GKE Requirements

1. Install the Google Cloud SDK (`gcloud`)

   ```
   curl https://sdk.cloud.google.com | bash
   ```

   For more information, see [Installing Google Cloud SDK](https://cloud.google.com/sdk/install)

2. Make sure you are authenticated to use the Google Cloud API:

   ```
   export ADMIN_USER=user@email.com
   glcoud auth login
   ```

   The `$ADMIN_USER` will be used to create a cluster role binding

3. Create a project

   ```
   export GKE_PROJECT=gke-clusters
   gcloud projects create $GKE_PROJECT
   ```

4. Enable the GKE API for the project

   ```
   gcloud services enable --project $GKE_PROJECT container.googleapis.com
   ```

## Creating the cluster

1. Specify optional cluster & zone parameters (optional):

   ```
   export GKE_REGION=europe-north1
   export GKE_ZONE=-a
   export GKE_VERSION=1.11
   ```

2. Create a GKE cluster and deploy Cilium

   ```
   CLUSTER_NAME=cluster1 ./create-gke-cluster.sh
   ```

## Verify Installation

```
$  kubectl -n cilium get pods
NAME                                    READY   STATUS    RESTARTS   AGE
cilium-5jm4g                            1/1     Running   1          15m
cilium-etcd-4rnwn47btn                  1/1     Running   0          13m
cilium-etcd-bd4qh529rj                  1/1     Running   0          14m
cilium-etcd-h79whhjzq8                  1/1     Running   0          14m
cilium-etcd-operator-5f647dbbf8-8vfn9   1/1     Running   0          15m
cilium-jlgs9                            1/1     Running   1          15m
cilium-vf528                            1/1     Running   1          15m
etcd-operator-759954d8db-w5ddm          1/1     Running   0          15m
```

## Deleting the cluster

```
CLUSTER_NAME=cluster1 ./delete-gke-cluster.sh
```

## Adding additional nodes

When adding additional nodes, the following commands have to be executed to
prepare the nodes and enable CNI in the kubelet configuration of the node:

```
FLAGS="--zone $GKE_REGION$GKE_ZONE --project $GKE_PROJECT"
gcloud compute ssh $INSTANCE $FLAGS -- sudo sed -i "s:--network-plugin=kubenet:--network-plugin=cni\ --cni-bin-dir=/home/kubernetes/bin:g" /etc/default/kubelet
gcloud compute ssh $INSTANCE $FLAGS -- sudo systemctl restart kubelet
gcloud compute ssh $INSTANCE $FLAGS -- sudo mkdir -p /etc/cni/net.d/
gcloud compute scp 04-cilium-cni.conf root@${INSTANCE}:/etc/cni/net.d/04-cilium-cni.conf $FLAGS
```

## Details

* Cilium runs in the `cilium` namespace instead of the `kube-system` namespace.
* cilium-etcd-operator maintains an etcd cluster for use by Cilium that allows
  to scale down to 0 and scale back up.
