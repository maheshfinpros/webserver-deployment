pipeline {
    agent any
    environment {
        PATH = "/usr/local/bin:${env.PATH}" // Ensure aws is in the PATH
    }
    stages {
        stage('Checkout') {
            steps {
                checkout([$class: 'GitSCM', branches: [[name: '*/main']],
                          userRemoteConfigs: [[url: 'https://github.com/maheshfinpros/webserver-deployment.git', credentialsId: 'github']]])
            }
        }
        stage('Upload to S3') {
            steps {
                withAWS(region: 'us-west-2', credentials: 'aws-credentials-id') {
                    sh 'aws s3 cp index1.html s3://mahesh-project-asg/index1.html'
                    sh 'aws s3 cp index2.html s3://mahesh-project-asg/index2.html'
                }
            }
        }
        stage('Deploy to EC2') {
            steps {
                withAWS(region: 'us-west-2', credentials: 'aws-credentials-id') {
                    script {
                        def activeDeployment = sh(script: 'aws deploy list-deployments --application-name mahesh-project-asg --deployment-group-name mahesh-project-Dg --deployment-status-filter InProgress', returnStdout: true).trim()
                        
                        if (activeDeployment) {
                            echo 'There is an active deployment. Waiting for it to complete...'
                            sleep(time: 300, unit: 'SECONDS') // Wait for 5 minutes (adjust as needed)
                            // Optionally, you could add logic here to wait until the deployment is done.
                        } else {
                            echo 'No active deployment found. Proceeding with new deployment...'
                            sh 'aws deploy create-deployment --application-name mahesh-project-asg --deployment-group-name mahesh-project-Dg --s3-location bucket=mahesh-project-asg,bundleType=zip,key=index1.html --file-exists-behavior OVERWRITE'
                            sh 'aws deploy create-deployment --application-name mahesh-project-asg --deployment-group-name mahesh-project-Dg --s3-location bucket=mahesh-project-asg,bundleType=zip,key=index2.html --file-exists-behavior OVERWRITE'
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
        failure {
            echo 'Deployment failed!'
        }
    }
}
