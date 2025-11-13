# Desafio DevOps - Site de Joias na AWS

# Utilizando CloudFormation

Solução para subir um site na AWS usando Docker e CloudFormation com automação via Makefile.

Principais objetivos:
- Infraestrutura provisionada na AWS (CloudFormation)
- Região: us-east-1
- Simplicidade e custo reduzido (1x EC2 t3.micro + Docker)
- Automação via make
- Segurança (Security Group restrito por IP)
- Preparado para integrar em CI (GitHub Actions)

---

Visão geral

A solução provisiona uma única instância EC2 (t3.micro) que:
- Instala Docker e Git via user data
- Clona este repositório
- Faz build da imagem Docker (Nginx com arquivos estáticos)
- Roda o container expondo a aplicação em http://<IP_PUBLICO>:8000

---

Arquitetura

- 1x EC2 t3.micro (us-east-1)
- Security Group com regras:
  - SSH (22) restrito ao IP
  - App (8000) aberto ao público (padrão, pode ajustar)
- Docker executando a imagem construída a partir deste repositório
- CloudFormation gera Security Group e EC2
- User Data realiza todo o bootstrap (instalação e deploy)

---

Estrutura do repositório

- Dockerfile — empacota a aplicação (build Node/Yarn → arquivos estáticos → imagem Nginx)
- docker-compose.yml — para desenvolvimento local (expor em localhost:8000)
- juliana-joias.yaml — template CloudFormation (Security Group + EC2 + User Data)
- Makefile — automações (builds, criação/deleção do stack, obter IP, deploy completo)
- teste.sh — script auxiliar (instala dependências em Linux e executa build + deploy)
- src/ (ou pasta da aplicação) — código da aplicação (se aplicável)

---

Pré-requisitos

- Conta AWS com permissões: CloudFormation, EC2, VPC, Security Groups
- AWS CLI instalado e configurado (`aws configure`) apontando para us-east-1
- make instalado (Linux / WSL / macOS)
- Docker (para testes locais)
- Node.js + npm + yarn (para build local)
- KeyPair EC2 já criado (será usado como KEY_NAME)
- VPC e Subnet existentes em us-east-1 (IDs configuráveis no Makefile)

Observação: em Windows use WSL para maior compatibilidade com make, docker CLI e scripts shell.

---

Configurações importantes (Makefile)

Edite o Makefile para ajustar os valores abaixo antes de criar o stack:

```make
STACK_NAME    = docker-aws
TEMPLATE_FILE = juliana-joias.yaml
REGION        = us-east-1

KEY_NAME      = docker-ju             # Nome do KeyPair EC2
REPO_URL      = https://github.com/JulianaForbici/docker-aws
BRANCH        = main

SUBNET_ID     = subnet-06ad8ff9e17e7bef3
VPC_ID        = vpc-06786ee7f7a163059
MY_IP         = 0.0.0.0/0              # Troque por seu IP (/32) para SSH
```

Recomenda-se especialmente ajustar:
- KEY_NAME → nome do seu KeyPair
- SUBNET_ID / VPC_ID → IDs válidos em us-east-1
- MY_IP → seu IP público no formato x.x.x.x/32 (não deixe 0.0.0.0/0 para SSH)

---

Como usar

1) Execução local (desenvolvimento)

- Build da aplicação:
```bash
make build
```

- Rodar com docker-compose:
```bash
docker-compose up --build -d
# Acesse: http://localhost:8000
```

- Parar:
```bash
docker-compose down
```

2) Deploy na AWS

- Configure o AWS CLI:
```bash
aws configure
# Preencha AWS Access Key ID, Secret Access Key, region (us-east-1) e output (json)
```

- Confirme/edite as variáveis do Makefile (KEY_NAME, SUBNET_ID, VPC_ID, MY_IP, REPO_URL)

- Criar stack (CloudFormation + deploy via user data):
```bash
make create-stack
```

- Obter IP público da instância:
```bash
make get-ip
# Ou use: aws cloudformation describe-stacks --stack-name $(STACK_NAME) --query 'Stacks[0].Outputs' --output table
```

- Deploy completo (cria stack e imprime URL):
```bash
make deploy
# Mensagem final: ✅ Deploy concluído! Acesse: http://<IP_PUBLICO>:8000
```

---

Targets principais do Makefile

- make build — build da aplicação (yarn/npm)
- make docker-build — build da imagem Docker localmente
- make create-stack — cria o CloudFormation stack e provisiona EC2 + SG
- make get-ip — recupera o IP público do output do stack
- make deploy — create-stack + get-ip (deploy “one-shot”)
- make delete-stack — deleta o stack e aguarda término (pergunta confirmação)

---

Segurança

- SSH (22): configure MY_IP para seu IP público/32 — evitar deixar 0.0.0.0/0
- App (8000): por padrão aberta ao público — ajuste se precisar restringir
- Use KeyPair válido para acesso via SSH; prefira autenticação por chave (não senha)

---

Otimização de custos

- Instância única t3.micro (baixo custo) adequada para site estático/SPA
- Sem ELB, RDS ou outros recursos geradores de custo
- Use make delete-stack imediatamente após testes para evitar cobranças

---

GitHub Actions (integração sugerida)

- Sugestão de checks no CI:
  - yarn install && yarn build
  - make build
  - aws cloudformation validate-template --template-body file://juliana-joias.yaml
- Exemplo: .github/workflows/ci.yml (opcional)

---

Limpeza (remoção de recursos)

Para remover tudo:
```bash
make delete-stack
# Confirme 's' quando solicitado
```

Isso executa:
- aws cloudformation delete-stack --stack-name $(STACK_NAME)
- aguarda até stack-delete-complete

---

Dicas e troubleshooting

- Se o stack falhar, verifique eventos no CloudFormation Console para logs detalhados.
- Se o container não subir, conecte via SSH (se permitido) e cheque:
  - sudo docker ps -a
  - sudo docker logs <container>
  - /var/log/cloud-init-output.log (logs do user-data)
- Se a instância não pega IP público, confirme a Subnet tem auto-assign public IP ou o template está configurado corretamente.
- Valide o template CloudFormation localmente:
```bash
aws cloudformation validate-template --template-body file://juliana-joias.yaml
```

Resumo rápido

Local:
- make build
- docker-compose up --build -d → http://localhost:8000

AWS:
- Ajuste Makefile + aws configure
- make deploy → http://<IP_PUBLICO>:8000
- make delete-stack → remove recursos
