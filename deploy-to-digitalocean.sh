#!/bin/bash

# ProspectML Easy Deploy for DigitalOcean Kubernetes
# This script will help you deploy ProspectML to your DigitalOcean Kubernetes cluster

set -e

# Colors for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Fun ASCII art
echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════╗"
echo "║                                               ║"
echo "║     🤖 ProspectML AI Coding Assistant 🤖      ║"
echo "║         Easy Deploy for DigitalOcean          ║"
echo "║                                               ║"
echo "╚═══════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# Progress bar function
show_progress() {
    local duration=$1
    local steps=$2
    local message=$3
    local step_duration=$((duration / steps))
    
    echo -ne "${message} "
    for ((i=0; i<steps; i++)); do
        echo -ne "▓"
        sleep $step_duration
    done
    echo -e " ${GREEN}✓${NC}"
}

# Spinning animation function
spin() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Check if required tools are installed
echo -e "${CYAN}🔍 Step 1: Checking your computer has the required tools...${NC}"
echo ""

check_tool() {
    local tool=$1
    local name=$2
    local install_cmd=$3
    
    if command -v $tool &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} $name is installed"
    else
        echo -e "  ${RED}✗${NC} $name is not installed"
        echo -e "  ${YELLOW}→ To install: $install_cmd${NC}"
        exit 1
    fi
}

check_tool "kubectl" "Kubernetes CLI" "Visit https://kubernetes.io/docs/tasks/tools/"
check_tool "helm" "Helm (Package Manager)" "Visit https://helm.sh/docs/intro/install/"
check_tool "doctl" "DigitalOcean CLI" "brew install doctl (Mac) or visit https://docs.digitalocean.com/reference/doctl/how-to/install/"

echo ""
echo -e "${GREEN}✨ All required tools are installed!${NC}"
echo ""

# Get cluster information
echo -e "${CYAN}🌊 Step 2: Connecting to your DigitalOcean Kubernetes cluster${NC}"
echo ""
echo -e "${YELLOW}📋 Available clusters:${NC}"
echo ""

# List clusters
if ! doctl kubernetes cluster list 2>/dev/null; then
    echo -e "${RED}❌ Could not list clusters. Please make sure you're logged in to DigitalOcean CLI${NC}"
    echo -e "${YELLOW}→ Run: doctl auth init${NC}"
    exit 1
fi

echo ""
read -p "Enter your cluster name from the list above: " CLUSTER_NAME

# Connect to cluster
echo ""
echo -e "${CYAN}🔗 Connecting to cluster '${CLUSTER_NAME}'...${NC}"
if doctl kubernetes cluster kubeconfig save "$CLUSTER_NAME" &> /tmp/doctl_output; then
    echo -e "${GREEN}✓ Connected successfully!${NC}"
else
    echo -e "${RED}❌ Failed to connect to cluster${NC}"
    cat /tmp/doctl_output
    exit 1
fi

# Verify connection
echo ""
echo -e "${CYAN}🏥 Checking cluster health...${NC}"
if kubectl cluster-info &> /dev/null; then
    echo -e "${GREEN}✓ Cluster is healthy and ready!${NC}"
    echo ""
    echo -e "${PURPLE}📊 Your cluster nodes:${NC}"
    kubectl get nodes -o custom-columns=NAME:.metadata.name,STATUS:.status.conditions[-1].type,CPU:.status.capacity.cpu,MEMORY:.status.capacity.memory
else
    echo -e "${RED}❌ Cannot connect to cluster${NC}"
    exit 1
fi

# Get API key
echo ""
echo -e "${CYAN}🔑 Step 3: API Key Setup${NC}"
echo ""
echo -e "${YELLOW}ProspectML needs an API key to power the AI coding assistant.${NC}"
echo -e "${YELLOW}You can get one from: https://console.anthropic.com/api${NC}"
echo ""
read -s -p "Please enter your Anthropic API key (it will be hidden): " API_KEY
echo ""

if [ -z "$API_KEY" ]; then
    echo -e "${RED}❌ API key cannot be empty${NC}"
    exit 1
fi

echo -e "${GREEN}✓ API key received (hidden for security)${NC}"

# Create namespace
echo ""
echo -e "${CYAN}📦 Step 4: Preparing your cluster...${NC}"
echo ""

