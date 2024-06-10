pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        S3_BUCKET = 'mahesh-project-asg'
        S3_KEY = 'webserver-deployment.zip'
        APPLICATION_NAME = 'mahesh-jenkins'
        DEPLOYMENT_GROUP_NAME = 'mahesh-jenkins-DG'
        INSTANCE_IDS = 'i-09759cd2f95e9f5f9 i-06b7c8a20f24b5af5 i-0ef074045f487a1cf'
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout([
                    $class: 'GitSCM', 
                    branches: [[name: '*/main']], 
                    userRemoteConfigs: [[url: 'https://github.com/maheshfinpros/webserver-deployment.git', credentialsId: 'github']]
                ])
            }
        }

        stage('Create package.json') {
            steps {
                script {
                    writeFile file: 'package.json', text: '''{
  "name": "mahesh-project",
  "version": "1.0.0",
  "scripts": {
    "build": "echo Build process completed successfully"
  }
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
                sh "aws s3 cp webserver-deployment.zip s3://${S3_BUCKET}/${S3_KEY} --region ${AWS_REGION}"
            }
        }

        stage('Check and Stop Active Deployment') {
            steps {
                echo 'Checking for active deployments...'
                script {
                    def activeDeployment = sh(script: "aws deploy list-deployments --application-name ${APPLICATION_NAME} --deployment-group-name ${DEPLOYMENT_GROUP_NAME} --include-only-statuses InProgress --query deployments[0] --output text --region ${AWS_REGION}", returnStdout: true).trim()
                    if (activeDeployment != "None") {
                        echo "Active deployment found: ${activeDeployment}. Stopping it..."
                        sh "aws deploy stop-deployment --deployment-id ${activeDeployment} --region ${AWS_REGION}"
                    } else {
                        echo 'No active deployments found.'
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                echo 'Deploying the application...'
                script {
                    def deploymentOutput = sh(script: "aws deploy create-deployment --application-name ${APPLICATION_NAME} --deployment-group-name ${DEPLOYMENT_GROUP_NAME} --s3-location bucket=${S3_BUCKET},bundleType=zip,key=${S3_KEY} --region ${AWS_REGION}", returnStdout: true).trim()
                    echo "Deployment Output: ${deploymentOutput}"
                }
            }
        }

        stage('Get Instance Details') {
            steps {
                echo 'Getting instance details...'
                script {
                    def instanceDetails = sh(script: "aws ec2 describe-instances --instance-ids ${INSTANCE_IDS} --query 'Reservations[*].Instances[*].[InstanceId,PrivateIpAddress]' --output text --region ${AWS_REGION}", returnStdout: true).trim()
                    echo "Instance Details: ${instanceDetails}"
                }
            }
        }

        stage('Run Commands on Instances') {
            steps {
                echo 'Running commands on instances...'
                script {
                    sshagent(credentials: ['mahesh-ssh']) { // Updated the ID here
                        def instances = [
                            "3.110.224.24",
                            "13.127.198.30",
                            "52.66.24.205"
                        ]
                        instances.each { instance ->
                            def command = "ssh -o StrictHostKeyChecking=no mahesh@${instance} ping -c 4 google.com"
                            echo "Running command: ${command}"
                            try {
                                sh command
                            } catch (Exception e) {
                                echo "Failed to run command on ${instance}: ${e.getMessage()}"
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
    }
}
