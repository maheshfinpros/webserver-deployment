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
        COMMANDS = "ls -l; pwd" // Example commands
        DIRECTORIES = "/var/www/html /home/ubuntu" // Example directories
    }

    stages {
        stage('Create package.json') {
            steps {
                script {
                    writeFile file: 'package.json', text: '''
                    {
                      "scripts": {
                        "start": "node index.js",
                        "test": "echo \\"Error: no test specified\\" && exit 1",
                        "build": "echo \\"Build process completed successfully\\""
                      }
                    }
                    '''
                }
            }
        }
        stage('Checkout') {
            steps {
                echo 'Checking out the code...'
                checkout scm
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
                archiveArtifacts artifacts: 'webserver-deployment.zip', allowEmptyArchive: true
            }
        }
        stage('Upload to S3') {
            steps {
                echo 'Uploading to S3...'
                sh "aws s3 cp webserver-deployment.zip s3://${S3_BUCKET_NAME}/webserver-deployment.zip --region ${AWS_REGION}"
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying the application...'
                sh """
                aws deploy create-deployment \
                    --application-name ${APPLICATION_NAME} \
                    --deployment-group-name ${DEPLOYMENT_GROUP_NAME} \
                    --s3-location bucket=${S3_BUCKET_NAME},bundleType=zip,key=webserver-deployment.zip \
                    --region ${AWS_REGION}
                """
            }
        }
        stage('Get Instance Details') {
            steps {
                echo 'Getting instance details...'
                script {
                    def instances = sh(script: "aws ec2 describe-instances --filters 'Name=instance-state-name,Values=running' --query 'Reservations[*].Instances[*].[InstanceId,PrivateIpAddress]' --output text", returnStdout: true).trim()
                    env.INSTANCE_DETAILS = instances
                    echo "Instance Details: ${env.INSTANCE_DETAILS}"
                }
            }
        }
        stage('Run Commands on Instances') {
            steps {
                echo 'Running commands on instances...'
                script {
                    def instanceDetails = env.INSTANCE_DETAILS.split('\n')
                    def commandsList = env.COMMANDS.split(';')
                    def directories = env.DIRECTORIES.split(' ')

                    instanceDetails.each { detail ->
                        def parts = detail.split('\\s+')
                        def instanceId = parts[0]
                        def privateIp = parts[1]

                        directories.each { dir ->
                            commandsList.each { cmd ->
                                sshagent(credentials: [SSH_CREDENTIALS_ID]) {
                                    sh """
                                    echo "Attempting SSH connection to ${privateIp} (${instanceId})"
                                    ssh -o StrictHostKeyChecking=no ${SSH_USERNAME}@${privateIp} 'cd ${dir} && ${cmd}'
                                    """
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    post {
        always {
            script {
                echo 'Performing post-build actions...'
                sh 'mkdir -p jenkins/logs'
                try {
                    archiveArtifacts artifacts: '**/build.log', allowEmptyArchive: true
                    sh "aws s3 cp build.log s3://${S3_BUCKET_NAME}/jenkins-logs/${env.BUILD_NUMBER}.log --region ${AWS_REGION}"
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
