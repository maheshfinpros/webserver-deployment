pipeline {
    agent any
    environment {
        // AWS Configuration
        AWS_REGION = 'ap-south-1'
        S3_BUCKET = 'mahesh-project-asg'
        APP_NAME = 'mahesh-jenkins'
        DEPLOYMENT_GROUP_NAME = 'mahesh-jenkins-DG'
        INSTANCE_TAG_NAME = 'mahesh-jenkins-server'

        // File paths
        ARTIFACT_NAME = 'webserver-deployment.zip'

        // AWS CLI paths for easier modification
        AWS_DEPLOY_COMMAND = "aws deploy"
        AWS_S3_COMMAND = "aws s3"
        AWS_EC2_COMMAND = "aws ec2"
        AWS_SSM_COMMAND = "aws ssm"
    }
    stages {
        stage('Checkout SCM') {
            steps {
                echo 'Checking out SCM...'
                checkout scm
            }
        }
        stage('Build') {
            steps {
                echo 'Building the project...'
                sh 'npm install'
                sh 'npm run build'
            }
        }
        stage('Package') {
            steps {
                echo 'Packaging the project...'
                sh "zip -r ${ARTIFACT_NAME} Jenkinsfile README.md appspec.yml index1.html index2.html scripts/ webpack.config.js package.json package-lock.json"
                archiveArtifacts artifacts: "${ARTIFACT_NAME}", fingerprint: true
            }
        }
        stage('Upload to S3') {
            steps {
                echo 'Uploading to S3...'
                sh "${AWS_S3_COMMAND} cp ${ARTIFACT_NAME} s3://${S3_BUCKET}/${ARTIFACT_NAME} --region ${AWS_REGION}"
            }
        }
        stage('Check and Stop Active Deployment') {
            steps {
                echo 'Checking for active deployments...'
                script {
                    def deploymentId = sh(script: "${AWS_DEPLOY_COMMAND} list-deployments --application-name ${APP_NAME} --deployment-group-name ${DEPLOYMENT_GROUP_NAME} --include-only-statuses InProgress --query deployments[0] --output text --region ${AWS_REGION}", returnStdout: true).trim()
                    if (deploymentId != "None") {
                        echo "Stopping active deployment: ${deploymentId}"
                        sh "${AWS_DEPLOY_COMMAND} stop-deployment --deployment-id ${deploymentId} --region ${AWS_REGION}"
                    } else {
                        echo 'No active deployment to stop.'
                    }
                }
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying the application...'
                script {
                    def deploymentOutput = sh(script: "${AWS_DEPLOY_COMMAND} create-deployment --application-name ${APP_NAME} --deployment-group-name ${DEPLOYMENT_GROUP_NAME} --s3-location bucket=${S3_BUCKET},bundleType=zip,key=${ARTIFACT_NAME} --region ${AWS_REGION}", returnStdout: true).trim()
                    echo "Deployment Output: ${deploymentOutput}"
                }
            }
        }
        stage('Get Instance Details') {
            steps {
                echo 'Getting instance details...'
                script {
                    def instancesOutput = sh(script: "${AWS_EC2_COMMAND} describe-instances --filters Name=tag:Name,Values=${INSTANCE_TAG_NAME} Name=instance-state-name,Values=running --query Reservations[*].Instances[*].[InstanceId,PrivateIpAddress,PublicIpAddress] --output text --region ${AWS_REGION}", returnStdout: true).trim()
                    echo "Instances Output: ${instancesOutput}"
                    env.INSTANCE_IDS = instancesOutput
                }
            }
        }
        stage('Run Commands on Instances') {
            steps {
                echo 'Running commands on instances...'
                script {
                    def instanceIds = env.INSTANCE_IDS.split()
                    for (instance in instanceIds) {
                        sh """
                        ${AWS_SSM_COMMAND} send-command \
                            --instance-ids ${instance} \
                            --document-name 'AWS-RunShellScript' \
                            --comment 'Running custom commands on instance' \
                            --parameters '{"commands":["ping -c 4 google.com", "echo \\"Hello World\\" > /tmp/maheshmatta", "cat /tmp/maheshmatta"]}' \
                            --region ${AWS_REGION}
                        """
                    }
                }
            }
        }
    }
    post {
        always {
            echo 'Pipeline finished.'
        }
        failure {
            echo 'Pipeline failed.'
        }
    }
}
