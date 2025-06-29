#!/bin/bash

# ProspectML Universal Deployment Script
# Works on: AWS EKS, Google GKE, Azure AKS, DigitalOcean, minikube, kind, and more

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration (can be overridden by environment variables)
NAMESPACE="${PROSPECTML_NAMESPACE:-prospectml}"
RELEASE_NAME="${PROSPECTML_RELEASE_NAME:-prospectml}"
MINIO_RELEASE_NAME="${PROSPECTML_MINIO_RELEASE:-prospectml-minio}"
VERSION="${PROSPECTML_VERSION:-latest}"
SERVICE_TYPE="${PROSPECTML_SERVICE_TYPE:-auto}"  # auto, LoadBalancer, NodePort, ClusterIP
CLUSTER_TYPE="${PROSPECTML_CLUSTER_TYPE:-auto}"  # auto, aws, gcp, azure, digitalocean, minikube, kind

echo -e "${CYAN}🚀 ProspectML Universal Installer${NC}"
echo -e "${BLUE}   Works on any Kubernetes cluster${NC}"
echo ""

# Check prerequisites
echo -e "${CYAN}🔍 Checking prerequisites...${NC}"
MISSING_TOOLS=""

if ! command -v kubectl &> /dev/null; then
    MISSING_TOOLS="$MISSING_TOOLS kubectl"
fi

if ! command -v helm &> /dev/null; then
    MISSING_TOOLS="$MISSING_TOOLS helm"
fi

if [ -n "$MISSING_TOOLS" ]; then
    echo -e "${RED}❌ Missing required tools:$MISSING_TOOLS${NC}"
    echo ""
    echo "Please install the missing tools:"
    echo "• kubectl: https://kubernetes.io/docs/tasks/tools/"
    echo "• helm: https://helm.sh/docs/intro/install/"
    exit 1
fi

echo -e "${GREEN}✓ All prerequisites found${NC}"

# Step 1: Verify Kubernetes connection
echo ""
echo -e "${CYAN}📍 Step 1: Verifying Kubernetes connection...${NC}"

if ! kubectl cluster-info &>/dev/null; then
    echo -e "${RED}❌ Cannot connect to Kubernetes cluster${NC}"
    echo ""
    echo "Please ensure:"
    echo "• kubectl is configured to connect to your cluster"
    echo "• You have sufficient permissions to create resources"
    echo ""
    echo "Try: kubectl get nodes"
    exit 1
fi

CURRENT_CONTEXT=$(kubectl config current-context 2>/dev/null || echo "unknown")
echo -e "Current context: ${YELLOW}$CURRENT_CONTEXT${NC}"

# Get cluster info for auto-detection
CLUSTER_INFO=$(kubectl cluster-info 2>/dev/null || echo "")
NODES_INFO=$(kubectl get nodes -o wide 2>/dev/null || echo "")

echo -e "${GREEN}✓ Connected to Kubernetes cluster${NC}"

# Step 2: Auto-detect cluster type and set defaults
echo ""
echo -e "${CYAN}🔍 Step 2: Detecting cluster environment...${NC}"

if [ "$CLUSTER_TYPE" = "auto" ]; then
    if echo "$CLUSTER_INFO" | grep -q "eks.amazonaws.com"; then
        CLUSTER_TYPE="aws"
        echo -e "Detected: ${YELLOW}Amazon EKS${NC}"
    elif echo "$CLUSTER_INFO" | grep -q "gke.goog"; then
        CLUSTER_TYPE="gcp"
        echo -e "Detected: ${YELLOW}Google GKE${NC}"
    elif echo "$CLUSTER_INFO" | grep -q "azmk8s.io"; then
        CLUSTER_TYPE="azure"
        echo -e "Detected: ${YELLOW}Azure AKS${NC}"
    elif echo "$CLUSTER_INFO" | grep -q "ondigitalocean.com"; then
        CLUSTER_TYPE="digitalocean"
        echo -e "Detected: ${YELLOW}DigitalOcean Kubernetes${NC}"
    elif echo "$NODES_INFO" | grep -q "minikube"; then
        CLUSTER_TYPE="minikube"
        echo -e "Detected: ${YELLOW}minikube${NC}"
    elif echo "$NODES_INFO" | grep -q "kind"; then
        CLUSTER_TYPE="kind"
        echo -e "Detected: ${YELLOW}kind${NC}"
    else
        CLUSTER_TYPE="generic"
        echo -e "Detected: ${YELLOW}Generic Kubernetes cluster${NC}"
    fi
