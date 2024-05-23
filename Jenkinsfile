pipeline {
    agent any

    environment {
        S3_BUCKET = 'mahesh-project-asg'
        APPLICATION_NAME = 'mahesh-jenkins'
        DEPLOYMENT_GROUP_NAME = 'mahesh-jenkins-DG'
        AWS_REGION = 'ap-south-1'
        AWS_CREDENTIALS_ID = 'aws-access'
        GIT_CREDENTIALS_ID = 'github'
        GIT_REPO = 'https://github.com/maheshfinpros/webserver-deployment.git'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', credentialsId: "${GIT_CREDENTIALS_ID}", url: "${GIT_REPO}"
            }
        }

        stage('Build') {
            steps {
                script {
                    withAWS(credentials: "${AWS_CREDENTIALS_ID}", region: "${AWS_REGION}") {
                        sh 'zip -r webserver-deployment.zip *'
                        s3Upload(bucket: "${S3_BUCKET}", path: "webserver-deployment.zip", file: "webserver-deployment.zip")
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    withAWS(credentials: "${AWS_CREDENTIALS_ID}", region: "${AWS_REGION}") {
                        sh """
                        aws deploy create-deployment \
                            --application-name ${APPLICATION_NAME} \
                            --deployment-group-name ${DEPLOYMENT_GROUP_NAME} \
                            --s3-location bucket=${S3_BUCKET},bundleType=zip,key=webserver-deployment.zip
                        """
                    }
                }
            }
        }

        stage('Post-Deployment') {
            steps {
                echo 'Deployment completed successfully!'
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'webserver-deployment.zip', allowEmptyArchive: true
            script {
                withAWS(credentials: "${AWS_CREDENTIALS_ID}", region: "${AWS_REGION}") {
                    s3Upload(bucket: "${S3_BUCKET}", path: "jenkins-logs/${BUILD_NUMBER}.log", file: "jenkins/logs/${BUILD_NUMBER}.log")
                }
            }
        }
        failure {
            echo 'Deployment failed!'
        }
    }
}
