#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Starting Agentic Software Factory${NC}"
echo "========================================"
echo ""

echo -e "${BLUE}1. Pre-flight checks${NC}"

IS_WSL=false
if grep -qi "microsoft" /proc/version 2>/dev/null; then
    IS_WSL=true
    echo -e "${GREEN}WSL 2 detected - running head (brain) mode${NC}"
fi

if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}X Docker not running. Start Docker first.${NC}"
    exit 1
fi
echo -e "${GREEN}OK Docker running${NC}"

if [ ! -f ../sec/.env ]; then
    echo -e "${YELLOW}W sec/.env not found. Copy from .env.example...${NC}"
    if [ -f ../sec/.env.example ]; then
        cp ../sec/.env.example ../sec/.env
        echo -e "${YELLOW}Edit sec/.env with your API keys${NC}"
    else
        echo -e "${RED}X No sec/.env.example found.${NC}"
    fi
fi
fi
echo -e "${GREEN}OK Environment configured${NC}"

if [ ! -f ../sec/.env ]; then
    echo -e "${YELLOW}W variables.env not found in ops/...${NC}"
fi

if [ ! -d ./plane/logs ]; then
    mkdir -p ./plane/logs
fi

if curl -s http://localhost:11434/api/version > /dev/null 2>&1; then
    echo -e "${GREEN}OK Ollama running${NC}"
else
    echo -e "${YELLOW}W Ollama not running. Starting...${NC}"
    if command -v ollama > /dev/null 2>&1; then
        ollama serve > /dev/null 2>&1 &
        sleep 3
        echo -e "${GREEN}OK Ollama started${NC}"
    else
        echo -e "${RED}X Ollama not installed.${NC}"
        exit 1
    fi
fi

echo ""

echo -e "${BLUE}2. Starting infrastructure${NC}"
docker-compose --env-file ../sec/.env up -d
echo -e "${GREEN}OK Docker services started${NC}"
echo ""

echo -e "${BLUE}3. Waiting for services${NC}"

echo "   Plane Database..."
timeout=60
counter=0
while ! docker-compose exec -T plane-db pg_isready -U plane > /dev/null 2>&1; do
    if [ $counter -ge $timeout ]; then
        echo -e "${RED}X Plane Database failed${NC}"
        exit 1
    fi
    sleep 1
    counter=$((counter + 1))
done
echo -e "   ${GREEN}OK Plane Database${NC}"

echo "   Plane API..."
timeout=120
counter=0
while ! curl -s http://localhost:8000/api/v1/ > /dev/null 2>&1; do
    if [ $counter -ge $timeout ]; then
        echo -e "${RED}X Plane API failed${NC}"
        exit 1
    fi
    sleep 2
    counter=$((counter + 2))
done
echo -e "   ${GREEN}OK Plane API${NC}"

echo "   Jenkins..."
timeout=180
counter=0
while ! curl -s http://localhost:8081/login > /dev/null 2>&1; do
    if [ $counter -ge $timeout ]; then
        echo -e "${RED}X Jenkins failed${NC}"
        exit 1
    fi
    sleep 3
    counter=$((counter + 3))
done
echo -e "   ${GREEN}OK Jenkins${NC}"

echo ""

echo -e "${BLUE}4. Agent Team Status${NC}"
CONFIG_FILE="../sec/config/models.yaml"
if [ -f "$CONFIG_FILE" ]; then
    python3 -c "
import yaml
with open('$CONFIG_FILE') as f:
    cfg = yaml.safe_load(f)
    print('   Role          Provider   Model')
    print('   ' + '-' * 40)
    for role, spec in cfg['roles'].items():
        print(f'   {role:14} {spec[\"provider\"]:10} {spec[\"model\"]}')" 2>/dev/null || echo "   Config parsing failed"
else
    echo -e "   ${YELLOW}W: config/models.yaml not found${NC}"
fi

echo ""

echo -e "${BLUE}5. Starting Agent Services${NC}"

if [ "$IS_WSL" = true ]; then
    echo "   Starting head container (WSL 2 mode)..."
    docker-compose up -d head
    if docker-compose ps head | grep -q "Up"; then
        echo -e "   ${GREEN}OK head container running${NC}"
    else
        echo -e "   ${YELLOW}W head container may need attention${NC}"
    fi
elif command -v python3 > /dev/null 2>&1; then
    if [ -f ../dev/inbox_poller.py ]; then
        echo "   Starting inbox_poller (Windows host mode)..."
        nohup python3 ../dev/inbox_poller.py > ./plane/logs/inbox_poller.log 2>&1 &
        POLLER_PID=$!
        sleep 2
        if ps -p $POLLER_PID > /dev/null 2>&1; then
            echo -e "   ${GREEN}OK inbox_poller running (PID: $POLLER_PID)${NC}"
        else
            echo -e "   ${YELLOW}W inbox_poller may have failed - check logs${NC}"
        fi
    else
        echo -e "   ${YELLOW}W dev/inbox_poller.py not found${NC}"
    fi
else
    echo -e "   ${YELLOW}W Python3 not found - skipping agent services${NC}"
fi

echo ""

echo -e "${GREEN}Agentic Software Factory is OPERATIONAL${NC}"
echo "=============================================="
echo ""
echo -e "${BLUE}Service URLs:${NC}"
echo "   Plane (Project Management): http://localhost"
echo "   Kafka UI:                   http://localhost:8085"
echo "   Jenkins (CI/CD):            http://localhost:8081"
echo "   MinIO (Storage):            http://localhost:9000"
echo ""
echo -e "${BLUE}Agent Logs:${NC}"
if [ "$IS_WSL" = true ]; then
    echo "   Head container: docker-compose logs -f head"
else
    echo "   inbox_poller: tail -f plane/logs/inbox_poller.log"
fi
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "   1. Visit Plane to create/manage projects"
echo "   2. Watch agent respond: docker-compose logs -f head (WSL) or tail -f ops/plane/logs/inbox_poller.log (Windows)"
echo "   3. Test gatekeeper: python dev/gatekeeper.py --role Coder --prompt 'Hello'"