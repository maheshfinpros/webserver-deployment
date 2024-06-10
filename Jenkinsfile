pipeline {
    agent any
    
    environment {
        AWS_REGION = 'ap-south-1'
        S3_BUCKET = 'mahesh-project-asg'
        DEPLOYMENT_GROUP = 'mahesh-jenkins-DG'
        APPLICATION_NAME = 'mahesh-jenkins'
    }
    
    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }
        
        stage('Create package.json') {
            steps {
                script {
                    writeFile file: 'package.json', text: '''{
                        "name": "mahesh-project",
                        "version": "1.0.0",
                        "scripts": {
                            "build": "echo Build process completed successfully"
                        },
                        "dependencies": {}
                    }'''
                }
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
                echo 'Packaging the project...'
                sh 'zip -r webserver-deployment.zip Jenkinsfile README.md appspec.yml index1.html index2.html scripts/ webpack.config.js package.json package-lock.json'
                archiveArtifacts artifacts: 'webserver-deployment.zip', fingerprint: true
            }
        }
        
        stage('Upload to S3') {
            steps {
                echo 'Uploading to S3...'
                sh "aws s3 cp webserver-deployment.zip s3://${S3_BUCKET}/webserver-deployment.zip --region ${AWS_REGION}"
            }
        }
        
        stage('Deploy') {
            steps {
                echo 'Deploying the application...'
                script {
                    def deployCommand = """
                        aws deploy create-deployment --application-name ${APPLICATION_NAME} \
                        --deployment-group-name ${DEPLOYMENT_GROUP} \
                        --s3-location bucket=${S3_BUCKET},bundleType=zip,key=webserver-deployment.zip \
                        --region ${AWS_REGION}
                    """
                    def deployOutput = sh(script: deployCommand, returnStdout: true).trim()
                    echo "Deployment Output: ${deployOutput}"
                }
            }
        }
        
        stage('Get Instance Details') {
            steps {
                echo 'Getting instance details...'
                script {
                    def instanceDetails = sh(script: """
                        aws ec2 describe-instances --filters Name=instance-state-name,Values=running \
                        --query 'Reservations[*].Instances[*].[InstanceId,PrivateIpAddress]' \
                        --output text --region ${AWS_REGION}
                    """, returnStdout: true).trim()
                    echo "Instance Details: ${instanceDetails}"
                }
            }
        }
        
        stage('Run Commands on Instances') {
            steps {
                echo 'Running commands on instances...'
                script {
                    def instanceIps = ['10.0.1.67', '10.0.0.57', '172.31.43.149']
                    for (ip in instanceIps) {
                        sshagent(['ubuntu']) {
                            sh "echo Attempting SSH connection to ${ip}"
                            def commands = [
                                "cd /var/www/html && ls -l",
                                "cd /home/ubuntu && ls -l"
                            ]
                            for (cmd in commands) {
                                sh "ssh -o StrictHostKeyChecking=no ubuntu@${ip} ${cmd}"
                            }
                        }
                    }
                }
            }
        }
    }
    
    post {
        always {
            echo 'Performing post-build actions...'
            sh 'mkdir -p jenkins/logs'
            archiveArtifacts artifacts: 'jenkins/logs/*.log', fingerprint: true
            script {
                def logFile = 'build.log'
                if (fileExists(logFile)) {
                    sh "aws s3 cp ${logFile} s3://${S3_BUCKET}/jenkins-logs/121.log --region ${AWS_REGION}"
                } else {
                    echo "Error: ${logFile} does not exist."
                }
            }
        }
        failure {
            echo 'Deployment failed!'
        }
    }
}
