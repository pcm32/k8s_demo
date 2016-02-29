# Galaxy and k8s on the EBI-EMBASSY Cloud

This part of the demo builds on work kindly shared by [Stephanie](https://github.com/stephanieherman), [Payam](https://github.com/PayamEmami), Anders, [Marco](https://github.com/mcapuccini) and Ola, our partners at Uppsala. We use their workflow and image container definitions available [here](https://github.com/phnmnl/workflow-demo) (you don't need to follow that link to continue).

Since we are using a different k8s cluster now, we need to swap the `~/.kube/config` file to get the adequate authentication to use the EMBASSY Cloud installation (which is provisioned through [this](https://github.com/phnmnl/mantl-kubernetes) MANTL kubernetes setup).

```
mv ~/.kube/config ~/.kube/config_gcloud
ln -s ~/.kube/config_embassy ~/.kube/config
```

## From a dockerfile to a deployable job 

Here we will describe how to go from a dockerfile codified tool to something that we run on Galaxy (the W4M) installation and that is offloaded (the heavy computation) to the Kubernetes cluster.

### Dockerfile is built and pushed to an accesible hub for the k8s cluster

At the EMBASSY Cloud we have our own instance of Jenkins which has hooks to the dockerfile github repos that we are interested. You can access our live instance [here](http://phenomenal-h2020.eu/jenkins/)

![Figure 2: EMBASSY Jenkins instance]()

So, for instance, the first step of the Uppsala's demo workflow, the BlankFilter, whose dockerfile is [here](https://github.com/phnmnl/workflow-demo/blob/master/BlankFilter/Dockerfile) and looks like this:

```dockerfile
FROM r-base
MAINTAINER Stephanie Herman, stephanie.herman.3820@student.uu.se

ADD BlankFilter.r /
ENTRYPOINT ["Rscript", "BlankFilter.r"] 
```

and this is built (as in `docker build -t phnmnl/ex-blankfilter .`) by our EMBASSY Cloud Jenkins, and subsequently pushed to our internal docker registry.

So, to execute that first step of the Uppsala example workflow, we would first need to somehow upload the data to our shared filesystem, and then execute:

```bash
kubectl create -f run_blankfilter_step.yaml
```

where the run_blankfilter_step.yaml looks like this:

```yaml

```
