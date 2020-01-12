# Sinatra Application Deployment to AWS ECS

This project deploys a simple sinatra application to AWS ECS. The application runs on port 80 and returns "Hello World".

## Background

The project creates an Ubuntu docker container with all the necessary packages like git, aws cli, docker, python and jq. This container is then used to create the necessary ECS infrastructure on AWS, clone the sinatra app from git repository and deploy to AWS ECS cluster.

## Architecture
![alt text](https://raw.githubusercontent.com/viveksharma2175/cfn-simple-sintara-app/master/gitimages/REA1.png)

## Resource to be Created
- VPC
- Public and Private Subnets
- Route Table
- Internet Gateway
- NAT Gateway
- ECS Cluster, Service and Tasks
- Auto scaling of ECS instances in cluster and the containers running in the instances
- Load Balancer listening to http requests on port 80
- Bastion Server

## Design
1. The application is deployed using docker containers which provides flexibility and assurance that it will work on any server with just docker installed.
2. The conatiners are deployed on ECS cluster with auto scaling enabled which scales the servers and the containers based on CPU usage and provides high availabilty.
3. The architecture provides reliability as the instances can be spun in different availibility zones to prevent from instance failure in a particular availibility zone.
4. The server configuration like region, instance type, number of instances and the number of containers, container CPU and memory allocation, path, etc. are configurable using the param file xxxx_config.json in the infra folder.
5. The application runs a docker container of Phusion Passenger Application + Nginx server.

## Requirements
- AWS user Account with rights to create the above resources and the `Access Key ID` and the `Secret Access Key` of the user.
- `Docker` installed on the system from where the commands will be initiated.
- Key to access the ECS instances. The key name passed in the config files is `InterviewKey`. Create a key with the name `InterviewKey` and download to the local system. Set the rigths of the file to chmod 400.

## Assumptions

- To listen to the requests on port 80, coming from the load balancer
- To be deployed in the Sydney region
- To overwrite the existing service release with the new release deployment (deployment startegies like blue-green, canary, etc. are not implemented)
- To run the commands on a linux machine (to run on a windows machine install git bash)

## Steps to Create Infrastructure
1. Get the file on the local system
    - Clone this repository on your local system
    - From the directory of the Dockerfile, open a terminal
    - Make necessary changes to the config.json files if needed.
    - Fire command to build the docker container, `docker build -t cicd .` (make note of the dot '.' at the end of the command). This can take a few minutes during the initial run to get the base image and setup the container with necessary packages. (This may take around 15 minutes approximately for the first run)
2. Create the virtual private cloud in AWS
    - Fire the command in the terminal:
        `docker run -e "event=vpcsetup" -e "aws_region=<<AWS-REGION>>" -e "aws_account=<<AWS-ACCOUNT-NUMBER>>" -e "aws_access_key_id=<<AWS-ACCESS-ID>>" -e "aws_secret_access_key=<<AWS-SECRET-ACCESS-KEY>>" cicd:latest`
3. To create the ECS cluster and the ECR repository
    - Fire the command in the terminal:
        `docker run -e "event=clustersetup" -e "aws_region=<<AWS-REGION>>" -e "aws_account=<<AWS-ACCOUNT-NUMBER>>" -e "aws_access_key_id=<<AWS-ACCESS-ID>>" -e "aws_secret_access_key=<<AWS-SECRET-ACCESS-KEY>>" cicd:latest`
4. Clone the repo with the sinatra app, build a docker image and push to repository    
    - Fire the command by replacing the values in << >> with AWS account details in the terminal:
        `docker run -e "event=build" -e "aws_region=<<AWS-REGION>>" -e "build_version=<<BUILD-VERSION>>" -e "aws_account=<<AWS-ACCOUNT-NUMBER>>" -e "aws_access_key_id=<<AWS-ACCESS-ID>>" -e "aws_secret_access_key=<<AWS-SECRET-ACCESS-KEY>>" -v /var/run/docker.sock:/var/run/docker.sock -it cicd:latest`
5. Deploy the docker image from the ECR repository to ECS   
    - Fire the command by replacing the values in << >> with AWS account details in the terminal:
        `docker run -e "event=deploy" -e "build_version=<<BUILD-VERSION>>" -e "release_version=<<DEPLOYMENT-VERSION>>" -e "aws_region=<<AWS-REGION>>" -e "aws_account=<<AWS-ACCOUNT-NUMBER>>" -e "aws_access_key_id=<<AWS-ACCESS-ID>>" -e "aws_secret_access_key=<<AWS-SECRET-ACCESS-KEY>>" cicd:latest`
      Note: the value for `DEPLOYMENT-VERSION` passed into `release_version` should not contain special characters.
6. Get the DNS name for the load balancer to send request to the application
    - The DNS name can be found from the Load Balancer service page in AWS account (Service > EC2 > Load Balancers)
    OR
    - Cloudformation page in AWS account, select ClusterSetup and from Outputs tab and the value of the URL

Incase of any errors, log in to the AWS account and go to the cloudformation service and select the respective stack for the error message.

## Steps to Destroy Infrastructure
1. The infrastructure can be destroyed from the cloudformation service in AWS.
    - First, delete the images pushed to the ECR repository to avoid errors.
    - Second, delete the ServiceSetup stack and wait for it to complete.
    - Third, delete the ClusterSetup stack and wait for it to complete.
    - Fourth, delete the VPCeSetup stack and wait for it to complete.


If you have any questions please feel free to contact viveksharma2175@gmail.com