fi

# Set service type based on cluster
if [ "$SERVICE_TYPE" = "auto" ]; then
    case "$CLUSTER_TYPE" in
        aws|gcp|azure|digitalocean)
            SERVICE_TYPE="LoadBalancer"
            echo -e "Service type: ${YELLOW}LoadBalancer${NC} (cloud provider)"
            ;;
        minikube|kind)
            SERVICE_TYPE="NodePort"
            echo -e "Service type: ${YELLOW}NodePort${NC} (local cluster)"
            ;;
        *)
            SERVICE_TYPE="ClusterIP"
            echo -e "Service type: ${YELLOW}ClusterIP${NC} (generic cluster)"
            ;;
    esac
else
    echo -e "Service type: ${YELLOW}$SERVICE_TYPE${NC} (user specified)"
fi

# Step 3: Check for required API keys
echo ""
echo -e "${CYAN}🔑 Step 3: Checking for AI provider API keys...${NC}"

if [ -z "$ANTHROPIC_API_KEY" ] && [ -z "$OPENAI_API_KEY" ] && [ -z "$GOOGLE_API_KEY" ]; then
    echo -e "${YELLOW}⚠️  No AI provider API keys found${NC}"
    echo ""
    echo "ProspectML requires at least one AI provider API key:"
    echo "• ANTHROPIC_API_KEY (recommended)"
    echo "• OPENAI_API_KEY" 
    echo "• GOOGLE_API_KEY"
    echo ""
    read -p "Do you want to enter an Anthropic API key now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -s -p "Enter your Anthropic API key: " ANTHROPIC_API_KEY
        echo ""
        if [ -z "$ANTHROPIC_API_KEY" ]; then
            echo -e "${RED}❌ API key is required to proceed${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ At least one AI provider API key is required${NC}"
        echo "Set one of: ANTHROPIC_API_KEY, OPENAI_API_KEY, or GOOGLE_API_KEY"
        exit 1
    fi
fi

# Show which keys are configured
if [ -n "$ANTHROPIC_API_KEY" ]; then
    echo -e "${GREEN}✓ Anthropic API key configured${NC}"
fi
if [ -n "$OPENAI_API_KEY" ]; then
    echo -e "${GREEN}✓ OpenAI API key configured${NC}"
fi
if [ -n "$GOOGLE_API_KEY" ]; then
    echo -e "${GREEN}✓ Google API key configured${NC}"
fi

# Step 4: Create namespace
echo ""
echo -e "${CYAN}📁 Step 4: Creating namespace...${NC}"
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f - >/dev/null 2>&1
echo -e "${GREEN}✓ Namespace $NAMESPACE ready${NC}"

# Step 5: Deploy MinIO separately
echo ""
echo -e "${CYAN}🪣 Step 5: Deploying MinIO object storage...${NC}"

# Add Bitnami repo
if ! helm repo list | grep -q "^bitnami"; then
    echo "Adding Bitnami Helm repository..."
    helm repo add bitnami https://charts.bitnami.com/bitnami >/dev/null 2>&1
fi
helm repo update >/dev/null 2>&1

# Generate secure MinIO password
MINIO_PASSWORD=$(openssl rand -base64 16 2>/dev/null || echo "minio-$(date +%s | tail -c 10)")

# Deploy MinIO with cluster-appropriate settings
echo "Installing MinIO..."
MINIO_VALUES=""
case "$CLUSTER_TYPE" in
    minikube|kind)
        MINIO_VALUES="--set persistence.enabled=false"
        ;;
    *)
        MINIO_VALUES="--set persistence.enabled=true --set persistence.size=20Gi"
        ;;
esac

