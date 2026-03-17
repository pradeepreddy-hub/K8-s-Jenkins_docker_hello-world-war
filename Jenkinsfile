pipeline {
    agent any

    environment {
        DOCKER_IMAGE  = "docker.io/pradeepreddyhub/hello-world:latest"
        IMAGE_TAG     = "${BUILD_NUMBER}"
        HELM_CHART    = "hello-world"
        HELM_VERSION  = "0.1.0"
        JFROG_URL     = "https://trial3sfswa.jfrog.io/artifactory/jenkins-helm"
        KUBE_NS       = "default"
        DOCKER_CREDS  = credentials('dockerhub-creds')
        JFROG_CREDS   = credentials('jfrog-creds')
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/pradeepreddy-hub/Jenkins_docker_hello-world-war.git'
            }
        }

        stage('Maven Build') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Docker Build') {
            steps {
                sh "docker build -t $DOCKER_IMAGE:$IMAGE_TAG ."
            }
        }

        stage('Docker Push') {
            steps {
                sh """
                echo $DOCKER_CREDS_PSW | docker login -u $DOCKER_CREDS_USR --password-stdin
                docker push $DOCKER_IMAGE:$IMAGE_TAG
                docker tag  $DOCKER_IMAGE:$IMAGE_TAG $DOCKER_IMAGE:latest
                docker push $DOCKER_IMAGE:latest
                """
            }
        }

        stage('Helm Package') {
            steps {
                sh """
                helm lint $HELM_CHART
                helm package $HELM_CHART
                """
            }
        }

        stage('Push Helm Chart to JFrog') {
            steps {
                sh """
                curl -u $JFROG_CREDS_USR:$JFROG_CREDS_PSW \
                  -T ${HELM_CHART}-${HELM_VERSION}.tgz \
                  ${JFROG_URL}/${HELM_CHART}-${HELM_VERSION}.tgz
                """
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh """
                helm repo add jfrog-helm ${JFROG_URL} \
                  --username $JFROG_CREDS_USR \
                  --password $JFROG_CREDS_PSW \
                  --force-update

                helm repo update

                helm upgrade --install $HELM_CHART jfrog-helm/$HELM_CHART \
                  --version $HELM_VERSION \
                  --set image.tag=$IMAGE_TAG \
                  --namespace $KUBE_NS \
                  --wait \
                  --timeout 2m
                """
            }
        }

        stage('Verify Deployment') {
            steps {
                sh """
                kubectl rollout status deployment/$HELM_CHART \
                  --namespace $KUBE_NS \
                  --timeout=120s

                echo "Pods running:"
                kubectl get pods -n $KUBE_NS -l app=$HELM_CHART

                echo "Service:"
                kubectl get svc $HELM_CHART -n $KUBE_NS
                """
            }
        }
    }

    post {
        success {
            echo "Deployment SUCCESS — http://<NODE-IP>:30080"
        }
        failure {
            echo "Pipeline FAILED — check logs above"
        }
        always {
            sh "docker rmi $DOCKER_IMAGE:$IMAGE_TAG || true"
        }
    }
}
