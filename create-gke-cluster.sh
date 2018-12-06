#!/bin/bash -e

if [ -z "$ADMIN_USER" ]; then
	echo "ADMIN_USER is not set"
	exit 1
fi

CLUSTER_NAME="${CLUSTER_NAME:-default-cluster}"
GKE_PROJECT="${GKE_PROJECT:-default-project}"
GKE_REGION="${GKE_REGION:-europe-north1}"
GKE_ZONE="${GKE_ZONE:--a}"
IMAGE_TYPE="${IMAGE_TYPE:-COS}"

default_version=$(gcloud container get-server-config --project $GKE_PROJECT --zone europe-north1-a | grep 1.11 | head -n 1 | awk '{print $2}')
GKE_VERSION=${GKE_VERSION:-$default_version}

gcloud beta container --project $GKE_PROJECT clusters create $CLUSTER_NAME --zone $GKE_REGION$GKE_ZONE --username "admin" --cluster-version $GKE_VERSION --machine-type "n1-standard-1" --image-type $IMAGE_TYPE --disk-type "pd-standard" --disk-size "100" --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" --num-nodes "3" --no-enable-cloud-logging --no-enable-cloud-monitoring --network "projects/$GKE_PROJECT/global/networks/default" --subnetwork "projects/$GKE_PROJECT/regions/$GKE_REGION/subnetworks/default" --addons HorizontalPodAutoscaling,HttpLoadBalancing --no-enable-autoupgrade --no-enable-autorepair

gcloud container clusters get-credentials $CLUSTER_NAME --zone $GKE_REGION$GKE_ZONE --project $GKE_PROJECT

echo "Waiting for Kubernetes cluster to become ready..."
until kubectl get pods; do sleep 1; done

echo "Enabling CNI configuration..."
INSTANCES=$(gcloud compute instances --project $GKE_PROJECT list | grep $CLUSTER_NAME | awk '{print $1}')
for INSTANCE in $INSTANCES; do
	FLAGS="--zone $GKE_REGION$GKE_ZONE --project $GKE_PROJECT"
	gcloud compute ssh $INSTANCE $FLAGS -- sudo sed -i "s:--network-plugin=kubenet:--network-plugin=cni\ --cni-bin-dir=/home/kubernetes/bin:g" /etc/default/kubelet
	gcloud compute ssh $INSTANCE $FLAGS -- sudo systemctl restart kubelet
	gcloud compute scp 04-cilium-cni.conf ${INSTANCE}:/tmp/04-cilium-cni.conf $FLAGS
	gcloud compute ssh $INSTANCE $FLAGS -- sudo mkdir -p /etc/cni/net.d/
	gcloud compute ssh $INSTANCE $FLAGS -- sudo cp /tmp/04-cilium-cni.conf /etc/cni/net.d/04-cilium-cni.conf
done

echo "Installing Cilium..."
kubectl create ns cilium
kubectl create clusterrolebinding cluster-admin-binding --clusterrole cluster-admin --user $ADMIN_USER
kubectl create -f cilium-etcd-operator.yaml
kubectl create -f cilium-deployment.yaml

echo "Restarting kube-dns-autoscaler..."
kubectl -n kube-system delete pod -l k8s-app=kube-dns-autoscaler

echo "Restarting kube-dns..."
kubectl -n kube-system delete pod -l k8s-app=kube-dns

echo "Restarting l7-default-backend..."
kubectl -n kube-system delete pod -l k8s-app=glbc

echo "Restarting heapster..."
kubectl -n kube-system delete pod -l k8s-app=heapster

echo "Restarting metrics-server..."
kubectl -n kube-system delete pod -l k8s-app=metrics-server

echo "Waiting for cilium to become ready..."
until kubectl wait --for=condition=Ready --selector k8s-app=cilium -n cilium pod; do sleep 1; done
