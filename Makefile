STACK_NAME    = docker-aws
TEMPLATE_FILE = juliana-joias.yaml
REGION        = us-east-1
KEY_NAME      = docker-ju
REPO_URL      = https://github.com/JulianaForbici/docker-aws
BRANCH        = main

SUBNET_ID     = subnet-06ad8ff9e17e7bef3
VPC_ID        = vpc-06786ee7f7a163059
MY_IP         = 0.0.0.0/0 

build:
	@echo "🔧 Instalando dependências e gerando build da aplicação..."
	rm -rf node_modules
	yarn install
	yarn build
	@echo "✅ Build concluído!"

docker-build:
	@echo "🐳 Construindo imagem Docker local..."
	docker build -t jewelry-app .
	@echo "✅ Imagem Docker criada com sucesso!"

create-stack:
	@echo "🚀 Criando stack '$(STACK_NAME)'..."
	aws cloudformation create-stack \
		--stack-name $(STACK_NAME) \
		--template-body file://$(TEMPLATE_FILE) \
		--parameters \
			ParameterKey=KeyName,ParameterValue=$(KEY_NAME) \
			ParameterKey=RepoUrl,ParameterValue=$(REPO_URL) \
			ParameterKey=Branch,ParameterValue=$(BRANCH) \
			ParameterKey=SubnetId,ParameterValue=$(SUBNET_ID) \
			ParameterKey=VpcId,ParameterValue=$(VPC_ID) \
			ParameterKey=MyIpAddress,ParameterValue=$(MY_IP) \
		--region $(REGION)

	@echo "⏳ Aguardando a conclusão da criação do stack..."
	aws cloudformation wait stack-create-complete \
		--stack-name $(STACK_NAME) \
		--region $(REGION)

	@echo "✅ Stack '$(STACK_NAME)' criado com sucesso!"

get-ip:
	@aws cloudformation describe-stacks \
		--stack-name $(STACK_NAME) \
		--query "Stacks[0].Outputs[?OutputKey=='PublicIP'].OutputValue" \
		--output text \
		--region $(REGION)

deploy: create-stack
	@echo "⏳ Aguardando inicialização da instância..."
	@IP=$$(make get-ip); \
	if [ -z "$$IP" ]; then \
		echo "❌ Não foi possível obter o IP da instância"; \
	else \
		echo "✅ Deploy concluído! Acesse: http://$$IP:8000"; \
	fi

delete-stack:
	@read -p "⚠️ Tem certeza que quer deletar o stack $(STACK_NAME)? (s/n) " resp; \
	if [ "$$resp" = "s" ]; then \
		aws cloudformation delete-stack --stack-name $(STACK_NAME) --region $(REGION); \
		aws cloudformation wait stack-delete-complete --stack-name $(STACK_NAME) --region $(REGION); \
		echo "✅ Stack removido com sucesso!"; \
	else \
		echo "❌ Operação cancelada."; \
	fi