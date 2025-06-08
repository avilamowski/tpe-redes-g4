#!/bin/bash
MASTER_IP="${master_ip}"
K3S_TOKEN="${token}"
curl -sfL https://get.k3s.io | K3S_URL="https://$MASTER_IP:6443" K3S_TOKEN="$K3S_TOKEN" INSTALL_K3S_EXEC="--kubelet-arg node-status-update-frequency=5s" sh -