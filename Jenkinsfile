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
                script {
                    checkout([$class: 'GitSCM',
                              branches: [[name: '*/main']],
                              userRemoteConfigs: [[url: 'https://github.com/maheshfinpros/webserver-deployment.git']],
                              extensions: [[$class: 'CleanBeforeCheckout'],
                                           [$class: 'CloneOption', noTags: false, shallow: true, depth: 1]]])
                }
            }
        }
        stage('Build') {
            steps {
                script {
                    sh 'zip -r webserver-deployment.zip Jenkinsfile README.md appspec.yml index1.html index2.html'
                }
            }
        }
        stage('Upload to S3') {
            steps {
                script {
                    withAWS(region: AWS_REGION, credentials: AWS_CREDENTIALS_ID) {
                        s3Upload(bucket: S3_BUCKET_NAME, path: 'webserver-deployment.zip', file: 'webserver-deployment.zip')
                    }
                }
            }
        }
        stage('Deploy') {
            steps {
                script {
                    withAWS(region: AWS_REGION, credentials: AWS_CREDENTIALS_ID) {
                        def deployment = awsCodeDeploy application: APPLICATION_NAME,
                                                        deploymentGroup: DEPLOYMENT_GROUP_NAME,
                                                        s3Location: [bucket: S3_BUCKET_NAME, key: 'webserver-deployment.zip', bundleType: 'zip']
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                try {
                    archiveArtifacts artifacts: '**/*.log', allowEmptyArchive: true
                    withAWS(region: AWS_REGION, credentials: AWS_CREDENTIALS_ID) {
                        s3Upload(bucket: S3_BUCKET_NAME, path: "jenkins-logs/${env.BUILD_NUMBER}.log", file: "${env.BUILD_NUMBER}.log")
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
