#!/bin/bash
# Script to create a Docker Swarm cluster with 1 manager, 2 workers, and a registry on macOS ARM

echo "Cleaning up existing containers..."
docker rm -f manager worker1 worker2 registry 2>/dev/null || true
docker network rm swarm-network 2>/dev/null || true

echo "Creating the network..."
docker network create --driver bridge swarm-network

echo "Creating the registry on port 5001..."
docker run -d --restart always --name registry \
  --network swarm-network \
  -p 5001:5000 \
  registry:2

sleep 5

# Get the registry IP
REGISTRY_IP=$(docker container inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' registry)
echo "Registry IP: $REGISTRY_IP"

cat > daemon.json << EOF
{
  "insecure-registries": ["registry:5000"]
}
EOF

echo "Creating the manager..."
docker run -d --restart always --name manager \
  --network swarm-network \
  --privileged \
  -p 2377:2377 -p 7946:7946 -p 4789:4789/udp \
  -p 3000:3000 \
  -e "DOCKER_TLS_CERTDIR=" \
  -v $(pwd)/daemon.json:/etc/docker/daemon.json \
  docker:dind

echo "Waiting for the Docker daemon to start on the manager..."
until docker exec manager docker info &>/dev/null; do
  echo "Waiting for the Docker daemon on the manager..."
  sleep 3
done

echo "Initializing the Swarm on the manager..."
docker exec manager docker swarm init --advertise-addr $(docker container inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' manager)

# Get the worker token
TOKEN=$(docker exec manager docker swarm join-token worker -q)

echo "Creating worker1..."
docker run -d --restart always --name worker1 \
  --network swarm-network \
  --privileged \
  -e "DOCKER_TLS_CERTDIR=" \
  -v $(pwd)/daemon.json:/etc/docker/daemon.json \
  docker:dind

echo "Creating worker2..."
docker run -d --restart always --name worker2 \
  --network swarm-network \
  --privileged \
  -e "DOCKER_TLS_CERTDIR=" \
  -v $(pwd)/daemon.json:/etc/docker/daemon.json \
  docker:dind

echo "Waiting for the Docker daemons to start on the workers..."
until docker exec worker1 docker info &>/dev/null; do
  echo "Waiting for the Docker daemon on worker1..."
  sleep 3
done

until docker exec worker2 docker info &>/dev/null; do
  echo "Waiting for the Docker daemon on worker2..."
  sleep 3
done

# Get the manager IP address
MANAGER_IP=$(docker container inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' manager)

echo "Connecting the workers to the Swarm..."
docker exec worker1 docker swarm join --token $TOKEN ${MANAGER_IP}:2377
docker exec worker2 docker swarm join --token $TOKEN ${MANAGER_IP}:2377

echo "Checking the cluster nodes..."
docker exec manager docker node ls

echo "Docker Swarm cluster with registry created successfully!"
echo "Registry available on localhost:5001 (external) and $REGISTRY_IP:5000 (internal)"
echo "To push to the registry: docker tag myimage:latest localhost:5001/myimage:latest && docker push localhost:5001/myimage:latest"
echo "In docker-compose.yml, use: image: $REGISTRY_IP:5000/myimage:latest"
echo "To connect to the manager: docker exec -it manager sh"
echo "To connect to worker1: docker exec -it worker1 sh"
echo "To connect to worker2: docker exec -it worker2 sh"