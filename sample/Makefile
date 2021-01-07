CTX_CLUSTER1 = kops
CTX_CLUSTER2 = gke1

CLUSTER = kops
HOST = api
DOMAIN = xiaowenx.com

# curl -LO https://raw.githubusercontent.com/istio/istio/release-1.8/samples/sleep/sleep.yaml

docker:
	docker build -t echo-info .
	docker tag echo-info gcr.io/xiaowen/echo-info
	docker push gcr.io/xiaowen/echo-info

echo-install-cluster: # set CLUSTER
	-kubectl --context=${CLUSTER} create namespace istio-disabled
	-kubectl --context=${CLUSTER} create namespace istio-enabled
	-kubectl --context=${CLUSTER} label namespace istio-enabled istio-injection=enabled
	kubectl --context=${CLUSTER} apply -n istio-disabled -f echo1-${CLUSTER}.yaml,echo1.yaml,sleep.yaml
	kubectl --context=${CLUSTER} apply -n istio-enabled -f echo2-${CLUSTER}.yaml,echo2.yaml,sleep.yaml

echo-install:
	make echo-install-cluster CLUSTER=kops
	make echo-install-cluster CLUSTER=gke1

echo-uninstall-cluster: # set CLUSTER
	kubectl --context=${CLUSTER} delete --ignore-not-found=true -n istio-disabled -f echo1-${CLUSTER}.yaml,echo1.yaml,sleep.yaml
	kubectl --context=${CLUSTER} delete --ignore-not-found=true -n istio-enabled -f echo2-${CLUSTER}.yaml,echo2.yaml,sleep.yaml
	kubectl --context=${CLUSTER} delete --ignore-not-found=true namespace istio-disabled
	kubectl --context=${CLUSTER} delete --ignore-not-found=true namespace istio-enabled

echo-uninstall:
	make echo-uninstall-cluster CLUSTER=kops
	make echo-uninstall-cluster CLUSTER=gke1

echo-status-cluster: # set CLUSTER and HOST
	@echo from ${CLUSTER}:istio-disabled: curl echo1:8080
	@for i in 1 2 3 4; do kubectl exec --context=${CLUSTER} -n istio-disabled -c sleep \
	    $$(kubectl get pod --context=${CLUSTER} -n istio-disabled -l app=sleep -o jsonpath='{.items[0].metadata.name}') \
	    -- curl -s echo1:8080/hello; done;
	@echo
	@echo from ${CLUSTER}:istio-enabled: curl echo2:8080
	@for i in 1 2 3 4; do kubectl exec --context=${CLUSTER} -n istio-enabled -c sleep \
	    $$(kubectl get pod --context=${CLUSTER} -n istio-enabled -l app=sleep -o jsonpath='{.items[0].metadata.name}') \
	    -- curl -s echo2:8080/hello; done;
	@echo
	@echo curl ${HOST}.${DOMAIN}/echo1
	@for i in 1 2 3 4; do curl -s ${HOST}.${DOMAIN}/echo1; done
	@echo
	@echo curl ${HOST}.${DOMAIN}/echo2
	@for i in 1 2 3 4; do curl -s ${HOST}.${DOMAIN}/echo2; done
	@echo

echo-status:
	@make echo-status-cluster CLUSTER=kops HOST=api1
	@make echo-status-cluster CLUSTER=gke1 HOST=api2
