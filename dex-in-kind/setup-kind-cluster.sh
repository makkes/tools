#!/usr/bin/env bash

set -euo pipefail

helm repo add mesosphere-stable https://mesosphere.github.io/charts/stable
helm repo add mesosphere-staging https://mesosphere.github.io/charts/staging

kind create cluster
docker cp kind-control-plane:/etc/kubernetes/pki/ca.key .
docker cp kind-control-plane:/etc/kubernetes/pki/ca.crt .

# install MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.5/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.5/manifests/metallb.yaml
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
kubectl -n metallb-system create -f- <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 172.18.255.1-172.18.255.250
EOF

# install Addons
helm install cert-manager-kubeaddons mesosphere-staging/cert-manager-setup --namespace=cert-manager --version 0.2.3 --values cert-manager-values.yaml --create-namespace --wait
kubectl create secret tls kubernetes-root-ca -n cert-manager --cert=ca.crt --key=ca.key
helm install traefik-kubeaddons --create-namespace --namespace=kubeaddons mesosphere-staging/traefik --values=traefik-values.yaml --version=1.88.0 --wait
helm install dex-kubeaddons --create-namespace --namespace=kubeaddons mesosphere-stable/dex --values=dex-values.yaml --version=2.9.0 --wait
