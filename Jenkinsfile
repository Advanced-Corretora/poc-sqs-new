def agentLabel = 'ec2-fleet'
def ENV_DEPLOY = ""
def DOMAIN_PREFIX_ENV = ""
def VPC_ID = ""
def PUBLIC_SUBNETS_ID = ""
def CONTAINER_MEMORY = 512
def CONTAINER_VCPU = 256
def CONTAINER_QUANTITY = 1


// ############ VARIAVEIS DO PROJETO - ALTERAR OS VALORES PARA NOVOS PROJETOS ############
def PROJECT_NAME = "poc-sqs-new-service"
def DOMAIN_PREFIX = "poc-sqs-new" // Compoe url final do servico. Por exemplo: https://poc-sqs.advancedcorretora.com.br
def HEALTH_CHECK_PATH = "api/v1/" // normalmente 'api/v1/'
// #######################################################################################


if (BRANCH_NAME == 'develop') {
    DOMAIN_ALIAS = "${DOMAIN_PREFIX}-stageapi" 
    ENV_DEPLOY = "${env.ENV_STAGING_NAME}"
    VPC_ID = env.STAGING_VPC_ID
    PUBLIC_SUBNETS_ID = env.STAGING_PUBLIC_SUBNETS_ID
}

if (BRANCH_NAME == 'master') {
    DOMAIN_ALIAS = "${DOMAIN_PREFIX}-api"
    ENV_DEPLOY = "${env.ENV_PROD_NAME}"
    VPC_ID = env.PROD_VPC_ID
    PUBLIC_SUBNETS_ID = env.PROD_PUBLIC_SUBNETS_ID
    CONTAINER_MEMORY = 1024
    CONTAINER_VCPU = 512
    CONTAINER_QUANTITY = 1
}

// ############ ***** ATENÇÃO ***** NAO ALTERAR ESTA SEÇÃO ##################################################
def ECR_REPOSITORY = "${ENV_DEPLOY}-${PROJECT_NAME}-ecr"
def ECR_URI = ""
def TF_CONFIG_KEY = "terraform/${PROJECT_NAME}/${ENV_DEPLOY}/terraform.tfstate"
def IMAGE_TAG = "v-${new Date().format('yyyyMMdd-HHmmss')}"
// #######################################################################################

pipeline {
    agent {
        label agentLabel
    }

    stages {
        stage('Tooling versions') {
            steps {
                sh '''
                    git --version
                    docker --version
                    aws --version
                    terraform --version
                    yarn --version
                    terraform --version
                '''
            }
        }
        stage('Setup ECR') {
            steps {
                script {
                    dir('terraform') {
                        sh """
                            rm -rf .terraform

                            terraform init \
                                -backend-config="bucket=${env.AWS_S3_BUCKET}" \
                                -backend-config="key=${TF_CONFIG_KEY}" \
                                -backend-config="region=${env.AWS_REGION}"
                            
                            terraform apply \
                                -target=module.ecr \
                                -var="region=${env.AWS_REGION}" \
                                -var="service_name=${PROJECT_NAME}" \
                                -var="env=${ENV_DEPLOY}" \
                                -var="department=${env.DEPARTMENT}" \
                                -auto-approve
                        """
                        
                        ECR_URI = sh(
                            script: "terraform output -raw ecr_repository_url",
                            returnStdout: true
                        ).trim()
                    }
                }
            }
        }

        stage('Setup Env') {
            steps {
                sh """
                    aws configure set region ${env.AWS_REGION}
                    aws s3api get-object --bucket ${env.AWS_S3_BUCKET} --key envs/.env-${ENV_DEPLOY} .env
                """
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                sh """
                    aws ecr get-login-password --region ${env.AWS_REGION} | docker login --username AWS --password-stdin ${ECR_URI.split('/')[0]}
                    docker build -t ${ECR_URI}:${IMAGE_TAG} .
                    docker push ${ECR_URI}:${IMAGE_TAG}
                """
            }
        }

        stage('Deploy on ECS') {
            steps {
                script {
                    dir('terraform') {
                         sh """
                            terraform apply \
                                -target=module.ecs \
                                -var="region=${env.AWS_REGION}" \
                                -var="service_name=${PROJECT_NAME}" \
                                -var="env=${ENV_DEPLOY}" \
                                -var="department=${env.DEPARTMENT}" \
                                -var="ecr_image_tag=${IMAGE_TAG}" \
                                -var="domain_name=${env.DOMAIN_NAME}" \
                                -var="subdomain_prefix=${DOMAIN_ALIAS}" \
                                -var="health_check_path=${HEALTH_CHECK_PATH}" \
                                -var="vpc_id=${VPC_ID}" \
                                -var="public_subnets_id=${PUBLIC_SUBNETS_ID}" \
                                -var="container_memory=${CONTAINER_MEMORY}" \
                                -var="container_cpu=${CONTAINER_VCPU}" \
                                -var="container_quantity=${CONTAINER_QUANTITY}" \
                                -auto-approve
                        """
                    }
                }
            }
        }

        stage('Cleanup resources') {
            steps {
                sh '''
                    docker system prune -af --volumes
                '''
            }
        }
    }
}
