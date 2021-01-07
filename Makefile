# https://istio.io/latest/docs/setup/install/multicluster/multi-primary_multi-network/
CTX_CLUSTER1 = kops
CTX_CLUSTER2 = gke1

# curl -sLO https://raw.githubusercontent.com/istio/istio/release-1.8/samples/multicluster/gen-eastwest-gateway.sh
# chmod +x gen-eastwest-gateway.sh
# curl -sLO https://raw.githubusercontent.com/istio/istio/release-1.8/samples/multicluster/expose-services.yaml
# ./gen-eastwest-gateway.sh --mesh mesh1 --cluster cluster1 --network network1 > cluster1-gw.yaml
# ./gen-eastwest-gateway.sh --mesh mesh1 --cluster cluster2 --network network2 > cluster2-gw.yaml

install:
	-kubectl --context="${CTX_CLUSTER1}" label namespace istio-system topology.istio.io/network=network1
	istioctl --context="${CTX_CLUSTER1}" install -y -f cluster1.yaml
	istioctl --context="${CTX_CLUSTER1}" install -y -f cluster1-gw.yaml
	kubectl --context="${CTX_CLUSTER1}" apply -n istio-system -f expose-services.yaml

	-kubectl --context="${CTX_CLUSTER2}" label namespace istio-system topology.istio.io/network=network2
	istioctl --context="${CTX_CLUSTER2}" install -y -f cluster2.yaml
	istioctl --context="${CTX_CLUSTER2}" install -y -f cluster2-gw.yaml
	kubectl --context="${CTX_CLUSTER2}" apply -n istio-system -f expose-services.yaml

	istioctl x create-remote-secret --context="${CTX_CLUSTER1}" --name=cluster1 -n istio-system | kubectl apply -f - --context="${CTX_CLUSTER2}"
	istioctl x create-remote-secret --context="${CTX_CLUSTER2}" --name=cluster2 -n istio-system | kubectl apply -f - --context="${CTX_CLUSTER1}"

uninstall:
	istioctl x create-remote-secret --context="${CTX_CLUSTER1}" --name=cluster1 -n istio-system | kubectl delete --ignore-not-found=true -f - --context="${CTX_CLUSTER2}"
	istioctl x create-remote-secret --context="${CTX_CLUSTER2}" --name=cluster2 -n istio-system | kubectl delete --ignore-not-found=true -f - --context="${CTX_CLUSTER1}"

	-kubectl --context="${CTX_CLUSTER1}" delete --ignore-not-found=true -n istio-system -f expose-services.yaml
	istioctl --context="${CTX_CLUSTER1}" manifest generate -f cluster1-gw.yaml | kubectl delete --ignore-not-found=true -f - --context="${CTX_CLUSTER1}"
	-istioctl --context="${CTX_CLUSTER1}" manifest generate -f cluster1.yaml | kubectl delete --ignore-not-found=true -f - --context="${CTX_CLUSTER1}"
	kubectl --context="${CTX_CLUSTER1}" label namespace istio-system topology.istio.io/network-

	-kubectl --context="${CTX_CLUSTER2}" delete --ignore-not-found=true -n istio-system -f expose-services.yaml
	istioctl --context="${CTX_CLUSTER2}" manifest generate -f cluster2-gw.yaml | kubectl delete --ignore-not-found=true -f - --context="${CTX_CLUSTER2}"
	-istioctl --context="${CTX_CLUSTER2}" manifest generate -f cluster2.yaml | kubectl delete --ignore-not-found=true -f - --context="${CTX_CLUSTER2}"
	kubectl --context="${CTX_CLUSTER2}" label namespace istio-system topology.istio.io/network-

status:
	kubectl --context="${CTX_CLUSTER1}" get svc -n istio-system; echo
	kubectl --context="${CTX_CLUSTER2}" get svc -n istio-system; echo

ingress-install:
	kubectl --context kops apply -f api.xiaowenx.com.yaml,api1.xiaowenx.com.yaml,api2.xiaowenx.com.yaml
	kubectl --context gke1 apply -f api.xiaowenx.com.yaml,api1.xiaowenx.com.yaml,api2.xiaowenx.com.yaml

ingress-uninstall:
	kubectl --context kops delete --ignore-not-found=true -f api.xiaowenx.com.yaml,api1.xiaowenx.com.yaml,api2.xiaowenx.com.yaml
	kubectl --context gke1 delete --ignore-not-found=true -f api.xiaowenx.com.yaml,api1.xiaowenx.com.yaml,api2.xiaowenx.com.yaml
