pipeline {
    agent any

    stages {
        stage('Declarative: Checkout SCM') {
            steps {
                checkout scm
            }
        }
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
                sh 'aws s3 cp webserver-deployment.zip s3://mahesh-project-asg/webserver-deployment.zip --region ap-south-1'
            }
        }
        stage('Check and Stop Active Deployment') {
            steps {
                echo 'Checking for active deployments...'
                script {
                    def activeDeployment = sh(script: 'aws deploy list-deployments --application-name mahesh-jenkins --deployment-group-name mahesh-jenkins-DG --include-only-statuses InProgress --query deployments[0] --output text --region ap-south-1', returnStdout: true).trim()
                    if (activeDeployment != 'None') {
                        echo "Active deployment found: ${activeDeployment}"
                        sh "aws deploy stop-deployment --deployment-id ${activeDeployment} --region ap-south-1"
                        echo "Stopped active deployment: ${activeDeployment}"
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
                    def deploymentOutput = sh(script: 'aws deploy create-deployment --application-name mahesh-jenkins --deployment-group-name mahesh-jenkins-DG --s3-location bucket=mahesh-project-asg,bundleType=zip,key=webserver-deployment.zip --region ap-south-1', returnStdout: true).trim()
                    echo "Deployment Output: ${deploymentOutput}"
                }
            }
        }
        stage('Get Instance Details') {
            steps {
                echo 'Getting instance details...'
                script {
                    def instanceDetails = sh(script: 'aws ec2 describe-instances --instance-ids i-09759cd2f95e9f5f9 i-06b7c8a20f24b5af5 i-0ef074045f487a1cf --query Reservations[*].Instances[*].[InstanceId,PrivateIpAddress] --output text --region ap-south-1', returnStdout: true).trim()
                    echo "Instance Details: ${instanceDetails}"
                }
            }
        }
        stage('Run Commands on Instances') {
            steps {
                echo 'Running commands on instances...'
                script {
                    sshagent(['mahesh-ssh']) {
                        def commands = ["ssh -o StrictHostKeyChecking=no mahesh@3.110.224.24 ping -c 4 google.com",
                                        "ssh -o StrictHostKeyChecking=no mahesh@13.127.198.30 ping -c 4 google.com",
                                        "ssh -o StrictHostKeyChecking=no mahesh@52.66.24.205 ping -c 4 google.com"]

                        for (command in commands) {
                            try {
                                sh command
                            } catch (Exception e) {
                                echo "Failed to run command: ${command}"
                                echo "Error: ${e.getMessage()}"
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
