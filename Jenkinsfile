pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        ECR_REGISTRY = '044014415078.dkr.ecr.us-east-1.amazonaws.com'
        ECR_REPOSITORY = 'devops-demo-app'
        IMAGE_NAME = 'devops-demo-app'
        SONAR_PROJECT_KEY = 'devops-demo-app'
        K8S_NAMESPACE = 'devops'
        K8S_DEPLOYMENT = 'devops-demo-app'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Detect GitOps Commit') {
            steps {
                script {
                    def commitMessage = sh(script: 'git log -1 --pretty=%B', returnStdout: true).trim()
                    if (commitMessage.startsWith('[skip ci] Update application image to ')) {
                        currentBuild.result = 'NOT_BUILT'
                        error('Jenkins GitOps commit detected. Skipping CI pipeline.')
                    }
                }
            }
        }

        stage('Terraform Format Check') {
            steps {
                dir('terraform') {
                    sh 'terraform fmt -check'
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir('terraform') {
                    sh 'terraform init -input=false'
                    sh 'terraform validate'
                }
            }
        }

        stage('Unit Tests') {
            steps {
                sh 'python3 -m venv .ci-venv && .ci-venv/bin/pip install --upgrade pip && .ci-venv/bin/pip install -r app/requirements.txt pytest && .ci-venv/bin/pytest -v'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'sonar-scanner'

                    withSonarQubeEnv('sonarqube') {
                        sh """
                            ${scannerHome}/bin/sonar-scanner \
                              -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                              -Dsonar.projectName='DevOps Demo App' \
                              -Dsonar.sources=app \
                              -Dsonar.tests=app/tests \
                              -Dsonar.exclusions=app/tests/** \
                              -Dsonar.python.version=3.12 \
                              -Dsonar.sourceEncoding=UTF-8
                        """
                    }

                    timeout(time: 5, unit: 'MINUTES') {
                        waitForQualityGate abortPipeline: true
                    }
                }
            }
        }

        stage('Generate Image Tag') {
            steps {
                script {
                    def shortSha = sh(
                        script: 'git rev-parse --short=7 HEAD',
                        returnStdout: true
                    ).trim()

                    env.IMAGE_TAG = "build-${env.BUILD_NUMBER}-${shortSha}"
                    env.IMAGE_URI = "${env.ECR_REGISTRY}/${env.ECR_REPOSITORY}:${env.IMAGE_TAG}"

                    echo "Image tag: ${env.IMAGE_TAG}"
                    echo "Image URI: ${env.IMAGE_URI}"
                }
            }
        }

        stage('Docker Build') {
            steps {
                sh 'docker build -t ${IMAGE_URI} .'
            }
        }

        stage('Trivy Security Scan') {
            steps {
                sh '''
                    trivy image \
                      --severity CRITICAL \
                      --ignore-unfixed \
                      --exit-code 1 \
                      ${IMAGE_URI}
                '''
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

        stage('Push Image to ECR') {
            steps {
                sh 'docker push ${IMAGE_URI}'
            }
        }

        stage('Update Kubernetes Manifest') {
            steps {
                sh '''
                    sed -i -E \
                      "s#(image: .*/devops-demo-app:).*#\\1${IMAGE_TAG}#" \
                      k8s/deployment.yaml

                    grep 'image:' k8s/deployment.yaml
                '''
            }
        }

        stage('Commit and Push GitOps Change') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'github-credentials',
                        usernameVariable: 'GIT_USERNAME',
                        passwordVariable: 'GIT_PASSWORD'
                    )
                ]) {
                    sh '''
                        git config user.name "Jenkins CI"
                        git config user.email "jenkins@localhost"

                        git add k8s/deployment.yaml

                        git commit \
                          -m "[skip ci] Update application image to ${IMAGE_TAG}"

                        git -c credential.helper='!f() { echo username="$GIT_USERNAME"; echo password="$GIT_PASSWORD"; }; f' \
                          push origin HEAD:main
                    '''
                }
            }
        }

        stage('Wait for Argo CD Deployment') {
            steps {
                sh '''
                    echo "Waiting for Argo CD to deploy ${IMAGE_TAG}..."

                    kubectl rollout status \
                      deployment/${K8S_DEPLOYMENT} \
                      -n ${K8S_NAMESPACE} \
                      --timeout=5m
                '''
            }
        }

        stage('Application Health Check') {
            steps {
                sh '''
                    kubectl get pods -n ${K8S_NAMESPACE} -l app=${IMAGE_NAME}

                    kubectl rollout status \
                      deployment/${K8S_DEPLOYMENT} \
                      -n ${K8S_NAMESPACE} \
                      --timeout=2m

                    SERVICE_URL=$(kubectl get svc \
                      -n ${K8S_NAMESPACE} \
                      devops-demo-service \
                      -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

                    echo "Load Balancer: ${SERVICE_URL}"

                    test -n "${SERVICE_URL}"

                    curl -f \
                      --retry 10 \
                      --retry-delay 5 \
                      "http://${SERVICE_URL}/health"
                '''
            }
        }
    }

    post {
        always {
            sh 'docker image prune -f || true'
        }

        success {
            echo 'CI/CD pipeline completed successfully.'
        }

        failure {
            echo 'CI/CD pipeline failed. Deployment will not be considered successful.'
        }
    }
}