echo -ne "${YELLOW}Creating workspace...${NC} "
kubectl create namespace prospectml --dry-run=client -o yaml | kubectl apply -f - &> /dev/null &
spin $!
echo -e "${GREEN}✓${NC}"

# Create values file
echo ""
echo -e "${CYAN}⚙️  Step 5: Configuring ProspectML...${NC}"
echo ""

cat > /tmp/prospectml-values.yaml << EOF
# ProspectML Configuration for DigitalOcean
image:
  repository: algorithmicresearch/prospectml
  tag: "latest"
  pullPolicy: IfNotPresent

service:
  type: LoadBalancer
  port: 80

postgresql:
  enabled: true
  auth:
    username: prospectml
    password: "$(openssl rand -base64 16)"
    database: prospectml
  primary:
    persistence:
      enabled: true
      size: 10Gi

# Disable additional storage due to DigitalOcean limitations
storage:
  outputs:
    enabled: false
  sharedTmp:
    enabled: false
  data:
    enabled: false

resources:
  requests:
    memory: "2Gi"
    cpu: "1"
  limits:
    memory: "4Gi"
    cpu: "2"

aiProvider:
  anthropic:
    apiKey: "${API_KEY}"

agent:
  maxConcurrentRuns: 2
  resources:
    requests:
      memory: "4Gi"
      cpu: "2"
    limits:
      memory: "8Gi"
      cpu: "4"
EOF

echo -e "${GREEN}✓ Configuration created${NC}"

# Download Helm chart
echo ""
echo -e "${CYAN}📥 Step 6: Downloading ProspectML...${NC}"
echo ""

TEMP_DIR=$(mktemp -d)
cd $TEMP_DIR

echo -ne "${YELLOW}Downloading latest version...${NC} "
# Get the latest release
LATEST_RELEASE=$(curl -s https://api.github.com/repos/AlgorithmicResearchGroup/Coding-Agent-For-Deployment/releases/latest | grep "browser_download_url.*tgz" | cut -d '"' -f 4 || echo "")

if [ -z "$LATEST_RELEASE" ]; then
    # Fallback to direct download
    echo ""
    echo -e "${YELLOW}Using direct download method...${NC}"
    curl -sL -o prospectml-chart.tgz https://github.com/AlgorithmicResearchGroup/Coding-Agent-For-Deployment/releases/latest/download/prospectml-latest.tgz 2>/dev/null || \
    curl -sL -o prospectml-chart.tgz https://github.com/AlgorithmicResearchGroup/Coding-Agent-For-Deployment/archive/refs/heads/master.tar.gz
else
    curl -sL -o prospectml-chart.tgz "$LATEST_RELEASE" &
    spin $!
fi
echo -e "${GREEN}✓${NC}"

# Install ProspectML
echo ""
echo -e "${CYAN}🚀 Step 7: Installing ProspectML (this will take 5-10 minutes)...${NC}"
echo ""

echo -e "${YELLOW}📌 Installing components:${NC}"
echo "  • PostgreSQL Database"
echo "  • ProspectML Web Interface"
echo "  • AI Agent System"
echo "  • Load Balancer for Internet Access"
echo ""

# Install Helm chart
if [ -f prospectml-chart.tgz ]; then
    helm install prospectml prospectml-chart.tgz \
        -f /tmp/prospectml-values.yaml \
        --namespace prospectml \
        --wait \
        --timeout 10m &> /tmp/helm_output &
    HELM_PID=$!
else
    # Fallback: clone and install from repo
    echo -e "${YELLOW}Downloading from repository...${NC}"
    git clone --quiet https://github.com/AlgorithmicResearchGroup/Coding-Agent-For-Deployment.git &> /dev/null
    helm install prospectml ./Coding-Agent-For-Deployment/helm/prospectml \
        -f /tmp/prospectml-values.yaml \
        --namespace prospectml \
        --wait \
        --timeout 10m &> /tmp/helm_output &
    HELM_PID=$!
fi

# Show progress while installing
echo -ne "${YELLOW}Installing ProspectML components ${NC}"
while kill -0 $HELM_PID 2>/dev/null; do
    kubectl get pods -n prospectml --no-headers 2>/dev/null | while read line; do
        POD=$(echo $line | awk '{print $1}')
        STATUS=$(echo $line | awk '{print $3}')
        READY=$(echo $line | awk '{print $2}')
        
        case $STATUS in
            "Running") echo -ne "\r\033[K${GREEN}✓${NC} $POD is running! ($READY)                    " ;;
            "ContainerCreating") echo -ne "\r\033[K${YELLOW}⏳${NC} Setting up $POD...                    " ;;
            "PodInitializing") echo -ne "\r\033[K${YELLOW}🔄${NC} Initializing $POD...                  " ;;
            "Pending") echo -ne "\r\033[K${YELLOW}⏸${NC} Waiting for $POD...                     " ;;
            "ErrImagePull"|"ImagePullBackOff") echo -ne "\r\033[K${YELLOW}📥${NC} Downloading AI system (4.5GB, may take 5-10 min)..." ;;
            *) echo -ne "\r\033[K${YELLOW}⚡${NC} $POD: $STATUS                          " ;;
        esac
    done
    sleep 2
