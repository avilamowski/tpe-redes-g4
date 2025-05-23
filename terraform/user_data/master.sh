#!/bin/bash
K3S_TOKEN="${token}"
curl -sfL https://get.k3s.io | K3S_TOKEN="$K3S_TOKEN" sh -

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
git clone https://github.com/avilamowski/tpe-redes-g4.git
cd tpe-redes-g4
export KUBECONFIG=~/.kube/config
mkdir ~/.kube 2> /dev/null
sudo k3s kubectl config view --raw > "$KUBECONFIG"
chmod 600 "$KUBECONFIG"
while [ $(kubectl get nodes | grep Ready | wc -l) -lt 2 ]; do
    sleep 5
done
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install postgres bitnami/postgresql --set auth.username=redes --set auth.password=kubernetes --set auth.database=chatdb
helm install message-service ./charts/message-service-chart 
helm install chat-frontend ./charts/chat-frontend-chart
helm install ingress ./charts/ingress-chart