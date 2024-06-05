pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'  // Mumbai region
        AWS_ACCOUNT_ID = '377850997170'
        ROLE_ARN = 'arn:aws:iam::377850997170:role/aws-codedelpoy-ec2'
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
            }
        }

        stage('Assume IAM Role') {
            steps {
                script {
                    def assumeRoleCmd = "aws sts assume-role --role-arn ${ROLE_ARN} --role-session-name jenkinsSession --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' --output text"
                    def creds = sh(script: assumeRoleCmd, returnStdout: true).trim().split()
                    env.AWS_ACCESS_KEY_ID = creds[0]
                    env.AWS_SECRET_ACCESS_KEY = creds[1]
                    env.AWS_SESSION_TOKEN = creds[2]
                }
            }
        }

        stage('Package') {
            when {
                expression { return currentBuild.resultIsBetterOrEqualTo('SUCCESS') }
            }
            steps {
                echo 'Packaging the project...'
                // Add your packaging commands here
            }
        }

        stage('Upload to S3') {
            when {
                expression { return currentBuild.resultIsBetterOrEqualTo('SUCCESS') }
            }
            steps {
                echo 'Uploading to S3...'
                // Add your S3 upload commands here
            }
        }

        stage('Deploy') {
            when {
                expression { return currentBuild.resultIsBetterOrEqualTo('SUCCESS') }
            }
            steps {
                echo 'Deploying...'
                // Add your deployment commands here
            }
        }

        stage('Get Instance Details') {
            when {
                expression { return currentBuild.resultIsBetterOrEqualTo('SUCCESS') }
            }
            steps {
                echo 'Getting instance details...'
                // Add your commands to get instance details here
            }
        }

        stage('Run Commands on Instances') {
            when {
                expression { return currentBuild.resultIsBetterOrEqualTo('SUCCESS') }
            }
            steps {
                echo 'Running commands on instances...'
                // Add your commands to run on instances here
            }
        }
    }

    post {
        always {
            echo 'Deployment finished!'
            archiveArtifacts artifacts: '**/target/*.jar', allowEmptyArchive: true
        }
    }
}
