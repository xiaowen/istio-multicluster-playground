# Istio Multicluster Playground

This repo shows an example of how to put two Kubernetes clusters into a single Istio mesh and load balance between them.  There are steps for creating shared certificates, installing Istio with a multicluster topology, and installing a sample app.

Everything was tested with Istio 1.8 on a Kops cluster running Kubernetes 1.18.14 and a GKE cluster running Kubernetes 1.17.13.

## Preparing

Before installing Istio on multiple clusters, you should create the clusters first.  The steps here assume there are two clusters, where the kubectl context names are `kops` and `gke1`.  If your clusters are named differently, you can do a find and replace on all the files here.

## Creating shared certificates

This section is based on the initial steps documented on the Istio website [here](https://istio.io/latest/docs/setup/install/multicluster/multi-primary_multi-network/).

Switch to the `certs` directory, and run the following to generate shared certificates for Istio:
```
make generate
```

Staying in the `certs` directory, run the following to create a namespace for Istio and install these certificates into that namespace.  The command will do this for both Kubernetes clusters.
```
make install
```

## Install Istio

This section is a continuation of the [steps](https://istio.io/latest/docs/setup/install/multicluster/multi-primary_multi-network/) documented on the Istio website referenced in the previous section.

After the shared certificates have been installed on the two clusters, the next step is to install Istio itself.  Switch back to the root directory of this repo and run the following.
```
make install
```

This step will create the ingress gateways for Istio, as well as exchange secrets to establish trust between the clusters.  Run the following to see their status.
```
$ make status
kubectl --context="kops" get svc -n istio-system; echo
NAME                    TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)                                                                      AGE
istio-eastwestgateway   LoadBalancer   100.69.245.28    34.82.200.221   15021:31859/TCP,15443:30208/TCP,15012:32130/TCP,15017:30293/TCP              35m
istio-ingressgateway    LoadBalancer   100.71.80.86     34.82.246.2     15021:31747/TCP,80:32009/TCP,443:31423/TCP,15012:30198/TCP,15443:32415/TCP   35m
istiod                  ClusterIP      100.66.155.255   <none>          15010/TCP,15012/TCP,443/TCP,15014/TCP                                        35m

kubectl --context="gke1" get svc -n istio-system; echo
NAME                    TYPE           CLUSTER-IP   EXTERNAL-IP     PORT(S)                                                                      AGE
istio-eastwestgateway   LoadBalancer   10.0.6.156   34.67.233.225   15021:31107/TCP,15443:30428/TCP,15012:31333/TCP,15017:32237/TCP              35m
istio-ingressgateway    LoadBalancer   10.0.6.99    35.224.211.92   15021:31280/TCP,80:30237/TCP,443:30163/TCP,15012:31562/TCP,15443:31026/TCP   35m
istiod                  ClusterIP      10.0.12.95   <none>          15010/TCP,15012/TCP,443/TCP,15014/TCP                                        35m
```

For each cluster, there is an ingress gateway created for north-south traffic (called `istio-ingressgateway`), which is traffic from outside the mesh, and there's another ingress gateway for east-west traffic (called `istio-eastwestgateway`), which is for traffic between pods within the mesh.  If the clusters are running on a public cloud, then The `EXTERNAL-IP` column will initially be in `pending` state, and after a minute or two, will contain an externally addressable IP or hostname.

## Configure hostnames

If you would like to be able to easily access workloads in these clusters, you can update your DNS entries at this point.  For this example, I have `istio1.xiaowenx.com` pointed at the `istio-ingressgateway` of the `kops` cluster and `istio2.xiaowenx.com` pointed at the `gke1` cluster.

If you don't want to set up DNS, that's OK, as there are workarounds to resolving hostnames in other ways.

Configure Istio to recognize these hostnames by running the following:
```
make ingress-install
```

## Run some sample code

Now that Istio has been installed, we can install some sample code to test multicluster functionality.

Switch to the samples directory and create a docker image of a sample app that echos out some debug info.  You should modify the Makefile to push the image to a container repo you have access to.  If you don't have such a repo set up, then you can use the `HelloWorld` app from Istio's [docs](https://istio.io/latest/docs/setup/install/multicluster/verify/), though the functionality will be slightly different.
```
cd samples
make docker
```

Once you have a sample app ready, make sure to modify the deployment files accordingly.

To fully test the functionality, the steps here will create a namespace `istio-disabled`, where apps will not use Istio by default, and another namespace `istio-enabled`, where Istio will automatically inject a sidecar proxy.  An instance of the `echo` app called `echo1` will be deployed into the `istio-disabled` namespace and another instance `echo2` will be deployed to the `istio-enabled` namespace.  There will also be a `sleep` app installed that is used to test the functionality of the `echo` apps.
```
make echo-install
```

Once the apps are installed, run the following to test it.
```
make echo-status
from kops:istio-disabled: curl echo1:8080
[URL: http://echo1:8080/hello] on [pod: echo1-5cf848bd89-lql9p] in [cluster: kops]
[URL: http://echo1:8080/hello] on [pod: echo1-5cf848bd89-lql9p] in [cluster: kops]
[URL: http://echo1:8080/hello] on [pod: echo1-5cf848bd89-lql9p] in [cluster: kops]
[URL: http://echo1:8080/hello] on [pod: echo1-5cf848bd89-lql9p] in [cluster: kops]

from kops:istio-enabled: curl echo2:8080
[URL: http://echo2:8080/hello] on [pod: echo2-64ddccc94f-xdfqr] in [cluster: gke1]
[URL: http://echo2:8080/hello] on [pod: echo2-7f57546756-5tz7f] in [cluster: kops]
[URL: http://echo2:8080/hello] on [pod: echo2-64ddccc94f-xdfqr] in [cluster: gke1]
[URL: http://echo2:8080/hello] on [pod: echo2-7f57546756-5tz7f] in [cluster: kops]

curl istio1.xiaowenx.com/echo1
[URL: http://istio1.xiaowenx.com/echo1] on [pod: echo1-5cf848bd89-lql9p] in [cluster: kops]
[URL: http://istio1.xiaowenx.com/echo1] on [pod: echo1-5cf848bd89-lql9p] in [cluster: kops]
[URL: http://istio1.xiaowenx.com/echo1] on [pod: echo1-5cf848bd89-lql9p] in [cluster: kops]
[URL: http://istio1.xiaowenx.com/echo1] on [pod: echo1-5cf848bd89-lql9p] in [cluster: kops]

curl istio1.xiaowenx.com/echo2
[URL: http://istio1.xiaowenx.com/echo2] on [pod: echo2-64ddccc94f-xdfqr] in [cluster: gke1]
[URL: http://istio1.xiaowenx.com/echo2] on [pod: echo2-64ddccc94f-xdfqr] in [cluster: gke1]
[URL: http://istio1.xiaowenx.com/echo2] on [pod: echo2-7f57546756-5tz7f] in [cluster: kops]
[URL: http://istio1.xiaowenx.com/echo2] on [pod: echo2-64ddccc94f-xdfqr] in [cluster: gke1]

from gke1:istio-disabled: curl echo1:8080
[URL: http://echo1:8080/hello] on [pod: echo1-659848495b-g58k5] in [cluster: gke1]
[URL: http://echo1:8080/hello] on [pod: echo1-659848495b-g58k5] in [cluster: gke1]
[URL: http://echo1:8080/hello] on [pod: echo1-659848495b-g58k5] in [cluster: gke1]
[URL: http://echo1:8080/hello] on [pod: echo1-659848495b-g58k5] in [cluster: gke1]

from gke1:istio-enabled: curl echo2:8080
[URL: http://echo2:8080/hello] on [pod: echo2-64ddccc94f-xdfqr] in [cluster: gke1]
[URL: http://echo2:8080/hello] on [pod: echo2-7f57546756-5tz7f] in [cluster: kops]
[URL: http://echo2:8080/hello] on [pod: echo2-64ddccc94f-xdfqr] in [cluster: gke1]
[URL: http://echo2:8080/hello] on [pod: echo2-7f57546756-5tz7f] in [cluster: kops]

curl istio2.xiaowenx.com/echo1
[URL: http://istio2.xiaowenx.com/echo1] on [pod: echo1-659848495b-g58k5] in [cluster: gke1]
[URL: http://istio2.xiaowenx.com/echo1] on [pod: echo1-659848495b-g58k5] in [cluster: gke1]
[URL: http://istio2.xiaowenx.com/echo1] on [pod: echo1-659848495b-g58k5] in [cluster: gke1]
[URL: http://istio2.xiaowenx.com/echo1] on [pod: echo1-659848495b-g58k5] in [cluster: gke1]

curl istio2.xiaowenx.com/echo2
[URL: http://istio2.xiaowenx.com/echo2] on [pod: echo2-7f57546756-5tz7f] in [cluster: kops]
[URL: http://istio2.xiaowenx.com/echo2] on [pod: echo2-64ddccc94f-xdfqr] in [cluster: gke1]
[URL: http://istio2.xiaowenx.com/echo2] on [pod: echo2-7f57546756-5tz7f] in [cluster: kops]
[URL: http://istio2.xiaowenx.com/echo2] on [pod: echo2-64ddccc94f-xdfqr] in [cluster: gke1]

```

Some of the tests will use the DNS name that we configured earlier to access the services.  If you did not configure DNS, you can still do the test by manually configuring hostname resolution for `curl` via a command line option.  For example, in the following command, `curl` will resolve `istio1.xiaowenx.com` to `80:34.82.246.2`.
```
curl istio1.xiaowenx.com/echo1 --resolve '*:80:34.82.246.2'
```

Look through the output of the command to see Istio in action.  In the first section, we're invoking the `echo1` service in the `kops` cluster, and all of the requests are indeed serviced by the `echo1` pod in the `kops` cluster.  In the second section, we're invoking the `echo2` service in the `kops` cluster, and we see that some of the requests were serviced by the `echo2` pod in the `gke1` cluster instead.  This is because `echo2` and the client (the `sleep` app) were installed into a namespace that automatically injected an Istio sidecar proxy and Istio load-balanced the requests between the two clusters.  The next two sections show calling `echo1` and `echo2` via the DNS name from outside the mesh and the results are the same.  The next four sections show the same requests to the `gke1` cluster.

As we can see from this experiment, when you use Istio's sidecar proxy, it can do automatic load-balancing between clusters, which is very useful for east-west traffic.  For north-south traffic, you will probably want to add in a dedicated global load balancer to send customer traffic to the closest or most appropriate Kubernetes cluster.

## Uninstall
To uninstall, switch to the `samples` directory to uninstall the sample code:
```
cd samples
make echo-uninstall
```

Then, switch back to the root directory and uninstall Istio:
```
make ingress-uninstall
make uninstall
```

To delete the shared certificates and the `istio-system` namespace, switch to the `certs` directory and run the `make` target.
```
cd certs
make uninstall
```
