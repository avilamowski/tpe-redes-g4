#!/bin/bash
# Warning: this is only for local development

#minikube addons enable ingress

eval $(minikube docker-env)
docker build -t chat-frontend:latest client
docker build -t message-service:latest server

# helm repo add bitnami https://charts.bitnami.com/bitnami
helm install postgres bitnami/postgresql --set auth.username=redes --set auth.password=kubernetes --set auth.database=chatdb
helm install message-service ./charts/message-service-chart 
helm install chat-frontend ./charts/chat-frontend-chart
helm install ingress ./charts/ingress-chart
