# Desafio DevOps – Site de Joias na Amazon AWS

Este repositório contém a solução para o desafio de subir o site de uma joalheria (**NEW client**) utilizando **AWS**, **Docker** e **CloudFormation**, com toda a automação feita via **Makefile**.

A solução foi baseada e adaptada a partir do projeto do **OLD client**, atendendo aos requisitos:

- Infraestrutura na **AWS**
- Datacenter em **us-east-1**
- Tudo executado via **make**
- Uso da solução **mais barata possível** (EC2 t3.micro + Docker)
- Foco em **segurança** (Security Group restrito)
- Preparado para **pipeline em GitHub Actions** (se desejar automatizar)

---

## Arquitetura da Solução

### Visão Geral

A arquitetura é simples e focada em baixo custo:

- **1x EC2 t3.micro** em `us-east-1`
- **Security Group** permitindo:
  - Porta **22** (SSH), restrita via parâmetro `MyIpAddress`
  - Porta **8000** (aplicação web)
- **Docker** rodando uma imagem da aplicação de joias
- **CloudFormation** responsável por criar:
  - Security Group (`JulianaAppSecurityGroup`)
  - Instância EC2 (`JulianaAppInstance`)
- **User Data** da EC2:
  - Instala Docker + Git
  - Clona este repositório
  - Faz build da imagem
  - Sobe o container na porta `8000:80`

---

## Estrutura dos Arquivos

- `Dockerfile`  
  Faz build da aplicação (Node/Yarn) e empacota os arquivos estáticos em uma imagem **Nginx**.

- `docker-compose.yml`  
  Usado para desenvolvimento local da aplicação, expondo a aplicação em `http://localhost:8000`.

- `juliana-joias.yaml`  
  Template **AWS CloudFormation** que provisiona:
  - Security Group
  - Instância EC2 com User Data que faz todo o deploy via Docker.

- `Makefile`  
  Automação de:
  - Build da aplicação
  - Build da imagem Docker local
  - Criação do stack CloudFormation
  - Obtenção do IP público
  - Deploy e limpeza (delete stack)

- `teste.sh`  
  Script auxiliar que:
  - Instala dependências (node, npm, make, docker, yarn)
  - Executa `make build`, `make docker-build`, `make create-stack`
  - Mostra a URL final da aplicação.

---

## Pré-requisitos

Para rodar a solução você precisa de:

- Conta AWS com:
  - **Access Key** configurada no ambiente (AWS CLI)
  - Permissões para CloudFormation, EC2, VPC, Security Groups
- **AWS CLI** configurado (`aws configure`)
- **Make**
- **Docker** (para build/teste local)
- **Node.js** + **npm** + **yarn** (para build local)
- Um **KeyPair EC2** existente (nome usado em `KEY_NAME` no Makefile)
- Uma **VPC** e **Subnet** existentes em `us-east-1`

---

## Configurações Importantes

No arquivo `Makefile`:

```make
STACK_NAME    = desafio-proway-devops
TEMPLATE_FILE = juliana-joias.yaml
REGION        = us-east-1
KEY_NAME      = docker-ju
REPO_URL      = https://github.com/JulianaForbici/docker-aws
BRANCH        = main
SUBNET_ID     = subnet-06ad8ff9e17e7bef3
VPC_ID        = vpc-06786ee7f7a163059
MY_IP         = 0.0.0.0/0  

---

## Realize o Build do site:

make build