done

echo ""
if wait $HELM_PID; then
    echo ""
    echo -e "${GREEN}✅ ProspectML installed successfully!${NC}"
else
    echo ""
    echo -e "${RED}❌ Installation failed${NC}"
    echo -e "${YELLOW}Error details:${NC}"
    cat /tmp/helm_output
    exit 1
fi

# Wait for Load Balancer
echo ""
echo -e "${CYAN}🌐 Step 8: Setting up internet access...${NC}"
echo ""
echo -e "${YELLOW}Waiting for DigitalOcean to assign an IP address (usually 1-3 minutes)...${NC}"

# Wait for external IP
EXTERNAL_IP=""
for i in {1..60}; do
    EXTERNAL_IP=$(kubectl get svc prospectml -n prospectml -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    if [ ! -z "$EXTERNAL_IP" ]; then
        break
    fi
    echo -ne "\r${YELLOW}⏳ Waiting for IP address... ($i/60 seconds)${NC}"
    sleep 2
done

echo ""
if [ -z "$EXTERNAL_IP" ]; then
    echo -e "${RED}❌ Could not get external IP address${NC}"
    echo -e "${YELLOW}You can check manually with: kubectl get svc -n prospectml${NC}"
    exit 1
fi

# Success!
echo ""
echo -e "${GREEN}✨✨✨ SUCCESS! ✨✨✨${NC}"
echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                           ║${NC}"
echo -e "${BLUE}║${NC}   🎉 ${GREEN}ProspectML is now running on your cluster!${NC} 🎉      ${BLUE}║${NC}"
echo -e "${BLUE}║                                                           ║${NC}"
echo -e "${BLUE}║${NC}   📍 ${CYAN}Access your AI coding assistant at:${NC}                ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}      ${YELLOW}http://${EXTERNAL_IP}${NC}                              ${BLUE}║${NC}"
echo -e "${BLUE}║                                                           ║${NC}"
echo -e "${BLUE}║${NC}   📝 ${PURPLE}Next steps:${NC}                                        ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}      1. Open the link above in your browser              ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}      2. Create your account                              ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}      3. Start coding with AI! 🚀                         ${BLUE}║${NC}"
echo -e "${BLUE}║                                                           ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Save information
echo -e "${CYAN}💾 Saving your deployment information...${NC}"
cat > ~/prospectml-info.txt << EOF
ProspectML Deployment Information
=================================
Date: $(date)
Cluster: $CLUSTER_NAME
Namespace: prospectml
URL: http://${EXTERNAL_IP}

Useful Commands:
- View status: kubectl get pods -n prospectml
- View logs: kubectl logs -n prospectml -l app.kubernetes.io/name=prospectml -f
- Uninstall: helm uninstall prospectml -n prospectml

Database Password: $(grep "password:" /tmp/prospectml-values.yaml | cut -d'"' -f2)
EOF

echo -e "${GREEN}✓ Saved to ~/prospectml-info.txt${NC}"
echo ""

# Cleanup
rm -rf $TEMP_DIR
rm -f /tmp/prospectml-values.yaml /tmp/helm_output /tmp/doctl_output

echo -e "${PURPLE}🙏 Thank you for installing ProspectML!${NC}"
echo -e "${PURPLE}💬 Need help? Visit: https://github.com/AlgorithmicResearchGroup/Coding-Agent-For-Deployment${NC}"
echo ""