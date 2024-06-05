pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        S3_BUCKET_NAME = 'mahesh-project-asg'
        APPLICATION_NAME = 'mahesh-jenkins'
        DEPLOYMENT_GROUP_NAME = 'mahesh-jenkins-DG'
        SSH_CREDENTIALS_ID = 'mahesh-ssh'
        SSH_USERNAME = 'ubuntu'
        IAM_ROLE_ARN = 'arn:aws:iam::377850997170:role/aws-codedelpoy-ec2'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/maheshfinpros/webserver-deployment.git', credentialsId: 'github'
            }
        }
        stage('Build') {
            steps {
                echo 'Building the project...'
                sh 'npm install'
                // Ensure npm run build script is available in package.json
                sh 'npm run build'
            }
        }
        stage('Package') {
            steps {
                withAWS(credentials: 'aws', region: AWS_REGION) {
                    sh 'zip -r webserver-deployment.zip Jenkinsfile README.md appspec.yml index1.html index2.html scripts/'
                    archiveArtifacts artifacts: 'build.log', allowEmptyArchive: true
                }
            }
        }
        stage('Upload to S3') {
            steps {
                withAWS(credentials: 'aws', region: AWS_REGION) {
                    sh 'aws s3 cp webserver-deployment.zip s3://${S3_BUCKET_NAME}/webserver-deployment.zip'
                }
            }
        }
        stage('Deploy') {
            steps {
                withAWS(credentials: 'aws', region: AWS_REGION) {
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
        stage('Declarative: Post Actions') {
            steps {
                script {
                    sh 'mkdir -p jenkins/logs'
                    try {
                        archiveArtifacts artifacts: '**/build.log', allowEmptyArchive: true
                        withAWS(credentials: 'aws', region: AWS_REGION) {
                            sh 'aws s3 cp build.log s3://${S3_BUCKET_NAME}/jenkins-logs/${env.BUILD_NUMBER}.log'
                        }
                    } catch (Exception e) {
                        echo "Error: ${e.message}"
                    }
                }
            }
        }
    }
    post {
        always {
            echo 'Deployment finished!'
        }
        failure {
            echo 'Deployment failed!'
        }
    }
}
