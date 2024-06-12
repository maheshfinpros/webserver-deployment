pipeline {
    agent any

    environment {
        // Define environment variables for easy configuration
        AWS_REGION = 'ap-south-1'
        S3_BUCKET = 'mahesh-project-asg'
        APPLICATION_NAME = 'mahesh-jenkins'
        DEPLOYMENT_GROUP_NAME = 'mahesh-jenkins-DG'
        SSH_CREDENTIALS_ID = 'mahesh-ssh' // Updated with your actual SSH credentials ID in Jenkins
        SSH_USER = 'mahesh' // Updated with your actual SSH username
    }

    stages {
        stage('Checkout SCM') {
            steps {
                // Checkout the code from the Git repository
                git branch: 'main', credentialsId: 'github', url: 'https://github.com/maheshfinpros/webserver-deployment.git'
            }
        }
        stage('Build') {
            steps {
                echo 'Building the project...'
                // Install dependencies
                sh 'npm install'
                // Run the build script
                sh 'npm run build'
            }
        }
        stage('Package') {
            steps {
                echo 'Packaging the project...'
                // Package the project files into a zip file
                sh 'zip -r webserver-deployment.zip Jenkinsfile README.md appspec.yml index1.html index2.html scripts/ webpack.config.js package.json package-lock.json'
                // Archive the packaged artifact
                archiveArtifacts artifacts: 'webserver-deployment.zip', fingerprint: true
            }
        }
        stage('Upload to S3') {
            steps {
                echo 'Uploading to S3...'
                // Upload the zip file to the specified S3 bucket
                sh "aws s3 cp webserver-deployment.zip s3://${env.S3_BUCKET}/webserver-deployment.zip --region ${env.AWS_REGION}"
            }
        }
        stage('Check and Stop Active Deployment') {
            steps {
                echo 'Checking for active deployments...'
                script {
                    // Check for any active deployments
                    def activeDeployment = sh(script: "aws deploy list-deployments --application-name ${env.APPLICATION_NAME} --deployment-group-name ${env.DEPLOYMENT_GROUP_NAME} --include-only-statuses InProgress --query deployments[0] --output text --region ${env.AWS_REGION}", returnStdout: true).trim()
                    if (activeDeployment != 'None') {
                        echo "Stopping active deployment: ${activeDeployment}"
                        // Stop the active deployment if found
                        sh "aws deploy stop-deployment --deployment-id ${activeDeployment} --region ${env.AWS_REGION}"
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
                    // Create a new deployment
                    def deploymentOutput = sh(script: "aws deploy create-deployment --application-name ${env.APPLICATION_NAME} --deployment-group-name ${env.DEPLOYMENT_GROUP_NAME} --s3-location bucket=${env.S3_BUCKET},bundleType=zip,key=webserver-deployment.zip --region ${env.AWS_REGION}", returnStdout: true).trim()
                    echo "Deployment Output: ${deploymentOutput}"
                }
            }
        }
        stage('Get Instance Details') {
            steps {
                echo 'Getting instance details...'
                script {
                    // Retrieve instance details dynamically
                    def instanceDetails = sh(script: "aws ec2 describe-instances --filters 'Name=tag:Name,Values=${env.APPLICATION_NAME}' 'Name=instance-state-name,Values=running' --query 'Reservations[*].Instances[*].[InstanceId,PrivateIpAddress,PublicIpAddress]' --output text --region ${env.AWS_REGION}", returnStdout: true).trim()
                    env.INSTANCE_DETAILS = instanceDetails
                    echo "Instance Details: ${instanceDetails}"
                }
            }
        }
        stage('Run Commands on Instances') {
            steps {
                echo 'Running commands on instances...'
                script {
                    def instances = env.INSTANCE_DETAILS.split('\n')
                    sshagent([env.SSH_CREDENTIALS_ID]) {
                        for (instance in instances) {
                            def details = instance.split('\t')
                            def instanceId = details[0]
                            def privateIp = details[1]
                            def publicIp = details[2]
                            echo "Running commands on instance: ${instanceId} (${publicIp})"
                            try {
                                // Running multiple commands on the instance
                                sh "ssh -o StrictHostKeyChecking=no ${env.SSH_USER}@${publicIp} 'ping -c 4 facebook.com && ping -c 4 youtube.com'"
                            } catch (Exception e) {
                                echo "Failed to run commands on ${publicIp}: ${e.message}"
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
