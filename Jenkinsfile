pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        ECR_REGISTRY = '044014415078.dkr.ecr.us-east-1.amazonaws.com'
        ECR_REPOSITORY = 'devops-demo-app'
        IMAGE_TAG = "${BUILD_NUMBER}"
        IMAGE_URI = "${ECR_REGISTRY}/${ECR_REPOSITORY}:${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Test') {
            steps {
                sh 'python3 -m venv .venv'
                sh '.venv/bin/pip install -r app/requirements.txt'
                sh '.venv/bin/pip install pytest'
                sh '.venv/bin/python -m pytest app/tests'
            }
        }

        stage('Docker Build') {
            steps {
                sh 'docker build -t devops-demo-app:${BUILD_NUMBER} .'
            }
        }

        stage('Docker Run') {
            steps {
                sh 'docker rm -f devops-demo-container || true'
                sh 'docker run -d --name devops-demo-container -p 5001:5000 devops-demo-app:${BUILD_NUMBER}'
            }
        }

        stage('Health Check') {
            steps {
                sh 'sleep 5'
                sh 'curl -f http://localhost:5001/health'
            }
        }

        stage('ECR Login') {
            steps {
                sh '''
                    aws ecr get-login-password --region ${AWS_REGION} |
                    docker login --username AWS --password-stdin ${ECR_REGISTRY}
                '''
            }
        }

        stage('Docker Tag') {
            steps {
                sh '''
                    docker tag devops-demo-app:${BUILD_NUMBER} \
                    ${IMAGE_URI}
                '''
            }
        }

        stage('Push to ECR') {
            steps {
                sh 'docker push ${IMAGE_URI}'
            }
        }

        stage('Cleanup') {
            steps {
                sh 'docker rm -f devops-demo-container || true'
                sh 'docker image rm ${IMAGE_URI} || true'
            }
        }
    }
}
