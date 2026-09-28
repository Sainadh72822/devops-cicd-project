pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Test') {
            steps {
                sh 'python3 -m pytest app/tests'
            }
        }

        stage('Docker Build') {
            steps {
                sh 'docker build -t devops-demo-app:jenkins .'
            }
        }
    }
}