#!/bin/bash
K3S_TOKEN="${token}"
curl -sfL https://web.archive.org/web/20250330135747/https://get.k3s.io/ | K3S_TOKEN="$K3S_TOKEN" INSTALL_K3S_EXEC="--kube-apiserver-arg default-not-ready-toleration-seconds=10 --kube-apiserver-arg default-unreachable-toleration-seconds=10 --kube-controller-arg node-monitor-period=10s --kube-controller-arg node-monitor-grace-period=10s --kubelet-arg node-status-update-frequency=5s" sh -

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
helm install postgres-db ./charts/postgres-chart
helm install message-service ./charts/message-service-chart 
helm install chat-frontend ./charts/chat-frontend-chart
helm install message-broker-redis ./charts/message-broker-redis-chart
helm install ingress ./charts/ingress-chart
# helm install logs ./charts/logs-chart --set logstash.host="${logstash_host}"