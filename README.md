# Docker Swarm Lab - NestJS API with PostgreSQL

This project demonstrates the deployment of a NestJS API with its PostgreSQL database on a Docker Swarm cluster, using Docker-in-Docker on a local host machine.

## Objective

The main goal of this project is to show how to:

- Set up a local Docker Swarm cluster
- Use Docker-in-Docker (DinD) to simulate a multi-node environment
- Deploy a modern NestJS application with data persistence
- Configure networks, volumes, and secrets in a Swarm environment
- Manage high availability and application resilience

## Architecture

The project consists of:

- A backend API developed with NestJS
- A PostgreSQL database for data persistence
- A local Docker Swarm cluster using Docker-in-Docker

## Prerequisites

- Docker installed on your host machine
- Docker Compose
- Git

## How to Use

1. Clone the repository
2. Run the Swarm cluster initialization script
3. Deploy the stack with the API and database
4. Test the API via the exposed endpoints



## 1. Create the Swarm
```sh
cd docker-swarm-lab
./create-swarm.sh
```

## 2. Build the NestJS Image
```sh
cd nest-js-api
docker build -t nestjs-api .
```

## 3. Tag the Image
```sh
docker tag nestjs-api:latest localhost:5001/nestjs-api:latest
```

## 4. Push the Image to the Registry
```sh
docker push localhost:5001/nestjs-api:latest
```



### Verify the Image in the Registry
```sh
curl -X GET http://localhost:5001/v2/_catalog
# {"repositories":["nestjs-api"]}

curl -X GET http://localhost:5001/v2/nestjs-api/tags/list
# {"name":"nestjs-api","tags":["latest"]}

curl -v -H "Accept: application/vnd.docker.distribution.manifest.v2+json" -X GET http://localhost:5001/v2/nestjs-api/manifests/latest
```
## 5. Deploy the Image on the Swarm
### Delete the Image Manifest
```sh
curl -X DELETE http://localhost:5001/v2/nestjs-api/manifests/sha256:0bc03a4343159b4d783bf475609838b83afd8034acd2e26fa69a175eaac51a9e
```

### Deploy the Stack from Outside the Manager
```sh
docker exec -i manager sh -c 'cat > /docker-stack.yml && docker stack deploy -c /docker-stack.yml nestjs-app' < docker-stack.yml
```

### Check the Stack Status
```sh
docker stack ps nestjs-app
```

### Check the Services
```sh
docker service ls
```

### View API Service Logs
```sh
docker service logs nestjs-app_api
```

### Check Node Status
```sh
docker node ls
```

### Check API on host machine
```sh
curl -X GET http://localhost:3000
#Hello World!
```

### Update the Number of Replicas
```sh
docker exec -it manager docker service scale nestjs-app_api=7
```

### Shutdown a stack by setting 0 replica
```sh
docker exec -it manager docker service scale nestjs-app_api=0
```

### Remove the Entire Stack
```sh
docker exec -it manager docker stack rm nestjs-app
```

### Remove Individual Services
```sh
docker exec -it manager docker service rm nestjs-app_api
docker exec -it manager docker service rm nestjs-app_postgres
```

### Verify Services Removal
```sh
docker exec -it manager docker stack ls
docker exec -it manager docker service ls
```

### Clean Up Persistent Volumes
```sh
docker exec -it manager docker volume ls
docker exec -it manager docker volume rm nestjs-app_postgres_data
```