pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        AWS_CREDENTIALS_ID = 'aws-access'
        S3_BUCKET_NAME = 'mahesh-project-asg'
        APPLICATION_NAME = 'mahesh-jenkins'
        DEPLOYMENT_GROUP_NAME = 'mahesh-jenkins-DG'
        SSH_CREDENTIALS_ID = 'jenkins-ssh-key'  // Ensure this matches the ID of your Jenkins SSH credentials
        SSH_USERNAME = 'ubuntu'  // Replace with your SSH username (e.g., ec2-user)
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/maheshfinpros/webserver-deployment.git', credentialsId: 'github'
            }
        }
        stage('Build') {
            steps {
                script {
                    echo 'Building the project...'
                    // Add your build commands here if necessary
                }
            }
        }
        stage('Package') {
            steps {
                withAWS(credentials: "${AWS_CREDENTIALS_ID}", region: "${AWS_REGION}") {
                    sh 'zip -r webserver-deployment.zip Jenkinsfile README.md appspec.yml index1.html index2.html scripts/ > build.log 2>&1'
                    archiveArtifacts artifacts: 'build.log', allowEmptyArchive: true
                }
            }
        }
        stage('Upload to S3') {
            steps {
                withAWS(credentials: "${AWS_CREDENTIALS_ID}", region: "${AWS_REGION}") {
                    s3Upload(bucket: "${S3_BUCKET_NAME}", path: "webserver-deployment.zip", file: "webserver-deployment.zip")
                }
            }
        }
        stage('Deploy') {
            steps {
                withAWS(credentials: "${AWS_CREDENTIALS_ID}", region: "${AWS_REGION}") {
                    script {
                        sh """
                        aws deploy create-deployment \
                            --application-name ${APPLICATION_NAME} \
                            --deployment-group-name ${DEPLOYMENT_GROUP_NAME} \
                            --s3-location bucket=${S3_BUCKET_NAME},bundleType=zip,key=webserver-deployment.zip \
                            --region ${AWS_REGION}
                        """
                    }
                }
            }
        }
        stage('Get Instance Details') {
            steps {
                withAWS(credentials: "${AWS_CREDENTIALS_ID}", region: "${AWS_REGION}") {
                    script {
                        def instances = sh(script: 'aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].[InstanceId,PrivateIpAddress]" --output text', returnStdout: true).trim()
                        env.INSTANCE_DETAILS = instances
                        echo "Instance Details: ${env.INSTANCE_DETAILS}"
                    }
                }
            }
        }
        stage('Run Commands on Instances') {
            steps {
                script {
                    def instanceDetails = env.INSTANCE_DETAILS.split('\n')
                    instanceDetails.each { detail ->
                        def parts = detail.split('\\s+')
                        def instanceId = parts[0]
                        def privateIp = parts[1]
                        
                        sshagent(credentials: ['${SSH_CREDENTIALS_ID}']) {
                            sh """
                            ssh -o StrictHostKeyChecking=no ${SSH_USERNAME}@${privateIp} 'echo "Running command on ${instanceId} (${privateIp})"'
                            """
                        }
                    }
                }
            }
        }
    }
    post {
        always {
            script {
                sh 'mkdir -p jenkins/logs'
                try {
                    archiveArtifacts artifacts: '**/build.log', allowEmptyArchive: true
                    withAWS(credentials: "${AWS_CREDENTIALS_ID}", region: "${AWS_REGION}") {
                        s3Upload(bucket: "${S3_BUCKET_NAME}", path: "jenkins-logs/${env.BUILD_NUMBER}.log", file: "build.log")
                    }
                } catch (Exception e) {
                    echo "Error uploading logs: ${e}"
                }
            }
        }
        failure {
            echo 'Deployment failed!'
        }
    }
}
