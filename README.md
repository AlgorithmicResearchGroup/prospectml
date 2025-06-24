# 🤖 ProspectML - AI Coding Assistant

Deploy your own AI-powered coding assistant on DigitalOcean Kubernetes in minutes!

## 🚀 What is ProspectML?

ProspectML is an AI coding assistant that can:
- ✨ Write complete applications from scratch
- 🐛 Debug and fix code issues
- 🔧 Refactor and improve existing code
- 📚 Explain complex code concepts
- 🎯 Complete coding challenges and tasks

## 📋 Prerequisites

Before you start, you'll need:

1. **A DigitalOcean Account** 
   - Sign up at [digitalocean.com](https://www.digitalocean.com)
   - New users get $200 free credit!

2. **A Kubernetes Cluster on DigitalOcean**
   - Don't have one? [Create one here](https://cloud.digitalocean.com/kubernetes/clusters/new) (takes 5 minutes)
   - Recommended: 3 nodes with 4GB RAM each (~$60/month)

3. **An Anthropic API Key**
   - Get one free at [console.anthropic.com](https://console.anthropic.com/api)
   - This powers the AI brain of your coding assistant

## 🎯 Quick Start

Just run this single command:

```bash
curl -sSL https://raw.githubusercontent.com/AlgorithmicResearchGroup/Coding-Agent-For-Deployment/master/public_deploy/deploy-to-digitalocean.sh | bash
```

That's it! The script will:
- ✅ Check your computer has the required tools
- ✅ Connect to your DigitalOcean cluster
- ✅ Set up everything automatically
- ✅ Give you a web address to access your AI assistant

## 🛠 Manual Installation

If you prefer to see what you're running first:

1. Download the script:
```bash
wget https://raw.githubusercontent.com/AlgorithmicResearchGroup/Coding-Agent-For-Deployment/master/public_deploy/deploy-to-digitalocean.sh
```

2. Make it executable:
```bash
chmod +x deploy-to-digitalocean.sh
```

3. Run it:
```bash
./deploy-to-digitalocean.sh
```

## 📖 What Gets Installed?

- **ProspectML Web Interface**: A user-friendly web app to interact with your AI
- **PostgreSQL Database**: Stores your projects and history
- **AI Agent System**: The brain that writes and debugs code
- **Load Balancer**: Makes your assistant accessible from the internet

## 💰 Costs

Running ProspectML on DigitalOcean typically costs:
- **Kubernetes Cluster**: ~$60/month (3 small nodes)
- **Load Balancer**: ~$12/month
- **Storage**: ~$10/month
- **Total**: ~$82/month

Plus API costs:
- **Anthropic API**: ~$0.01-0.03 per code generation

## 🔧 Troubleshooting

### "Installation is stuck at downloading AI system"
The AI system is 4.5GB and can take 5-10 minutes to download on DigitalOcean. This is normal!

### "Cannot connect to cluster"
Make sure you're logged in to DigitalOcean CLI:
```bash
doctl auth init
```

### "No external IP address"
DigitalOcean can take 2-3 minutes to assign an IP. You can check manually:
```bash
kubectl get svc -n prospectml
```

## 🗑 Uninstalling

To remove ProspectML from your cluster:
```bash
helm uninstall prospectml -n prospectml
kubectl delete namespace prospectml
```

## 🤝 Support

- 📚 Documentation: [GitHub Wiki](https://github.com/AlgorithmicResearchGroup/Coding-Agent-For-Deployment/wiki)
- 🐛 Issues: [GitHub Issues](https://github.com/AlgorithmicResearchGroup/Coding-Agent-For-Deployment/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/AlgorithmicResearchGroup/Coding-Agent-For-Deployment/discussions)

## 🔒 Security

- Your API keys are stored securely in Kubernetes secrets
- The AI agent runs in an isolated container
- All code is Cython-compiled for protection
- PostgreSQL passwords are randomly generated

## 📜 License

ProspectML is provided as-is for personal and commercial use.

---

Made with ❤️ by the Algorithmic Research Group