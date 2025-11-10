#!/bin/bash
set -e

sudo yum update -y
sudo yum install -y nodejs npm make docker git
sudo npm install -g yarn

echo "Buildando..."
make build

echo "Construindo o Docker local..."
make docker-build

echo "Criando CloudFormation..."
make create-stack

echo "Aguarde..."
IP=$(make get-ip)

echo "Deu boa! Acesse o site em: http://$IP:8000"