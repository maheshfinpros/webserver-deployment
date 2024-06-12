pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        S3_BUCKET = 'mahesh-project-asg'
        APPLICATION_NAME = 'mahesh-jenkins'
        DEPLOYMENT_GROUP_NAME = 'mahesh-jenkins-DG'
        INSTANCE_TAG_NAME = 'mahesh-jenkins-server'
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout([$class: 'GitSCM', 
                          branches: [[name: '*/main']], 
                          doGenerateSubmoduleConfigurations: false, 
                          extensions: [], 
                          userRemoteConfigs: [[url: 'https://github.com/maheshfinpros/webserver-deployment.git']]
                         ])
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
                sh 'zip -r webserver-deployment.zip Jenkinsfile README.md appspec.yml index1.html index2.html scripts/ webpack.config.js package.json package-lock.json'
                archiveArtifacts artifacts: 'webserver-deployment.zip', fingerprint: true
            }
        }

        stage('Upload to S3') {
            steps {
                echo 'Uploading to S3...'
                sh 'aws s3 cp webserver-deployment.zip s3://${S3_BUCKET}/webserver-deployment.zip --region $AWS_REGION'
            }
        }

        stage('Check and Stop Active Deployment') {
            steps {
                echo 'Checking for active deployments...'
                script {
                    def activeDeployment = sh(script: "aws deploy list-deployments --application-name ${APPLICATION_NAME} --deployment-group-name ${DEPLOYMENT_GROUP_NAME} --include-only-statuses InProgress --query deployments[0] --output text --region ${AWS_REGION}", returnStdout: true).trim()
                    if (activeDeployment != "None") {
                        echo "Stopping active deployment: ${activeDeployment}"
                        sh "aws deploy stop-deployment --deployment-id ${activeDeployment} --region ${AWS_REGION}"
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
                    def deploymentOutput = sh(script: "aws deploy create-deployment --application-name ${APPLICATION_NAME} --deployment-group-name ${DEPLOYMENT_GROUP_NAME} --s3-location bucket=${S3_BUCKET},bundleType=zip,key=webserver-deployment.zip --region ${AWS_REGION}", returnStdout: true).trim()
                    echo "Deployment Output: ${deploymentOutput}"
                }
            }
        }

        stage('Get Instance Details') {
            steps {
                echo 'Getting instance details...'
                script {
                    def instancesOutput = sh(script: "aws ec2 describe-instances --filters Name=tag:Name,Values=${INSTANCE_TAG_NAME} Name=instance-state-name,Values=running --query Reservations[*].Instances[*].[InstanceId,PrivateIpAddress,PublicIpAddress] --output text --region ${AWS_REGION}", returnStdout: true).trim()
                    echo "Instances Output: ${instancesOutput}"
                    if (!instancesOutput) {
                        error "No running instances found for tag '${INSTANCE_TAG_NAME}'"
                    }
                }
            }
        }

        stage('Run Commands on Instances') {
            when {
                expression {
                    return sh(script: "aws ec2 describe-instances --filters Name=tag:Name,Values=${INSTANCE_TAG_NAME} Name=instance-state-name,Values=running --query Reservations[*].Instances[*].[InstanceId] --output text --region ${AWS_REGION}", returnStdout: true).trim().length() > 0
                }
            }
            steps {
                echo 'Running commands on instances...'
                script {
                    def instances = sh(script: "aws ec2 describe-instances --filters Name=tag:Name,Values=${INSTANCE_TAG_NAME} Name=instance-state-name,Values=running --query Reservations[*].Instances[*].[InstanceId] --output text --region ${AWS_REGION}", returnStdout: true).trim().split()
                    for (instance in instances) {
                        sh """
                        aws ssm send-command \
                            --instance-ids ${instance} \
                            --document-name 'AWS-RunShellScript' \
                            --comment 'Running ping commands on instance' \
                            --parameters '{"commands":["ping google.com", "ping facebook.com", "ping youtube.com"]}' \
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
