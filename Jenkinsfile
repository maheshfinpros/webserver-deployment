pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        S3_BUCKET_NAME = 'mahesh-project-asg'
        APPLICATION_NAME = 'mahesh-jenkins'
        DEPLOYMENT_GROUP_NAME = 'mahesh-jenkins-DG'
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
                sh 'npm run build'
            }
        }

        stage('Package') {
            steps {
                sh 'zip -r webserver-deployment.zip Jenkinsfile README.md appspec.yml index1.html index2.html scripts/'
                archiveArtifacts artifacts: 'webserver-deployment.zip', allowEmptyArchive: true
            }
        }

        stage('Upload to S3') {
            steps {
                sh 'aws s3 cp webserver-deployment.zip s3://${S3_BUCKET_NAME}/webserver-deployment.zip'
            }
        }

        stage('Deploy') {
            steps {
                script {
                    sh """
                    aws deploy create-deployment \
                        --application-name ${APPLICATION_NAME} \
                        --deployment-group-name ${DEPLOYMENT_GROUP_NAME} \
                        --s3-location bucket=${S3_BUCKET_NAME},bundleType=zip,key=webserver-deployment.zip \
                        --region ${AWS_REGION} \
                        --role-arn arn:aws:iam::377850997170:role/aws-codedelpoy-ec2
                    """
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
                    sh 'aws s3 cp build.log s3://${S3_BUCKET_NAME}/jenkins-logs/${env.BUILD_NUMBER}.log'
                } catch (Exception e) {
                    echo "Error: ${e.message}"
                }
            }
        }
        failure {
            echo 'Deployment failed!'
        }
    }
}
