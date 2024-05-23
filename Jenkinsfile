def deployAPI(Map params) {
    // Your deployment logic here
    // Example: AWS CodeDeploy deployment
    def codeDeploy = new AWSCodeDeploy()
    codeDeploy.deployApplication(params)
}

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
                withAWS(credentials: "${AWS_CREDENTIALS_ID}", region: "${AWS_REGION}") {
                    sh 'zip -r webserver-deployment.zip Jenkinsfile README.md appspec.yml index1.html index2.html > build.log 2>&1'
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
                        deployAPI([
                            applicationName: "${APPLICATION_NAME}",
                            deploymentGroupName: "${DEPLOYMENT_GROUP_NAME}",
                            revision: [
                                revisionType: 'S3',
                                s3Location: [
                                    bucket: "${S3_BUCKET_NAME}",
                                    key: "webserver-deployment.zip",
                                    bundleType: 'zip'
                                ]
                            ]
                        ])
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
