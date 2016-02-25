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
which means that you have a k8s cluster running. This is a bit of an odd setup, as the master and node are running within the same machine as containers. If you are interested, there are many other ways of provisioning a k8s cluster [here](http://kubernetes.io/v1.1/docs/getting-started-guides/), both locally or on production infrastructure. On the google cloud platform, k8s is a "turn-key" technology, so if you run `gcloud container clusters create <cluster_name>` you get a k8s cluster, that easy.

First we will take a brief look at the components of the docker compose (slides).

## Communicating with the k8s cluster

Once you have lifted your cluster, you need to be able to talk to it. k8s provides both a REST based access or a command-line interface (which is nothing but a client to this REST API). Becuase we are running a setup in which we have a virtual machine in the middle
![docker on mac](https://docs.docker.com/engine/installation/images/mac_docker_host.svg) we need to first tunnel our way through the VM to access the cluster. We achieve this on a separate terminal with:
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

however, for simplicity, we will use the command line interface (cli). Please download for your platform:
- For Mac:
- For Linux:
- For Windows:








