pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins

  volumes:
  - name: workspace-volume
    emptyDir: {}
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock

  containers:
  - name: jnlp
    image: jenkins/inbound-agent:latest
    args: ['\$(JENKINS_SECRET)', '\$(JENKINS_NAME)']
    volumeMounts:
    - name: workspace-volume
      mountPath: /home/jenkins/agent

  - name: tools
    image: pradeepreddyhub/jenkins-image:v1
    command: ['cat']
    tty: true
    volumeMounts:
    - name: workspace-volume
      mountPath: /home/jenkins/agent
    - name: docker-sock
      mountPath: /var/run/docker.sock
"""
        }
    }

    environment {
        DOCKER_IMAGE = "docker.io/pradeepreddyhub/hello-world"
        IMAGE_TAG    = "${BUILD_NUMBER}"
        HELM_CHART   = "hello-world"
        HELM_VERSION = "0.2.0"
        JFROG_URL    = "https://trial3sfswa.jfrog.io/artifactory/jenkins-helm"
        KUBE_NS      = "default"

        DOCKER_CREDS = credentials('dockerhub-creds')
        JFROG_CREDS  = credentials('jfrog-creds')
    }

    stages {

        stage('Checkout') {
            steps {
                container('tools') {
                    git branch: 'main', url: 'https://github.com/pradeepreddy-hub/Jenkins_docker_hello-world-war.git'
                }
            }
        }

        stage('Docker Build & Push') {
            steps {
                container('tools') {
                    sh """
                    docker build -t $DOCKER_IMAGE:$IMAGE_TAG .
                    echo $DOCKER_CREDS_PSW | docker login -u $DOCKER_CREDS_USR --password-stdin
                    docker push $DOCKER_IMAGE:$IMAGE_TAG

                    docker tag $DOCKER_IMAGE:$IMAGE_TAG $DOCKER_IMAGE:latest
                    docker push $DOCKER_IMAGE:latest
                    """
                }
            }
        }

        stage('Helm Package & Push') {
            steps {
                container('tools') {
                    sh """
                    helm lint $HELM_CHART
                    helm package $HELM_CHART

                    curl -u $JFROG_CREDS_USR:$JFROG_CREDS_PSW \
                      -T ${HELM_CHART}-${HELM_VERSION}.tgz \
                      ${JFROG_URL}/${HELM_CHART}-${HELM_VERSION}.tgz

                    helm repo index . --url ${JFROG_URL}

                    curl -u $JFROG_CREDS_USR:$JFROG_CREDS_PSW \
                      -T index.yaml \
                      ${JFROG_URL}/index.yaml
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                container('tools') {
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
                      --wait --timeout 2m
                    """
                }
            }
        }

        stage('Verify') {
            steps {
                container('tools') {
                    sh """
                    kubectl rollout status deployment/$HELM_CHART -n $KUBE_NS
                    kubectl get pods -n $KUBE_NS
                    kubectl get svc -n $KUBE_NS
                    """
                }
            }
        }
    }

    post {
        success {
            echo "SUCCESS 🚀"
        }
        failure {
            echo "FAILED ❌"
        }
    }
}
