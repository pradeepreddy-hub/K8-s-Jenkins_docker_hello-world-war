pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins
  containers:
  - name: jnlp
    image: jenkins/inbound-agent:latest
    args: ["$(JENKINS_SECRET)", "$(JENKINS_NAME)"]

  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug
    command: ["/busybox/cat"]
    tty: true

  - name: tools
    image: dtzar/helm-kubectl:latest
    command: ["cat"]
    tty: true
'''
        }
    }

    environment {
        DOCKER_IMAGE = "docker.io/pradeepreddyhub/hello-world"
        IMAGE_TAG    = "${BUILD_NUMBER}"

        HELM_CHART   = "hello-world"
        HELM_VERSION = "0.2.0"

        JFROG_PLATFORM = "https://trial3sfswa.jfrog.io"
        JFROG_REPO     = "jenkins-helm"

        BUILD_NAME   = "hello-world-war"
        BUILD_NUMBER = "${BUILD_NUMBER}"

        JFROG_CREDS  = credentials('jfrog-creds')
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                url: 'https://github.com/pradeepreddy-hub/Jenkins_docker_hello-world-war.git'
            }
        }

        stage('Build & Push Image') {
            steps {
                container('kaniko') {
                    sh '''
                    /kaniko/executor \
                      --dockerfile=Dockerfile \
                      --context=/home/jenkins/agent/workspace/hello-world-war \
                      --destination=$DOCKER_IMAGE:$IMAGE_TAG \
                      --destination=$DOCKER_IMAGE:latest \
                      --skip-tls-verify
                    '''
                }
            }
        }

        stage('Helm Package & Push (JFrog Build Info)') {
            steps {
                container('tools') {
                    sh '''
                    # Install JFrog CLI
                    curl -fL https://getcli.jfrog.io | sh
                    mv jfrog /usr/local/bin/

                    # Configure JFrog
                    jfrog config add artifactory-server \
                      --url=$JFROG_PLATFORM \
                      --user=$JFROG_CREDS_USR \
                      --password=$JFROG_CREDS_PSW \
                      --interactive=false

                    # Package Helm
                    helm lint $HELM_CHART
                    helm package $HELM_CHART

                    # Upload Helm chart with build info
                    jfrog rt u "${HELM_CHART}-${HELM_VERSION}.tgz" $JFROG_REPO/ \
                      --build-name=$BUILD_NAME \
                      --build-number=$BUILD_NUMBER

                    # Upload index.yaml
                    helm repo index . --url ${JFROG_PLATFORM}/artifactory/${JFROG_REPO}

                    jfrog rt u "index.yaml" $JFROG_REPO/ \
                      --build-name=$BUILD_NAME \
                      --build-number=$BUILD_NUMBER

                    # Publish build info
                    jfrog rt bp $BUILD_NAME $BUILD_NUMBER
                    '''
                }
            }
        }
    }

    post {
        success { echo "SUCCESS 🚀" }
        failure { echo "FAILED ❌" }
    }
}
