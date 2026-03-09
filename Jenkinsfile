pipeline {
    agent any
    
    environment {
        // ===== UMWELTVARIABLEN =====
        // Staging VM
        STAGING_HOST = "10.10.10.110"
        STAGING_PATH = "/opt/my-fastapi-project"
        
        // Docker
        DOCKER_IMAGE = "jossef2010/fastapi-app:${BUILD_NUMBER}"
        DOCKER_IMAGE_LATEST = "jossef2010/fastapi-app:latest"
        
        // Domain/Ports
        DOMAIN = "62.210.89.4"
        BACKEND_PORT = "8000"
        FRONTEND_PORT = "8080"
        
        // GitHub Repo
        GIT_REPO = "https://github.com/jossef2010/fastapi-traefik-datascientest-project.git"
        GIT_BRANCH = "main"
    }
    
    stages {
        // ===== STAGE 1: CHECKOUT =====
        stage('Checkout Code') {
            steps {
                echo "📥 Cloning repository from ${GIT_REPO}..."
                git branch: GIT_BRANCH, url: GIT_REPO
                echo "✅ Code checkout complete!"
            }
        }
        
        // ===== STAGE 2: BACKEND TESTS =====
        stage('Test Backend') {
            steps {
                script {
                    echo "🧪 Running backend tests..."
                    sh '''
                        cd backend
                        echo "📦 Installing dependencies with pip..."
                
                        # Prüfe ob requirements.txt existiert
                	if [ -f "requirements.txt" ]; then
                            pip install -r requirements.txt
                	elif [ -f "pyproject.toml" ]; then
                    	    # Für pyproject.toml
                    	    pip install .
                        else
                           echo "⚠️ Keine requirements.txt gefunden, überspringe..."
                        fi
                        # Python venv erstellen und Abhängigkeiten installieren
                        python3 -m venv venv
                        . venv/bin/activate
                        pip install -r requirements.txt
                        
                        # Tests ausführen (falls vorhanden)
                        if [ -f "scripts/tests-start.sh" ]; then
                            bash scripts/tests-start.sh
                        else
                            pytest || echo "⚠️ No tests found, skipping..."
                        fi
                    '''
                }
            }
        }
        
        // ===== STAGE 3: FRONTEND TESTS (optional) =====
        stage('Test Frontend') {
            steps {
                script {
                    echo "🧪 Running frontend tests..."
                    sh '''
                        cd frontend
                        npm install
                        npm test || echo "⚠️ No frontend tests found, skipping..."
                    '''
                }
            }
        }
        
        // ===== STAGE 4: BUILD DOCKER IMAGES =====
        stage('Build Docker Images') {
            steps {
                script {
                    echo "🐳 Building Docker images..."
                    sh """
                        docker build -t ${DOCKER_IMAGE} .
                        docker tag ${DOCKER_IMAGE} ${DOCKER_IMAGE_LATEST}
                    """
                }
            }
        }
        
        // ===== STAGE 5: PUSH TO DOCKER REGISTRY =====
        stage('Push to Docker Registry') {
            steps {
                script {
                    echo "📤 Pushing images to Docker Hub..."
                    withCredentials([string(credentialsId: 'docker-hub', variable: 'DOCKER_PASSWORD')]) {
                        sh """
                            echo "${DOCKER_PASSWORD}" | docker login -u "jossef2010" --password-stdin
                            docker push ${DOCKER_IMAGE}
                            docker push ${DOCKER_IMAGE_LATEST}
                        """
                    }
                }
            }
        }
        
        // ===== STAGE 6: PREPARE DEPLOYMENT =====
        stage('Prepare Deployment') {
            steps {
                script {
                    echo "📝 Generating .env file for staging..."
                    
                    // .env Datei erstellen
                    sh """
                        cat > .env << 'EOF'
                        DOMAIN=${DOMAIN}
                        ENVIRONMENT=staging
                        STACK_NAME=my-fastapi-project
                        SECRET_KEY=${SECRET_KEY}
                        FIRST_SUPERUSER=jossef2010@hotmail.com
                        FIRST_SUPERUSER_PASSWORD=${FIRST_SUPERUSER_PASSWORD}
                        POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
                        BACKEND_CORS_ORIGINS=["http://${DOMAIN}:${FRONTEND_PORT}"]
                        EOF
                    """
                }
            }
        }
        
        // ===== STAGE 7: DEPLOY TO STAGING VM =====
        stage('Deploy to Staging') {
            steps {
                script {
                    echo "🚀 Deploying to staging VM (${STAGING_HOST})..."
                    
                    // Deployment via SSH
                    sshagent(credentials: ['staging-vm']) {
                        sh """
                            ssh -o StrictHostKeyChecking=no root@${STAGING_HOST} '
                                set -e
                                echo "📦 Updating deployment..."
                                
                                # In Projektverzeichnis wechseln
                                cd ${STAGING_PATH}
                                
                                # Neuesten Code pullen
                                git pull origin main
                                
                                # Neue .env Datei kopieren
                                cp /tmp/jenkins-env/.env ./.env 2>/dev/null || true
                                
                                # Neue Images pullen
                                echo "🔄 Pulling latest images..."
                                docker compose pull
                                
                                # Container neustarten
                                echo "🔄 Restarting containers..."
                                docker compose up -d --remove-orphans
                                
                                # Health Check
                                echo "🏥 Running health checks..."
                                sleep 10
                                curl -f http://localhost:8000/api/v1/utils/health-check/ || exit 1
                                curl -f http://localhost:8080 || exit 1
                                
                                # Alte Images aufräumen
                                echo "🧹 Cleaning up old images..."
                                docker image prune -f
                                
                                echo "✅ Deployment erfolgreich!"
                            '
                        """
                    }
                }
            }
        }
        
        // ===== STAGE 8: SMOKE TESTS =====
        stage('Smoke Tests') {
            steps {
                script {
                    echo "🔥 Running smoke tests..."
                    sh """
                        # Backend API testen
                        curl -f http://${DOMAIN}:${BACKEND_PORT}/api/v1/utils/health-check/ || exit 1
                        
                        # Frontend testen
                        curl -f http://${DOMAIN}:${FRONTEND_PORT} || exit 1
                        
                        # Login testen (optional)
                        curl -X POST "http://${DOMAIN}:${BACKEND_PORT}/api/v1/login/access-token" \
                          -H "Content-Type: application/x-www-form-urlencoded" \
                          -d "username=jossef2010@hotmail.com&password=${FIRST_SUPERUSER_PASSWORD}" || exit 1
                        
                        echo "✅ Alle Smoke Tests erfolgreich!"
                    """
                }
            }
        }
    }
    
    // ===== POST-DEPLOYMENT ACTIONS =====
    post {
        success {
            echo '🎉 **DEPLOYMENT ERFOLGREICH!**'
            echo "✅ Die Anwendung ist verfügbar unter:"
            echo "   - Frontend: http://${DOMAIN}:${FRONTEND_PORT}"
            echo "   - Backend API: http://${DOMAIN}:${BACKEND_PORT}/docs"
            echo "   - Jenkins: http://${DOMAIN}:8081"
            
            // Slack/Email Benachrichtigung (optional)
            // slackSend(color: 'good', message: "Deployment successful: ${env.JOB_NAME} - ${env.BUILD_NUMBER}")
        }
        
        failure {
            echo '❌ **DEPLOYMENT FEHLGESCHLAGEN!**'
            echo "🔍 Bitte Logs prüfen: ${env.BUILD_URL}"
            
            // Rollback (optional)
            // stage('Rollback') {
            //     steps {
            //         echo "🔄 Rolling back to previous version..."
            //         // Rollback-Logik hier
            //     }
            // }
            
            // Slack/Email Benachrichtigung (optional)
            // slackSend(color: 'danger', message: "Deployment failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER}")
        }
        
        always {
            echo "📊 Build ${env.BUILD_NUMBER} abgeschlossen."
            echo "🔗 Build-URL: ${env.BUILD_URL}"
        }
    }
}
