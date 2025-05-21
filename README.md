# Instalacion de PostgreSQL con Helm
```bash
helm install postgres bitnami/postgresql --set auth.username=redes --set auth.password=kubernetes --set auth.database=chatdb
```