helm upgrade --install $MINIO_RELEASE_NAME bitnami/minio \
  --namespace $NAMESPACE \
  --set auth.rootUser=minioadmin \
  --set auth.rootPassword="$MINIO_PASSWORD" \
  --set service.type=ClusterIP \
  --set service.port=9000 \
  $MINIO_VALUES \
  --wait \
  --timeout 10m >/dev/null 2>&1 || {
    echo -e "${RED}❌ MinIO deployment failed${NC}"
    echo "Check with: kubectl get pods -n $NAMESPACE"
    exit 1
}

echo -e "${GREEN}✓ MinIO deployed successfully${NC}"

# Step 6: Get Helm chart from GitHub Container Registry
echo ""
echo -e "${CYAN}📦 Step 6: Downloading ProspectML Helm chart...${NC}"

echo "Downloading Helm chart from GitHub Container Registry..."
if [ "$VERSION" = "latest" ]; then
    helm pull oci://ghcr.io/algorithmicresearchgroup/charts/prospectml --untar --untardir /tmp
else
    helm pull oci://ghcr.io/algorithmicresearchgroup/charts/prospectml --version "$VERSION" --untar --untardir /tmp
fi
CHART_PATH="/tmp/prospectml"

# Step 7: Create values file
echo ""
echo -e "${CYAN}⚙️  Step 7: Generating configuration...${NC}"

# Generate secure passwords
POSTGRES_PASSWORD=$(openssl rand -base64 16 2>/dev/null || echo "postgres-$(date +%s | tail -c 10)")
PROSPECTML_DB_PASSWORD=$(openssl rand -base64 16 2>/dev/null || echo "prospectml-$(date +%s | tail -c 10)")
FLASK_SECRET_KEY=$(openssl rand -base64 32 2>/dev/null || echo "flask-secret-$(date +%s)")

# Set service annotations based on cluster type
SERVICE_ANNOTATIONS=""
case "$CLUSTER_TYPE" in
    digitalocean)
        SERVICE_ANNOTATIONS="service.beta.kubernetes.io/do-loadbalancer-size-slug: lb-small"
        ;;
    aws)
        SERVICE_ANNOTATIONS="service.beta.kubernetes.io/aws-load-balancer-type: nlb"
        ;;
esac

# Set storage configuration based on cluster type
STORAGE_CONFIG="emptydir"
case "$CLUSTER_TYPE" in
    minikube|kind)
        STORAGE_CONFIG="emptydir"
        ;;
    *)
        STORAGE_CONFIG="emptydir"  # Can be changed to pvc if needed
        ;;
esac

# Create values file
cat > /tmp/prospectml-values.yaml <<EOF
# ProspectML Configuration
# Generated by install script for $CLUSTER_TYPE

# Basic application configuration
replicaCount: 1

# Image configuration
image:
  repository: algorithmicresearch/prospectml
  tag: "$VERSION"
  pullPolicy: Always

# Flask configuration
flask:
  env: "production"
  secretKey: "$FLASK_SECRET_KEY"

# Service configuration
service:
  type: $SERVICE_TYPE
  port: 80
  targetPort: 5000
$(if [ -n "$SERVICE_ANNOTATIONS" ]; then
echo "  annotations:"
echo "    $SERVICE_ANNOTATIONS"
fi)

# Storage configuration
storage:
  type: $STORAGE_CONFIG
  sharedTmp:
    enabled: true
    mountPath: "/tmp/shared"
    size: "10Gi"
  outputs:
    enabled: true
    mountPath: "/app/outputs"
    size: "20Gi"
  data:
    enabled: true
    mountPath: "/app/data"
    size: "10Gi"

# MinIO configuration (disabled since deployed separately)
minio:
  enabled: false

# PostgreSQL configuration
postgresql:
  enabled: true
  auth:
    postgresPassword: "$POSTGRES_PASSWORD"
    username: prospectml
    password: "$PROSPECTML_DB_PASSWORD"
    database: prospectml
  primary:
    persistence:
      enabled: $([ "$CLUSTER_TYPE" != "minikube" ] && [ "$CLUSTER_TYPE" != "kind" ] && echo "true" || echo "false")
      size: 20Gi

