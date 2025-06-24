# 🔧 Troubleshooting Guide

## Common Issues and Solutions

### 🚫 "Cannot list clusters" Error

**Problem**: The script shows an error when trying to list DigitalOcean clusters.

**Solution**:
1. Make sure you're logged in to DigitalOcean CLI:
   ```bash
   doctl auth init
   ```
2. Enter your DigitalOcean API token when prompted
3. You can get a token from: https://cloud.digitalocean.com/account/api/tokens

---

### ⏳ "Downloading AI system" Takes Forever

**Problem**: Installation seems stuck at "Downloading AI system (4.5GB)..."

**This is normal!** The AI system is 4.5GB and can take 5-15 minutes to download depending on DigitalOcean's network speed.

**What you can do**:
- Check progress: `kubectl describe pod -n prospectml -l app.kubernetes.io/name=prospectml`
- Look for "Pulling image" events
- Be patient - it will complete!

---

### 🌐 No External IP Address

**Problem**: The script can't get an external IP address.

**Solution**:
1. Wait 2-3 more minutes (DigitalOcean takes time to provision)
2. Check manually:
   ```bash
   kubectl get svc -n prospectml
   ```
3. Look for the EXTERNAL-IP column
4. If it says `<pending>`, wait a bit more
5. If it never appears, check your DO account has Load Balancer quota

---

### 💥 Pods Keep Restarting

**Problem**: Pods show status like "CrashLoopBackOff" or keep restarting.

**Check the logs**:
```bash
kubectl logs -n prospectml -l app.kubernetes.io/name=prospectml --previous
```

**Common causes**:
- Wrong API key format
- Database connection issues
- Not enough memory (increase node size)

---

### 🔑 "API key cannot be empty"

**Problem**: You pressed Enter without typing an API key.

**Solution**:
1. Get your API key from: https://console.anthropic.com/api
2. Run the script again
3. Paste your API key when prompted (it will be hidden)

---

### 💾 "No space left on device"

**Problem**: Cluster runs out of disk space.

**Solution**:
1. Check node disk usage:
   ```bash
   kubectl describe nodes | grep -A5 "Allocated resources"
   ```
2. Delete old pods/images:
   ```bash
   kubectl delete pod --field-selector=status.phase=Failed -n prospectml
   ```
3. Consider adding more nodes or bigger nodes

---

### 🚪 Can't Access the Web Interface

**Problem**: The URL doesn't work in your browser.

**Check these**:
1. Is the pod running?
   ```bash
   kubectl get pods -n prospectml
   ```
2. Is the service working?
   ```bash
   curl -I http://YOUR_IP_HERE
   ```
3. Check firewall rules in DigitalOcean dashboard
4. Try a different browser or disable ad blockers

---

### 🗑 Need to Start Over?

**Complete cleanup**:
```bash
# Uninstall ProspectML
helm uninstall prospectml -n prospectml

# Delete the namespace
kubectl delete namespace prospectml

# Remove any stuck volumes
kubectl delete pvc --all -n prospectml
```

Then run the deploy script again!

---

### 📊 Checking Resource Usage

**See what's using resources**:
```bash
# Overall cluster usage
kubectl top nodes

# Pod usage
kubectl top pods -n prospectml

# Detailed pod info
kubectl describe pod -n prospectml
```

---

### 🆘 Still Need Help?

1. **Run the test script**:
   ```bash
   ./test-deployment.sh
   ```

2. **Collect debug info**:
   ```bash
   kubectl get all -n prospectml
   kubectl describe pods -n prospectml
   kubectl logs -n prospectml --all-containers=true
   ```

3. **Get help**:
   - Create an issue: https://github.com/AlgorithmicResearchGroup/Coding-Agent-For-Deployment/issues
   - Include the debug info above
   - Describe what you expected vs what happened

---

## 💡 Pro Tips

### Save Money
- Delete the cluster when not using it
- Use smaller nodes for testing
- Set resource limits lower in values.yaml

### Better Performance  
- Use bigger nodes (8GB+ RAM)
- Deploy closer to your location
- Enable autoscaling for nodes

### Security
- Change default passwords
- Use private clusters
- Enable RBAC policies
- Rotate API keys regularly

### Monitoring
- Set up alerts for pod failures
- Monitor API usage costs
- Track memory/CPU usage
- Check logs regularly