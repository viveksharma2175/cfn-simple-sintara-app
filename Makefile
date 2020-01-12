GIT_URL = https://github.com/rea-cruitment/simple-sinatra-app.git
IMAGE_NAME = simple-sinatra-app
ECR_POSTFIX ?= dkr.ecr.$(AWS_DEFAULT_REGION).amazonaws.com
CFN_VPC_TEMPLATE_FILE = infra/vpc.yaml
VPC_PARAMETER_FILE = infra/vpc_config.json
CFN_CLUSTER_TEMPLATE_FILE = infra/cluster.yaml
CLUSTER_PARAMETER_FILE = infra/cluster_config.json
CFN_SERVICE_TEMPLATE_FILE = infra/service.yaml
SERVICE_PARAMETER_FILE = infra/service_config.json

.PHONY: clone_repo build tags push deploy tests vpcsetup clustersetup deploy_vpc_cfn deploy_cluster_cfn deploy_service_cfn

release: build push 

vpcsetup: tests deploy_vpc_cfn

clustersetup: tests deploy_cluster_cfn 

servicesetup: tests deploy_service_cfn 

tests:
	echo "IMAGE_VERSION: ${IMAGE_VERSION}"; \
	echo "AWS_ACCOUNT: ${AWS_ACCOUNT}"; \
	echo "AWS_DEFAULT_REGION: ${AWS_DEFAULT_REGION}"; \
	aws --version; \
	docker --version; \
	git --version;

clone_repo: 
	echo "Cloning Repo..."; \
	if [ -d $(IMAGE_NAME) ]; then \
  		rm -r $(IMAGE_NAME); \
		git clone $(GIT_URL); \
	else \
		git clone $(GIT_URL); \
  	fi;

build: tests clone_repo
	echo "Starting the build..."; \
	docker build -f ./ApplicationDockerfile --no-cache --pull -t $(IMAGE_NAME):$(BUILD_VERSION) .

tags: 
	docker tag $(IMAGE_NAME):$(BUILD_VERSION) $(AWS_ACCOUNT).$(ECR_POSTFIX)/$(IMAGE_NAME):$(BUILD_VERSION);

push: tags
	echo "Assume role with this account $(AWS_ACCOUNT)"; \
	eval $$(aws ecr get-login --no-include-email --region $(AWS_DEFAULT_REGION)); \
	docker push $(AWS_ACCOUNT).$(ECR_POSTFIX)/$(IMAGE_NAME):$(BUILD_VERSION); \
	docker rmi -f $(AWS_ACCOUNT).$(ECR_POSTFIX)/$(IMAGE_NAME):$(BUILD_VERSION);

deploy_service_cfn:
	echo "Deploying service in account $(AWS_ACCOUNT)"; \
	aws cloudformation deploy --stack-name ServiceSetup --template-file $(CFN_SERVICE_TEMPLATE_FILE) --parameter-overrides DockerImageTag=$(BUILD_VERSION) ReleaseNumber=$(RELEASE_VERSION) $(shell jq -r '.[] | [.ParameterKey, .ParameterValue] | join("=")' $(SERVICE_PARAMETER_FILE)) --capabilities CAPABILITY_IAM;

deploy_vpc_cfn: 
	echo "Setting up VPC in account $(AWS_ACCOUNT)"; \
	aws cloudformation deploy --stack-name VPCSetup --template-file $(CFN_VPC_TEMPLATE_FILE) --parameter-overrides $(shell jq -r '.[] | [.ParameterKey, .ParameterValue] | join("=")' $(VPC_PARAMETER_FILE)) --capabilities CAPABILITY_IAM;

deploy_cluster_cfn: 
	echo "Setting up cluster in account $(AWS_ACCOUNT)"; \
	aws cloudformation deploy --stack-name ClusterSetup --template-file $(CFN_CLUSTER_TEMPLATE_FILE) --parameter-overrides $(shell jq -r '.[] | [.ParameterKey, .ParameterValue] | join("=")' $(CLUSTER_PARAMETER_FILE)) --capabilities CAPABILITY_IAM;