# Database configuration
database:
  external:
    enabled: false

# Application resources
resources:
  requests:
    memory: "2Gi"
    cpu: "1"
  limits:
    memory: "4Gi"
    cpu: "2"

# Agent configuration
agent:
  maxConcurrentRuns: 3
  defaultModel: "claude-3-sonnet-20240229"
  defaultMaxIterations: 50
  enableStorage: true
  storageProvider: "minio"
  storageBucket: "prospectml-outputs"
  resources:
    requests:
      memory: "4Gi"
      cpu: "2"
    limits:
      memory: "8Gi"
      cpu: "4"

# AI Providers configuration
aiProviders:
  anthropic:
    apiKey: "${ANTHROPIC_API_KEY:-}"
  openai:
    apiKey: "${OPENAI_API_KEY:-}"
  google:
    apiKey: "${GOOGLE_API_KEY:-}"

# Environment variables
env:
  MINIO_ENDPOINT: "$MINIO_RELEASE_NAME.$NAMESPACE.svc.cluster.local:9000"
  MINIO_ACCESS_KEY: "minioadmin"
  MINIO_SECRET_KEY: "$MINIO_PASSWORD"
  FLASK_ENV: "production"

# Logging configuration
logging:
  level: "INFO"
  format: "json"

# Health check configuration
healthcheck:
  enabled: true
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  successThreshold: 1
  failureThreshold: 3

# RBAC
rbac:
  create: true

# Service Account
serviceAccount:
  create: true

# Ingress (disabled by default)
ingress:
  enabled: false
EOF

echo -e "${GREEN}✓ Configuration generated${NC}"

# Step 8: Deploy ProspectML
echo ""
echo -e "${CYAN}🚢 Step 8: Deploying ProspectML...${NC}"

echo "Installing ProspectML application..."
helm upgrade --install $RELEASE_NAME \
  "$CHART_PATH" \
  --namespace $NAMESPACE \
  --values /tmp/prospectml-values.yaml \
  --timeout 20m >/dev/null 2>&1 || {
    echo -e "${RED}❌ ProspectML deployment failed${NC}"
    echo ""
    echo "Debug commands:"
    echo "  kubectl get pods -n $NAMESPACE"
    echo "  kubectl logs -n $NAMESPACE -l app.kubernetes.io/name=prospectml"
    echo "  helm status $RELEASE_NAME -n $NAMESPACE"
    exit 1
}

echo -e "${GREEN}✓ ProspectML deployed successfully${NC}"

# Step 9: Wait for services
echo ""
echo -e "${CYAN}⏳ Step 9: Waiting for services to start...${NC}"

# Wait for PostgreSQL
echo "Waiting for database..."
for i in {1..120}; do
    if kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=postgresql 2>/dev/null | grep -q "Running"; then
        break
    fi
    if [ $((i % 20)) -eq 0 ]; then
        echo "  Still waiting for database... (${i}s)"
    fi
    sleep 1
done

