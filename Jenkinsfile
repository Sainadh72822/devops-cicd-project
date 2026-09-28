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
            sh 'python3 -m venv .venv'
            sh '.venv/bin/pip install -r app/requirements.txt'
            sh '.venv/bin/pip install pytest'
            sh '.venv/bin/python -m pytest app/tests'
        }
    }

    stage('Docker Build') {
        steps {
            sh 'docker build -t devops-demo-app:jenkins .'
        }
    }
}

}
