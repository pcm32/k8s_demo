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

If we want to do some computations, we might need to have a shared filesystem, for which we will use GlusterFS. We will provision our k8s cluster on GCE with ansible.

To use ansible over ssh, we need to get the k8s hosts added to our `~/.ssh/config`:

```
gcloud compute config-ssh
```

Now we need to cheat a bit (TODO: fix this). In your `~/.ssh/config`, we need to alter a bit the hostnames of the GCE instances becuase of the way that our ansible script is written (I need to fix this!). Each instance of:

```
Host gke-k8s-test-2-1e52c4fa-node-uugf.europe-west1-b.phenomenal-1145
    HostName 104.155.9.116
    IdentityFile /Users/pmoreno/.ssh/google_compute_engine
    UserKnownHostsFile=/dev/null
    IdentitiesOnly=yes
    CheckHostIP=no
    StrictHostKeyChecking=no
```

Needs to look like this:
```
Host gke-k8s-test-2-1e52c4fa-node-uugf
    HostName 104.155.9.116
    IdentityFile /Users/pmoreno/.ssh/google_compute_engine
    UserKnownHostsFile=/dev/null
    IdentitiesOnly=yes
    CheckHostIP=no
    StrictHostKeyChecking=no
```

So it is simply to remove the domain from the hostnames, for each k8s instance. Then, moving back to the demo directory, we will provision the gluster-fs cluster using the same nodes that we have and their hard drives.

```
cd ansible
bash makeInventoryForK8sCluster.sh
ansible-playbook -i inventory setup.yml
cd ..
```

Besides software installation and configuring, this entails the creation of an endpoint, which is used by any pod to mount the disk:

```
kubectl get ep
```

So now, we will send a job that would normally require shared file system to read files from and write outputs to. This is actually a PhenoMeNal containerized application called Mass IPO, which allows to choose optimized parameters for XCMS peak picking and retention time alignment based on the data to analyze (a sample of it). For this exercise, and to avoid using GCE resources that we would normally need to pay for, we wont execute this with data.

```
kubectl create -f test_ipo.yaml
```

If you inspect this yaml file, it shows how to access the mounted file system:

```yaml
spec:
      containers:
      - name: ipo-run
        image: phenomenal/ipo:latest
        volumeMounts:
          - name: glusterfsvol
            mountPath: /mnt/glusterfs
      restartPolicy: Never
      volumes:
         - name: glusterfsvol
           glusterfs:
               endpoints: glusterfs-cluster
               path: scratch
               readOnly: false
```

Please note that for this to work, the docker image needs to be at an accesible docker registry (in this case [here](https://hub.docker.com/r/phenomenal/ipo/)).

Take a look at the description that k8s has for the job and pod submitted (remember how to do it?), what can you see? Does it mention anything about the mount point?How can we get the STDOUT of the job we just run?











Answers:
```
kubectl describe -f test_ipo.yaml
# find the id of the pod created
kubectl describe pod/<pod-id>
```
Or you could use labels based selectors.
On the description you should see the volumes mounted and in the events you should see that they were mounted or otherwise an error.








Only to show that glusterfs deployed works, you can upload a file to the glusterfs share (located on /mnt/scratch on the nodes)
```
NODE=`cat ansible/inventory | sed -n 2p`
scp about_kubernetes.txt $NODE:~/
ssh $NODE 'sudo cp about_kubernetes.txt /mnt/scratch/'
kubectl create -f replace_glusterfs_example.yaml
```

The defined replacement job spec that looks like this:
```yaml
    spec:
      containers:
      - name: perl-replace
        image: perl
        command: ["perl", "-i.bak", "-p", "-e", "s/[Kk]ubernetes/k8s/g","/mnt/glusterfs/about_kubernetes.txt"]
        volumeMounts: 
          - name: glusterfsvol
            mountPath: /mnt/glusterfs
      volumes: 
         - name: glusterfsvol
           glusterfs: 
               endpoints: glusterfs-cluster
               path: scratch
               readOnly: false
      restartPolicy: Never
```

Take a look at the local `about_kubernetes.txt`, so that you can notice the difference after the job is done. This will essentially replace all the \[Kk\]ubernetes to its abbreviated form 'k8s'.

And once the job is completed:
```
ssh $NODE 'sudo less /mnt/scratch/about_kubernetes.txt'
ssh $NODE 'sudo ls -l /mnt/scratch/'
```

This should show you that the file changed, and that a backup was produced.

And we can delete the cluster:
```
gcloud container clusters delete k8s-test-1 --zone europe-west1-b
```
