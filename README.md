# ProspectML

🚀 **AI-Powered Coding Agent with Web Interface**

ProspectML is an autonomous coding agent that can write, test, and debug code using state-of-the-art language models. It features a web-based interface for managing coding tasks and monitoring progress in real-time.

## ✨ Features

- 🤖 **Multi-LLM Support**: Works with Anthropic Claude, OpenAI GPT, and Google Gemini
- 🌐 **Web Interface**: Beautiful dashboard for task management and monitoring
- 🔄 **Iterative Development**: Automatically refines code based on test results
- 📊 **Progress Tracking**: Real-time visualization of the coding process
- 🗄️ **Persistent Storage**: MinIO integration for storing outputs and artifacts
- ☸️ **Kubernetes Native**: Designed for cloud deployment

## 🚀 Quick Start

### ⚡ Easiest Way: One-Command Installation

The simplest way to get ProspectML running is with our universal installer script:

```bash
# Set your API key
export ANTHROPIC_API_KEY=sk-ant-your-key-here

# Install ProspectML (works on any Kubernetes cluster)
curl -sSL https://raw.githubusercontent.com/AlgorithmicResearchGroup/prospectml/master/install | bash
```

**That's it!** The script will:
- ✅ Auto-detect your cluster type (AWS EKS, GKE, AKS, DigitalOcean, minikube, etc.)
- ✅ Deploy MinIO object storage
- ✅ Deploy PostgreSQL database  
- ✅ Install ProspectML with optimal settings
- ✅ Provide you with the access URL

### Prerequisites

- Kubernetes cluster (any cloud provider or local)
- kubectl configured and connected
- Helm 3.x
- At least one AI provider API key

### Alternative: Manual Helm Installation

If you prefer to use Helm directly:

```bash
# Install ProspectML using Helm
helm install prospectml oci://ghcr.io/algorithmicresearchgroup/charts/prospectml \
  --set aiProviders.anthropic.apiKey="sk-ant-your-key-here" \
  --create-namespace \
  --namespace prospectml
```

### Configuration Options

```bash
# Install with custom configuration
helm install prospectml oci://ghcr.io/algorithmicresearchgroup/charts/prospectml \
  --set aiProviders.anthropic.apiKey="your-anthropic-key" \
  --set aiProviders.openai.apiKey="your-openai-key" \
  --set agent.maxConcurrentRuns=5 \
  --set resources.limits.memory="8Gi" \
  --namespace prospectml \
  --create-namespace
```

## 🔧 Configuration

### AI Providers

ProspectML supports multiple AI providers. Configure at least one:

```yaml
aiProviders:
  anthropic:
    apiKey: "sk-ant-your-key"
  openai:
    apiKey: "sk-your-openai-key"
  google:
    apiKey: "your-google-ai-key"
```

### Resource Limits

Adjust based on your cluster capacity:

```yaml
resources:
  requests:
    memory: "2Gi"
    cpu: "1"
  limits:
    memory: "4Gi"
    cpu: "2"

agent:
  resources:
    requests:
      memory: "4Gi"
      cpu: "2"
    limits:
      memory: "8Gi"
      cpu: "4"
```

### Service Types

Choose how to expose the service:

```yaml
service:
  type: LoadBalancer  # For cloud providers
  # type: NodePort    # For local clusters
  # type: ClusterIP   # Internal only
```

## 📖 Usage

### Access the Web Interface

After installation, get the service URL:

```bash
# For LoadBalancer
kubectl get svc -n prospectml

# For port-forwarding
kubectl port-forward -n prospectml svc/prospectml 8080:80
# Then visit: http://localhost:8080
```

### Create Your First Task

1. Open the web interface
2. Click "New Task"
3. Enter your coding task description
4. Select an AI model
5. Click "Start" and watch the agent work!

### Example Tasks

- "Create a REST API for a todo app using FastAPI"
- "Implement a binary search algorithm with unit tests"
- "Build a data visualization dashboard with matplotlib"
- "Write a web scraper for extracting product prices"

## 🛠️ Advanced Usage

### Custom Values File

Create a `values.yaml` file for advanced configuration:

```yaml
# values.yaml
aiProviders:
  anthropic:
    apiKey: "your-key"

agent:
  maxConcurrentRuns: 5
  defaultModel: "claude-3-sonnet-20240229"

resources:
  limits:
    memory: "8Gi"
    cpu: "4"

persistence:
  enabled: true
  size: "50Gi"
```

Install with:
```bash
helm install prospectml oci://ghcr.io/algorithmicresearchgroup/charts/prospectml -f values.yaml
```

### Monitoring

Check deployment status:

```bash
# View pods
kubectl get pods -n prospectml

# Check logs
kubectl logs -f deployment/prospectml -n prospectml

# Monitor resources
kubectl top pods -n prospectml
```

## 🔧 Troubleshooting

### Common Issues

**Pods not starting?**
```bash
kubectl describe pod -n prospectml -l app.kubernetes.io/name=prospectml
```

**Can't access the web interface?**
```bash
# Check service status
kubectl get svc -n prospectml

# Use port-forward as fallback
kubectl port-forward -n prospectml svc/prospectml 8080:80
```

**Database connection issues?**
```bash
# Check PostgreSQL status
kubectl get pods -n prospectml -l app.kubernetes.io/name=postgresql
```

### Getting Help

- Check the [troubleshooting guide](https://github.com/AlgorithmicResearchGroup/prospectml/blob/master/TROUBLESHOOTING.md)
- View logs: `kubectl logs -f deployment/prospectml -n prospectml`
- Open an [issue](https://github.com/AlgorithmicResearchGroup/prospectml/issues)

## 🗂️ Architecture

ProspectML consists of:

- **Web Application**: Flask-based dashboard and API
- **Agent Engine**: Autonomous coding agent with tree search
- **PostgreSQL**: Task and result storage
- **MinIO**: Object storage for code artifacts
- **Kubernetes Jobs**: Isolated execution environments

## 📦 Available Versions

```bash
# Install latest version
helm install prospectml oci://ghcr.io/algorithmicresearchgroup/charts/prospectml

# Install specific version
helm install prospectml oci://ghcr.io/algorithmicresearchgroup/charts/prospectml --version 1.250629.61

# List available versions
helm search repo prospectml --versions
```

## 🚀 Upgrade

```bash
# Upgrade to latest version
helm upgrade prospectml oci://ghcr.io/algorithmicresearchgroup/charts/prospectml

# Upgrade with new values
helm upgrade prospectml oci://ghcr.io/algorithmicresearchgroup/charts/prospectml -f new-values.yaml
```

## 🗑️ Uninstall

```bash
# Remove ProspectML
helm uninstall prospectml -n prospectml

# Remove namespace (optional)
kubectl delete namespace prospectml
```

## 🤝 Contributing

We welcome contributions! Please see our [contributing guide](CONTRIBUTING.md) for details.

## 📄 License

Please see the [LICENSE](https://github.com/AlgorithmicResearchGroup/prospectml-deploy/blob/main/LICENSE) file for details.

## 🆘 Support

- 📧 Email: support@algorithmicresearchgroup.com
- 💬 Discord: [Join our community](https://discord.gg/prospectml)
- 📖 Documentation: [docs.prospectml.com](https://docs.prospectml.com)

---

**Built with ❤️ by [Algorithmic Research Group](https://algorithmicresearchgroup.com)**