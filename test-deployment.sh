#!/bin/bash

# Test script to verify ProspectML deployment

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 ProspectML Deployment Test${NC}"
echo "============================="
echo ""

# Check if namespace exists
echo -n "Checking namespace... "
if kubectl get namespace prospectml &> /dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "Namespace 'prospectml' not found. Is ProspectML installed?"
    exit 1
fi

# Check pods
echo -n "Checking pods... "
PODS=$(kubectl get pods -n prospectml --no-headers 2>/dev/null | wc -l)
RUNNING=$(kubectl get pods -n prospectml --no-headers 2>/dev/null | grep -c "Running")

if [ $PODS -gt 0 ]; then
    echo -e "${GREEN}✓${NC} ($RUNNING/$PODS running)"
    kubectl get pods -n prospectml
else
    echo -e "${RED}✗${NC}"
    echo "No pods found"
    exit 1
fi

# Check service
echo ""
echo -n "Checking service... "
EXTERNAL_IP=$(kubectl get svc prospectml -n prospectml -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")

if [ ! -z "$EXTERNAL_IP" ]; then
    echo -e "${GREEN}✓${NC}"
    echo -e "URL: ${YELLOW}http://${EXTERNAL_IP}${NC}"
    
    # Test HTTP connection
    echo -n "Testing connection... "
    if curl -s -o /dev/null -w "%{http_code}" "http://${EXTERNAL_IP}" | grep -q "200"; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${YELLOW}⚠${NC} (may still be starting up)"
    fi
else
    echo -e "${YELLOW}Pending${NC}"
    echo "Load balancer IP not yet assigned"
fi

# Show logs
echo ""
echo -e "${BLUE}Recent logs:${NC}"
kubectl logs -n prospectml -l app.kubernetes.io/name=prospectml --tail=5 2>/dev/null || echo "No logs available yet"

echo ""
echo -e "${GREEN}Test complete!${NC}"