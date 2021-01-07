# https://istio.io/latest/docs/tasks/security/cert-management/plugin-ca-cert/
generate:
	# curl -LO https://raw.githubusercontent.com/istio/istio/master/tools/certs/Makefile.selfsigned.mk
	# curl -LO https://raw.githubusercontent.com/istio/istio/master/tools/certs/common.mk
	make -f Makefile.selfsigned.mk root-ca
	make -f Makefile.selfsigned.mk kops-cacerts
	make -f Makefile.selfsigned.mk gke1-cacerts

install:
	kubectl --context kops create namespace istio-system
	kubectl --context kops create secret generic cacerts -n istio-system \
	      --from-file=kops/ca-cert.pem \
	      --from-file=kops/ca-key.pem \
	      --from-file=kops/root-cert.pem \
	      --from-file=kops/cert-chain.pem
	kubectl --context gke1 create namespace istio-system
	kubectl --context gke1 create secret generic cacerts -n istio-system \
	      --from-file=gke1/ca-cert.pem \
	      --from-file=gke1/ca-key.pem \
	      --from-file=gke1/root-cert.pem \
	      --from-file=gke1/cert-chain.pem

uninstall:
	kubectl --context kops delete secret cacerts -n istio-system
	kubectl --context gke1 delete secret cacerts -n istio-system
	kubectl --context kops delete namespace istio-system
	kubectl --context gke1 delete namespace istio-system
