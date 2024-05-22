pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'your-aws-region'
        S3_BUCKET = 'your-s3-bucket-name'
        APPLICATION_NAME = 'WebApp'
        DEPLOYMENT_GROUP_NAME = 'WebAppDeploymentGroup'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/your-repo/your-app.git'
            }
        }
        stage('Build') {
            steps {
                withAWS(credentials: 'your-aws-credentials-id') {
                    script {
                        def buildCommand = """
                            aws codebuild start-build --project-name WebAppBuild
                        """
                        def buildOutput = sh(script: buildCommand, returnStdout: true).trim()
                        echo "Build output: ${buildOutput}"
                    }
                }
            }
        }
        stage('Upload to S3') {
            steps {
                withAWS(credentials: 'your-aws-credentials-id') {
                    sh '''
                        aws s3 cp ./appspec.yml s3://$S3_BUCKET/appspec.yml
                        aws s3 cp ./your-artifact.zip s3://$S3_BUCKET/your-artifact.zip
                    '''
                }
            }
        }
        stage('Deploy') {
            steps {
                withAWS(credentials: 'your-aws-credentials-id') {
                    script {
                        def deployCommand = """
                            aws deploy create-deployment \
                                --application-name $APPLICATION_NAME \
                                --deployment-group-name $DEPLOYMENT_GROUP_NAME \
                                --s3-location bucket=$S3_BUCKET,bundleType=zip,key=your-artifact.zip
                        """
                        def deployOutput = sh(script: deployCommand, returnStdout: true).trim()
                        echo "Deploy output: ${deployOutput}"
                    }
                }
            }
        }
    }
    post {
        success {
            echo 'Deployment was successful!'
        }
        failure {
            echo 'Deployment failed!'
        }
    }
}
