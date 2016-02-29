# Kubernetes (k8s) Hands-on/demonstration

## Requirements

Please make sure that you have docker installed, and docker-machine installed if using a mac or windows. Docker-machine can also be installed on linux, and for the sake of this hands-on, we will assume that you have it installed.

## Part 1: Lifting up your own instance

We are going to lift a k8s cluster locally for the sake of interacting with it in simple scenarios. This is clearly not a production set up, but an instance to learn the basics on the interactions with a Kubernetes cluster. We are going to use a docker compose approach.

If you are in a mac or windows, make sure that you are in a terminal that has proper. With docker-machine installed, this can be done by opening `Docker Quickstart Terminal`. This should start you `docker-machine` VM if it is not already running.

On that terminal, clone or download this repo:
```
git clone https://github.com/pcm32/k8s_demo.git
cd k8s_demo
```
Now, check that docker is running and accessible (in the docker-machine terminal, sudo is not necessary):
```
docker ps
```
If the output looks like this:
```
Get http:///var/run/docker.sock/v1.20/containers/json: dial unix /var/run/docker.sock: no such file or directory.
* Are you trying to connect to a TLS-enabled daemon without TLS?
* Is your docker daemon up and running?
```
then it probably means that your are not in the correct terminal or there is something wrong with your docker/docker-machine installation. If you get a table (which might be empty) like this:
```
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
```
then it is fine.

Now, lets lift the k8s cluster... execute
```
docker-compose -f k8s.yaml up -d
```
You should see:
```
Starting localk8s_master_1...
Starting localk8s_proxy_1...
Starting localk8s_etcd_1...
```
which means that you have a k8s cluster running. This is a bit of an odd setup, as the master and node are running within the same machine as containers. If you are interested, there are many other ways of provisioning a k8s cluster [here](http://kubernetes.io/v1.1/docs/getting-started-guides/), both locally or on production infrastructure. There are also a number of independent tutorials on different flavours, such as [bloombergs](https://github.com/bloomberg/kubernetes-cluster-cookbook/blob/master/templates/default/flannel-flanneld.erb), [pangaea](https://github.com/hasura/pangaea), on [CoreOS](https://coreos.com/kubernetes/docs/latest/getting-started.html), or the one I'm [using](https://github.com/phnmnl/mantl-kubernetes) for openstack, among many others. 
On the google cloud platform, k8s is a "turn-key" technology, so if you run `gcloud container clusters create <cluster_name>` you get a k8s cluster, that easy. There is also a way through the REST service and dashboard.

First we will take a brief look at the components of the docker compose (slides).

## Communicating with the k8s cluster

Once you have lifted your cluster, you need to be able to talk to it. k8s provides both a REST based access or a command-line interface (which is nothing but a client to this REST API). We are running a setup in which we have a virtual machine in the middle:

![docker on mac](https://docs.docker.com/engine/installation/images/mac_docker_host.svg) 

This means that we need to first tunnel our way through the VM to access the cluster. We achieve this on a separate terminal with:
```
docker-machine ssh default -L 8080:localhost:8080
```
if you are running on linux directly, you probably don't need to do this. 

At this point you should be able to access the cluster through it's REST API:
```
curl localhost:8080/api
```
and you should get an output like:

```json
{
  "kind": "APIVersions",
  "versions": [
    "v1"
  ]
}
```
you could also try:
```
curl localhost:8080/api/v1/nodes
```

However, for simplicity, we will use the command line interface (cli). Please download for your platform:
- For Mac, execute:
```
wget -O /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v1.1.2/bin/darwin/amd64/kubectl
chmod a+x /usr/local/bin/kubectl
```
- For Linux, execute:
```
wget -O /usr/local/bin/kubectl http://storage.googleapis.com/kubernetes-release/release/v1.1.2/bin/linux/amd64/kubectl
chmod a+x /usr/local/bin/kubectl
```
- For Windows, download from [here](https://github.com/eirslett/kubectl-windows/raw/master/kubectl-1.1.3.exe), rename to kubectl and put it in your path.

Now, you should be able to call kubectl and start talking to your tiny k8s cluster:

```
kubectl cluster-info
```
and get an output. On a real setup, the process of hooking up your kubectl with your cluster is a bit more cumbersome, as it requires to set a `kubeconfig` file (normally on `~/.kube/config`) which contains necessary user names, passwords, server address and port, private key and certificates. The `kubectl` to cluster connection is supposed to be secure. This kubeconfig file is generated differently according to how you lift your k8s cluster. Please see [here](https://github.com/kubernetes/kubernetes/blob/release-1.1/docs/user-guide/kubeconfig-file.md) for documentation on generating a kubeconfig (not needed for this tutorial). (Show my config for the EMBASSY installation).

### Using kubectl

`kubectl` allows to both retrieve the status of different elements of the cluster and give instructions to the cluster. The complete documentation is [here](https://cloud.google.com/container-engine/docs/kubectl/). Some documentation is given by executing with no arguments.

To see the nodes/pods/jobs/services/rpc you do (although you won't have any now):
```
kubectl get nodes
kubectl get pods
kubectl get jobs
kubectl get svc
kubectl get rc
```
To view your current connection config:
```
kubectl config view
```
And to view versions:
```
kubectl version
```

#### What we are here for: sending jobs, pods, etc.

In k8s, Jobs are one-off executions (ie. batch jobs), which is probably our most important use case (PhenoMeNal Project). More documentation on k8s jobs can be found [here](https://cloud.google.com/container-engine/docs/jobs). To send a job, you normally first condify it into a yaml or json file. The first example we will try looks like this:

```yaml
apiVersion: extensions/v1beta1
kind: Job
metadata:
  name: pi
spec:
  selector:
    matchLabels:
      app: pi
  template:
    metadata:
      name: pi
      labels:
        app: pi
    spec:
      containers:
      - name: pi
        image: perl
        command: ["perl",  "-Mbignum=bpi", "-wle", "print bpi(2000)"]
      restartPolicy: Never
```
If you have checked out this repo, it should be on the base directoy, under the name `example_jobs.yml`. What this job will do essentially is to run a docker image containing a `Perl` installation, and a command in will be executed in perl to compute the number \pi with 2000 decimals. Supposing you have the file mentioned in place, execute the following to send the job to the cluster:
```
kubectl create -f example_job.yaml
```
And it should state that the job 'pi' was created. Kubernetes will automagically pull from Docker hub the docker image required, in this case, the perl [image](https://hub.docker.com/_/perl/). Normally an underscore before the image name means that that is the offical image provided for that something.

Now we can see what happened to our job (last two are the same if the file is there):
```
kubectl get jobs
kubectl describe jobs/pi
kubectl describe -f example_job.yaml
```
When a job is sent, its actual execution is done through a pod. The last command shows us the pods that were created to execute this job (see table at the bottom, where it says "Message", it should say "Created pod: "). Using that pod name, or finding the name through `kubectl get pods`, you can then execute this to obtain more information about the run:

```
kubectl describe pods/pi-...
```
The output might be indicative of an error in this case, but the important message is in the end in the 'Status' part.

Now, because this job is outputing to the STDOUT, we can easily see the output with:
```
kubectl logs pi-...
```
Where `pi-...` is the name of the pod. You should see \pi with plenty of decimals. There was no need to install perl nor other dependencies to do this.

















