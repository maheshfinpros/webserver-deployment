pipeline {
    agent any

    environment {
        S3_BUCKET = 'mahesh-project-asg'
        S3_REGION = 'ap-south-1'
        APP_NAME = 'mahesh-jenkins'
        DEPLOY_GROUP = 'mahesh-jenkins-DG'
        INSTANCE_IDS = 'i-09759cd2f95e9f5f9 i-06b7c8a20f24b5af5 i-0ef074045f487a1cf'
        SSH_CREDENTIALS_ID = 'mahesh-ssh'
        COMMANDS = 'your-command-here'
        DIRECTORIES = 'dir1 dir2'
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }
        stage('Create package.json') {
            steps {
                script {
                    writeFile file: 'package.json', text: '''{
                        "name": "mahesh-project",
                        "version": "1.0.0",
                        "description": "",
                        "main": "index.js",
                        "scripts": {
                            "build": "echo Build process completed successfully"
                        },
                        "author": "",
                        "license": "ISC"
                    }'''
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
                archiveArtifacts artifacts: 'webserver-deployment.zip'
            }
        }
        stage('Upload to S3') {
            steps {
                echo 'Uploading to S3...'
                sh "aws s3 cp webserver-deployment.zip s3://${S3_BUCKET}/webserver-deployment.zip --region ${S3_REGION}"
            }
        }
        stage('Check and Stop Active Deployment') {
            steps {
                echo 'Checking for active deployments...'
                script {
                    def activeDeploymentId = sh(script: "aws deploy list-deployments --application-name ${APP_NAME} --deployment-group-name ${DEPLOY_GROUP} --include-only-statuses InProgress --query 'deployments[0]' --output text --region ${S3_REGION}", returnStdout: true).trim()
                    if (activeDeploymentId != "None") {
                        echo "Stopping active deployment: ${activeDeploymentId}"
                        sh "aws deploy stop-deployment --deployment-id ${activeDeploymentId} --region ${S3_REGION}"
                    } else {
                        echo "No active deployments found."
                    }
                }
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying the application...'
                script {
                    def deployOutput = sh(script: "aws deploy create-deployment --application-name ${APP_NAME} --deployment-group-name ${DEPLOY_GROUP} --s3-location bucket=${S3_BUCKET},bundleType=zip,key=webserver-deployment.zip --region ${S3_REGION}", returnStdout: true).trim()
                    echo "Deployment Output: ${deployOutput}"
                }
            }
        }
        stage('Get Instance Details') {
            steps {
                echo 'Getting instance details...'
                script {
                    def instanceDetails = sh(script: "aws ec2 describe-instances --instance-ids ${INSTANCE_IDS} --query 'Reservations[*].Instances[*].[InstanceId,PrivateIpAddress]' --output text --region ${S3_REGION}", returnStdout: true).trim()
                    echo "Instance Details: ${instanceDetails}"
                }
            }
        }
        stage('Run Commands on Instances') {
            steps {
                echo 'Running commands on instances...'
                script {
                    sshagent([SSH_CREDENTIALS_ID]) {
                        def instanceList = INSTANCE_IDS.split()
                        def directoryList = DIRECTORIES.split()
                        for (instance in instanceList) {
                            for (dir in directoryList) {
                                sh "ssh -o StrictHostKeyChecking=no ubuntu@${instance} 'cd ${dir} && ${COMMANDS}'"
                            }
                        }
                    }
                }
            }
        }
        stage('Declarative: Post Actions') {
            steps {
                echo 'Performing post-build actions...'
                sh 'mkdir -p jenkins/logs'
                archiveArtifacts artifacts: 'jenkins/logs/**'
                script {
                    if (fileExists('build.log')) {
                        archiveArtifacts artifacts: 'build.log'
                    } else {
                        echo 'Error: build.log does not exist.'
                    }
                }
            }
        }
    }
}
