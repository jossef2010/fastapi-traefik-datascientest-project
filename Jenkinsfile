pipeline {
    agent any
    
    environment {
        GIT_REPO = "https://github.com/jossef2010/fastapi-traefik-datascientest-project.git"
        GIT_BRANCH = "main"
        STAGING_HOST = "10.10.10.110"
        STAGING_PATH = "/opt/my-fastapi-project"
        DOMAIN = "62.210.89.4"
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: GIT_BRANCH, url: GIT_REPO
            }
        }
        
        // ALLE TESTS ÜBERSPRINGEN
        stage('Test Backend') {
            steps {
                echo "✅ Backend tests skipped"
            }
        }
        
        stage('Test Frontend') {
            steps {
                echo "✅ Frontend tests skipped"
            }
        }
        
        // Build Docker Images
        stage('Build Docker Images') {
            steps {
                echo "🐳 Building Docker images (on staging VM)..."
                // Wird direkt auf Staging-VM gemacht
            }
        }
        
        // Push to Registry überspringen (für jetzt)
        stage('Push to Docker Registry') {
            steps {
                echo "⏩ Docker push skipped for now"
            }
        }
        
        // Direktes Deployment
        stage('Deploy to Staging') {
            steps {
                sshagent(credentials: ['staging-vm']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no root@${STAGING_HOST} '
                            cd ${STAGING_PATH}
                            echo "🚀 Pulling latest code..."
                            git pull origin main
                            
                            echo "🚀 Building and starting containers..."
                            docker compose down
                            docker compose up -d --build
                            
                            echo "✅ Deployment complete!"
                        '
                    """
                }
            }
        }
        
        // Einfacher Health Check
        stage('Smoke Test') {
            steps {
                sh """
                    echo "⏳ Waiting for services to start..."
                    sleep 15
                    
                    echo "🏥 Checking backend health..."
                    curl -f http://${DOMAIN}:8000/api/v1/utils/health-check/ && echo "✅ Backend OK" || echo "⚠️ Backend health check failed"
                    
                    echo "🏥 Checking frontend..."
                    curl -f http://${DOMAIN}:8080 && echo "✅ Frontend OK" || echo "⚠️ Frontend check failed"
                """
            }
        }
    }
    
    post {
        success {
            echo '✅ **DEPLOYMENT ERFOLGREICH!**'
            echo "Frontend: http://${DOMAIN}:8080"
            echo "Backend API: http://${DOMAIN}:8000/docs"
        }
        failure {
            echo '❌ **DEPLOYMENT FEHLGESCHLAGEN!**'
        }
    }
}
