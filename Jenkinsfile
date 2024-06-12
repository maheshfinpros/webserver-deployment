pipeline {
    agent any
    environment {
        AWS_REGION = 'ap-south-1'
        S3_BUCKET = 'mahesh-project-asg'
        GIT_CREDENTIALS_ID = 'github'
        SSH_CREDENTIALS_ID = 'ubuntu'
        APP_NAME = 'mahesh-jenkins'
        DEPLOYMENT_GROUP_NAME = 'mahesh-jenkins-DG'
    }
    stages {
        stage('Checkout SCM') {
            steps {
                script {
                    try {
                        checkout([$class: 'GitSCM', branches: [[name: '*/main']], 
                                  doGenerateSubmoduleConfigurations: false, 
                                  extensions: [], 
                                  userRemoteConfigs: [[credentialsId: "${GIT_CREDENTIALS_ID}", url: 'https://github.com/maheshfinpros/webserver-deployment.git']]])
                    } catch (Exception e) {
                        echo "Error during SCM checkout: ${e}"
                        currentBuild.result = 'FAILURE'
                        error("SCM checkout failed.")
                    }
                }
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
                sh "aws s3 cp webserver-deployment.zip s3://${S3_BUCKET}/webserver-deployment.zip --region ${AWS_REGION}"
            }
        }
        stage('Check and Stop Active Deployment') {
            steps {
                echo 'Checking for active deployments...'
                script {
                    def activeDeploymentId = sh(script: "aws deploy list-deployments --application-name ${APP_NAME} --deployment-group-name ${DEPLOYMENT_GROUP_NAME} --include-only-statuses InProgress --query deployments[0] --output text --region ${AWS_REGION}", returnStdout: true).trim()
                    if (activeDeploymentId != 'None') {
                        echo "Stopping active deployment: ${activeDeploymentId}"
                        sh "aws deploy stop-deployment --deployment-id ${activeDeploymentId} --region ${AWS_REGION}"
                    } else {
                        echo "No active deployment found."
                    }
                }
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying the application...'
                script {
                    def deployOutput = sh(script: "aws deploy create-deployment --application-name ${APP_NAME} --deployment-group-name ${DEPLOYMENT_GROUP_NAME} --s3-location bucket=${S3_BUCKET},bundleType=zip,key=webserver-deployment.zip --region ${AWS_REGION}", returnStdout: true).trim()
                    echo "Deployment Output: ${deployOutput}"
                }
            }
        }
        stage('Get Instance Details') {
            steps {
                echo 'Getting instance details...'
                script {
                    def instancesOutput = sh(script: "aws ec2 describe-instances --filters Name=tag:Name,Values=${APP_NAME} Name=instance-state-name,Values=running --query Reservations[*].Instances[*].[InstanceId,PrivateIpAddress,PublicIpAddress] --output text --region ${AWS_REGION}", returnStdout: true).trim()
                    def instances = instancesOutput.split("\\n")
                    if (instances.size() > 0 && instances[0] != '') {
                        echo "Instance Details: ${instances.join(', ')}"
                    } else {
                        error "No running instances found for tag '${APP_NAME}'"
                    }
                }
            }
        }
        stage('Run Commands on Instances') {
            when {
                expression {
                    return env.instances && env.instances.size() > 0
                }
            }
            steps {
                echo 'Running commands on instances...'
                script {
                    sshagent(credentials: ["${SSH_CREDENTIALS_ID}"]) {
                        def instancesOutput = sh(script: "aws ec2 describe-instances --filters Name=tag:Name,Values=${APP_NAME} Name=instance-state-name,Values=running --query Reservations[*].Instances[*].[PublicIpAddress] --output text --region ${AWS_REGION}", returnStdout: true).trim()
                        def instances = instancesOutput.split("\\n")
                        for (instance in instances) {
                            if (instance != '') {
                                sh "ssh -o StrictHostKeyChecking=no ubuntu@${instance} 'ping -c 4 google.com'"
                                sh "ssh -o StrictHostKeyChecking=no ubuntu@${instance} 'ping -c 4 facebook.com'"
                                sh "ssh -o StrictHostKeyChecking=no ubuntu@${instance} 'ping -c 4 youtube.com'"
                            }
                        }
                    }
                }
            }
        }
    }
    post {
        always {
            echo 'Pipeline finished.'
        }
        success {
            echo 'Pipeline succeeded.'
        }
        failure {
            echo 'Pipeline failed.'
        }
    }
}
