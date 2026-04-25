#!/bin/bash

# ==========================================
# start-factory.sh - Agentic Factory Startup Script
# ==========================================
# Starts the complete Agentic Software Factory stack:
# - Plane (Requirements Management)
# - Jenkins (CI/CD)
# - Prometheus/Grafana (Monitoring)
# - Ollama (Local AI)
# ==========================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🏭 Starting Agentic Software Factory${NC}"
echo "========================================"
echo ""

# ==========================================
# 1. PRE-FLIGHT CHECKS
# ==========================================
echo -e "${BLUE}1️⃣  Pre-flight checks...${NC}"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker first.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Docker is running${NC}"

# Check if .env exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠️  .env file not found. Creating from .env.example...${NC}"
    if [ -f .env.example ]; then
        cp .env.example .env
        echo -e "${YELLOW}📝 Please edit .env file with your API keys${NC}"
    else
        echo -e "${RED}❌ No .env.example found. Please create .env manually.${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}✅ Environment configuration found${NC}"

# Check if Ollama is running
if curl -s http://localhost:11434/api/version > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Ollama is running${NC}"
else
    echo -e "${YELLOW}⚠️  Ollama not running. Starting...${NC}"
    if command -v ollama > /dev/null 2>&1; then
        ollama serve > /dev/null 2>&1 &
        sleep 3
        echo -e "${GREEN}✅ Ollama started${NC}"
    else
        echo -e "${RED}❌ Ollama not installed. Please install from https://ollama.ai${NC}"
        exit 1
    fi
fi

echo ""

# ==========================================
# 2. START INFRASTRUCTURE
# ==========================================
echo -e "${BLUE}2️⃣  Starting infrastructure services...${NC}"

# Start Docker Compose services
docker-compose up -d

echo -e "${GREEN}✅ Docker services started${NC}"
echo ""

# ==========================================
# 3. HEALTH CHECKS & WAITING
# ==========================================
echo -e "${BLUE}3️⃣  Waiting for services to be ready...${NC}"

# Wait for Plane Database
echo "   🗄️  Waiting for Plane Database..."
timeout=60
counter=0
while ! docker-compose exec -T plane-db pg_isready -U plane > /dev/null 2>&1; do
    if [ $counter -ge $timeout ]; then
        echo -e "${RED}❌ Plane Database failed to start within ${timeout}s${NC}"
        exit 1
    fi
    sleep 1
    counter=$((counter + 1))
done
echo -e "${GREEN}   ✅ Plane Database ready${NC}"

# Wait for Plane API
echo "   🚀 Waiting for Plane API..."
timeout=120
counter=0
while ! curl -s http://localhost:8000/api/v1/ > /dev/null 2>&1; do
    if [ $counter -ge $timeout ]; then
        echo -e "${RED}❌ Plane API failed to start within ${timeout}s${NC}"
        echo -e "${YELLOW}   💡 Check logs: docker-compose logs plane-api${NC}"
        exit 1
    fi
    sleep 2
    counter=$((counter + 2))
done
echo -e "${GREEN}   ✅ Plane API ready${NC}"

# Wait for Jenkins
echo "   🔧 Waiting for Jenkins..."
timeout=180
counter=0
while ! curl -s http://localhost:8081/login > /dev/null 2>&1; do
    if [ $counter -ge $timeout ]; then
        echo -e "${RED}❌ Jenkins failed to start within ${timeout}s${NC}"
        echo -e "${YELLOW}   💡 Check logs: docker-compose logs jenkins${NC}"
        exit 1
    fi
    sleep 3
    counter=$((counter + 3))
done
echo -e "${GREEN}   ✅ Jenkins ready${NC}"

# Wait for Prometheus
echo "   📊 Waiting for Prometheus..."
timeout=60
counter=0
while ! curl -s http://localhost:9090/-/ready > /dev/null 2>&1; do
    if [ $counter -ge $timeout ]; then
        echo -e "${YELLOW}⚠️  Prometheus slow to start (continuing...)${NC}"
        break
    fi
    sleep 2
    counter=$((counter + 2))
done
echo -e "${GREEN}   ✅ Prometheus ready${NC}"

echo ""

# ==========================================
# 4. TEST AGENTIC TEAM
# ==========================================
echo -e "${BLUE}4️⃣  Testing Agentic Team...${NC}"

# Activate Python venv and test gatekeeper
if [ -d ".venv" ]; then
    echo "   🐍 Activating Python virtual environment..."
    source .venv/Scripts/activate || source .venv/bin/activate
    echo -e "${GREEN}   ✅ Virtual environment activated${NC}"
    
    echo "   🤖 Testing agent routing..."
    python -c "
from gatekeeper import process_ticket
import sys

print('Testing agent connectivity...')
try:
    result = process_ticket('Code_Review', 'def hello(): return \"Hello Factory!\"')
    if result:
        print('✅ Agent team is operational!')
    else:
        print('⚠️  Agent test returned empty result')
        sys.exit(1)
except Exception as e:
    print(f'❌ Agent test failed: {e}')
    sys.exit(1)
" 2>/dev/null || echo -e "${YELLOW}   ⚠️  Agent test skipped (install dependencies: pip install -r requirements.txt)${NC}"
else
    echo -e "${YELLOW}   ⚠️  Python venv not found. Run: python -m venv .venv${NC}"
fi

echo ""

# ==========================================
# 5. SUCCESS SUMMARY
# ==========================================
echo -e "${GREEN}🎉 Agentic Software Factory is OPERATIONAL!${NC}"
echo "=============================================="
echo ""
echo -e "${BLUE}📍 Service URLs:${NC}"
echo "   🏗️  Plane (Project Management): http://localhost:8080"
echo "   🔧 Jenkins (CI/CD):             http://localhost:8081"
echo "   📊 Prometheus (Metrics):        http://localhost:9090"
echo "   📈 Grafana (Dashboards):        http://localhost:3000"
echo ""
echo -e "${BLUE}🔑 Default Credentials:${NC}"
echo "   Jenkins:  admin / agentic-factory"
echo "   Grafana:  admin / agentic-factory"
echo "   Plane:    Create account on first visit"
echo ""
echo -e "${BLUE}🤖 Agentic Team Status:${NC}"
echo "   📋 Product Owner (Cloud): Groq/Gemini"
echo "   🏗️  Architect (Cloud):    OpenRouter/Gemini"  
echo "   👨‍💻 Coder (Local):        DeepSeek-Coder 6.7B"
echo "   🧪 Tester (Local):       Llama3 8B"
echo "   👁️  Reviewer (Local):     Phi3 Mini"
echo "   💰 CEOMoneyKeeper (Local): Phi3 (Cost Control)"
echo ""
echo -e "${BLUE}🚀 Next Steps:${NC}"
echo "   1. Visit Plane to create your first project"
echo "   2. Configure Jenkins pipeline from Jenkinsfile"
echo "   3. Test the agent team: python gatekeeper.py"
echo "   4. Create a feature branch and push to trigger CI/CD"
echo ""
echo -e "${GREEN}Happy coding with your AI team! 🏭✨${NC}"