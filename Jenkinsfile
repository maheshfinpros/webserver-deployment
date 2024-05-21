pipeline {
    agent any
    environment {
        S3_BUCKET = 'mahesh-project-asg'
        CODEDEPLOY_APP = 'mahesh-project-asg'
        CODEDEPLOY_GROUP = 'mahesh-project-Dg'
        REPO_URL = 'https://github.com/maheshfinpros/webserver-deployment.git'
        GITHUB_CREDENTIALS_ID = 'github'
        AWS_CREDENTIALS_ID = 'aws-access'
    }
    stages {
        stage('Checkout') {
            steps {
                script {
                    checkout([$class: 'GitSCM', 
                              branches: [[name: '*/main']], 
                              doGenerateSubmoduleConfigurations: false, 
                              extensions: [], 
                              submoduleCfg: [], 
                              userRemoteConfigs: [[credentialsId: GITHUB_CREDENTIALS_ID, url: REPO_URL]]])
                }
            }
        }
        stage('Upload to S3') {
            steps {
                withAWS(credentials: AWS_CREDENTIALS_ID) {
                    sh 'aws s3 cp index1.html s3://${S3_BUCKET}/index1.html'
                    sh 'aws s3 cp index2.html s3://${S3_BUCKET}/index2.html'
                }
            }
        }
        stage('Deploy to EC2') {
            steps {
                withAWS(credentials: AWS_CREDENTIALS_ID) {
                    sh '''
                    aws deploy create-deployment \
                        --application-name ${CODEDEPLOY_APP} \
                        --deployment-group-name ${CODEDEPLOY_GROUP} \
                        --s3-location bucket=${S3_BUCKET},bundleType=zip,key=index1.html \
                        --file-exists-behavior OVERWRITE
                    aws deploy create-deployment \
                        --application-name ${CODEDEPLOY_APP} \
                        --deployment-group-name ${CODEDEPLOY_GROUP} \
                        --s3-location bucket=${S3_BUCKET},bundleType=zip,key=index2.html \
                        --file-exists-behavior OVERWRITE
                    '''
                }
            }
        }
    }
    post {
        success {
            echo 'Deployment successful!'
        }
        failure {
            echo 'Deployment failed!'
        }
    }
}
