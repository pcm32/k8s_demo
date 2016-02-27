# Lifting a Kubernetes cluster on Google Cloud Environment (GCE)

Kubernetes is a turn-key technology at Google Cloud Environment. As such, it shoudl be relatively straightforward to launch a k8s cluster there.

Supposing that we have installed the gcloud cli:
```bash
gcloud auth login
gcloud config set project phenomenal-1145
gcloud container clusters create k8s-test-1 --zone europe-west1-b
```

`gcloud` will automagically config our ~/.kube/config authentication file, and hence when running:
```
kubectl cluster-info
Kubernetes master is running at https://104.155.28.76
GLBCDefaultBackend is running at https://104.155.28.76/api/v1/proxy/namespaces/kube-system/services/default-http-backend
Heapster is running at https://104.155.28.76/api/v1/proxy/namespaces/kube-system/services/heapster
KubeDNS is running at https://104.155.28.76/api/v1/proxy/namespaces/kube-system/services/kube-dns
KubeUI is running at https://104.155.28.76/api/v1/proxy/namespaces/kube-system/services/kube-ui
```

We can visit at this point the dashboard, but we will need user and password available on the authentication file.

If we want to do some computations, we might need to have a shared filesystem, for which we will use GlusterFS. The beauty of Kubernetes is that even that can be run as a container. In this repo you will find a .yaml file for lifting up a GlusterFS storage layer (provided by the same minions).

```
kubectl create -f glusterfs_on_gce_k8s.yaml
```

We can now try for instance one of our images...

```
kubectl create -f test_ipo.yaml
```

Look at this yaml file to see how the glusterfs is mounted...

```
kubectl get jobs
kubectl describe -f test_ipo.yaml
kubectl describe pods/<pod-id>
```

Now we could load maybe a Galaxy instance, mounting the gluster fs where galaxy expect to create its files, and exposing galaxy to be visible from the outside.


