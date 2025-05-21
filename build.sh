#!/bin/bash
# Warning: this is only for local development
eval $(minikube docker-env)
docker build -t chat-frontend:latest client
docker build -t message-service:latest server

helm upgrade message-service ./message-service-chart 
helm upgrade chat-frontend ./chat-frontend-chart