# Wait for main application
echo "Waiting for ProspectML application..."
for i in {1..180}; do
    READY_REPLICAS=$(kubectl get deployment $RELEASE_NAME -n $NAMESPACE -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    if [ "$READY_REPLICAS" = "1" ]; then
        break
    fi
    if [ $((i % 30)) -eq 0 ]; then
        echo "  Still waiting for application... (${i}s)"
    fi
    sleep 1
done

echo -e "${GREEN}✓ All services are running${NC}"

# Step 10: Get access information
echo ""
echo -e "${CYAN}📡 Step 10: Getting access information...${NC}"

ACCESS_URL=""
PORT_FORWARD_NEEDED=false

case "$SERVICE_TYPE" in
    LoadBalancer)
        echo "Waiting for LoadBalancer IP..."
        for i in {1..120}; do
            LB_IP=$(kubectl get svc $RELEASE_NAME -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
            LB_HOSTNAME=$(kubectl get svc $RELEASE_NAME -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
            
            if [ -n "$LB_IP" ] && [ "$LB_IP" != "null" ]; then
                ACCESS_URL="http://$LB_IP"
                break
            elif [ -n "$LB_HOSTNAME" ] && [ "$LB_HOSTNAME" != "null" ]; then
                ACCESS_URL="http://$LB_HOSTNAME"
                break
            fi
            
            if [ $((i % 20)) -eq 0 ]; then
                echo "  Still waiting for LoadBalancer... (${i}s)"
            fi
            sleep 1
        done
        ;;
    NodePort)
        NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}' 2>/dev/null)
        if [ -z "$NODE_IP" ]; then
            NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null)
        fi
        NODE_PORT=$(kubectl get svc $RELEASE_NAME -n $NAMESPACE -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
        
        if [ -n "$NODE_IP" ] && [ -n "$NODE_PORT" ]; then
            ACCESS_URL="http://$NODE_IP:$NODE_PORT"
        else
            PORT_FORWARD_NEEDED=true
        fi
        ;;
    ClusterIP)
        PORT_FORWARD_NEEDED=true
        ;;
esac

# Display results
echo ""
echo -e "${GREEN}✅ ProspectML installation complete!${NC}"
echo ""
echo -e "${CYAN}📍 Access Information:${NC}"

if [ -n "$ACCESS_URL" ]; then
    echo -e "  🌐 ProspectML URL: ${YELLOW}$ACCESS_URL${NC}"
else
    PORT_FORWARD_NEEDED=true
fi

if [ "$PORT_FORWARD_NEEDED" = true ]; then
    echo -e "  💡 To access ProspectML, run this command:"
    echo -e "     ${YELLOW}kubectl port-forward -n $NAMESPACE svc/$RELEASE_NAME 8080:80${NC}"
    echo -e "  🌐 Then visit: ${YELLOW}http://localhost:8080${NC}"
fi

echo -e "  📊 Namespace: ${YELLOW}$NAMESPACE${NC}"
echo -e "  🏷️  Version: ${YELLOW}$VERSION${NC}"

# MinIO information
echo ""
echo -e "${CYAN}🪣 MinIO Object Storage:${NC}"
echo -e "  User: ${YELLOW}minioadmin${NC}"
echo -e "  Password: ${YELLOW}$MINIO_PASSWORD${NC}"
echo -e "  💡 To access MinIO console:"
echo -e "     ${YELLOW}kubectl port-forward -n $NAMESPACE svc/$MINIO_RELEASE_NAME 9001:9001${NC}"
echo -e "     Then visit: ${YELLOW}http://localhost:9001${NC}"

# Useful commands
echo ""
echo -e "${CYAN}💡 Useful Commands:${NC}"
echo -e "  • View app logs: ${YELLOW}kubectl logs -f deployment/$RELEASE_NAME -n $NAMESPACE${NC}"
echo -e "  • Check status: ${YELLOW}kubectl get pods -n $NAMESPACE${NC}"
echo -e "  • Uninstall: ${YELLOW}helm uninstall $RELEASE_NAME $MINIO_RELEASE_NAME -n $NAMESPACE${NC}"

# Save important info to file
cat > prospectml-info.txt <<EOF
ProspectML Installation Information
==================================

Access URL: $ACCESS_URL
Namespace: $NAMESPACE
Release: $RELEASE_NAME

MinIO Credentials:
- User: minioadmin
- Password: $MINIO_PASSWORD

Useful Commands:
- View logs: kubectl logs -f deployment/$RELEASE_NAME -n $NAMESPACE
- Port forward: kubectl port-forward -n $NAMESPACE svc/$RELEASE_NAME 8080:80
- Uninstall: helm uninstall $RELEASE_NAME $MINIO_RELEASE_NAME -n $NAMESPACE

Generated: $(date)
EOF

echo ""
echo -e "${BLUE}📄 Installation details saved to: ${YELLOW}prospectml-info.txt${NC}"

# Cleanup
rm -f /tmp/prospectml-values.yaml
if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
fi

echo ""
echo -e "${GREEN}🎉 Happy coding with ProspectML! 🚀${NC}"