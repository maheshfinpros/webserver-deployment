pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        AWS_CREDENTIALS_ID = 'aws-access'
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
                script {
                    echo 'Building the project...'
                    // Add your build commands here
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
    }
    post {
        always {
            script {
                sh 'mkdir -p jenkins/logs'
                try {
                    archiveArtifacts artifacts: '**/target/*.log', allowEmptyArchive: true
                    withAWS(credentials: "${AWS_CREDENTIALS_ID}", region: "${AWS_REGION}") {
                        s3Upload(bucket: "${S3_BUCKET_NAME}", path: "jenkins-logs/${env.BUILD_NUMBER}.log", file: "jenkins/logs/${env.BUILD_NUMBER}.log")
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
