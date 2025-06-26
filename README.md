# 🤖 ProspectML - AI Engineer Coding Assistant

Deploy your own AI-powered coding assistant on DigitalOcean Kubernetes in minutes!

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
   - You can use any other API that supports the OpenAI API format, such as OpenAI, Gemini, or open source models like Llama.

## 🎯 Quick Start

Just run this single command:

```bash
curl -sSL https://raw.githubusercontent.com/AlgorithmicResearchGroup/prospectml_deploy/master/public_deploy/deploy-to-digitalocean.sh | bash
```

That's it! The script will:
- ✅ Check your computer has the required tools
- ✅ Connect to your DigitalOcean cluster
- ✅ Set up everything automatically
- ✅ Give you a web address to access your AI assistant

## 🛠 Manual Installation

If you prefer to see what you're running first:

1. Ensure the script is executable:
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

- 📚 Documentation: [GitHub Wiki](https://github.com/AlgorithmicResearchGroup/prospectml_deploy/wiki)
- 🐛 Issues: [GitHub Issues](https://github.com/AlgorithmicResearchGroup/prospectml_deploy/issues)

---

Made with ❤️ by Algorithmic Research Group