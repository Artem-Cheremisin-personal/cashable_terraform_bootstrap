# Prerequisites for Terraform/Terragrunt Project

This document outlines the necessary prerequisites and setup steps to run the Terraform and Terragrunt configuration in this repository.

## 1. Required Tools

Ensure you have the following tools installed on your local machine.

### Installation for macOS (using Homebrew)

If you don't have Homebrew, you can install it from [https://brew.sh/](https://brew.sh/).

```bash
# Install Terraform
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Install Terragrunt
brew install terragrunt

# Install AWS CLI
brew install awscli

# Install Puppet (Optional)
brew install puppet
```

### Installation for Ubuntu (using apt)

```bash
# Update package list
sudo apt-get update

# Install prerequisites
sudo apt-get install -y gnupg software-properties-common curl wget unzip

# --- Install Terraform ---
# Add HashiCorp GPG key
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
# Add HashiCorp repository
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
# Install Terraform
sudo apt-get update
sudo apt-get install -y terraform

# --- Install Terragrunt ---
# Download the latest Terragrunt binary
wget https://github.com/gruntwork-io/terragrunt/releases/download/v0.58.10/terragrunt_linux_amd64
# Make it executable and move to path
chmod +x terragrunt_linux_amd64
sudo mv terragrunt_linux_amd64 /usr/local/bin/terragrunt

# --- Install AWS CLI ---
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# --- Install Puppet (Optional) ---
# Download the appropriate release package for your Ubuntu version (e.g., focal for 20.04)
wget https://apt.puppet.com/puppet7-release-focal.deb
sudo dpkg -i puppet7-release-focal.deb
sudo apt-get update
sudo apt-get install -y puppet-agent
# Add Puppet to your PATH
export PATH="/opt/puppetlabs/bin:$PATH"
```

## 2. AWS Credentials Configuration

Terraform needs to be authenticated to your AWS account to create, modify, or destroy resources.

1.  **Configure the AWS CLI**: Run the following command and provide your AWS Access Key ID, Secret Access Key, and default region when prompted.

    ```bash
    aws configure
    ```

2.  **Verify Configuration**: You can verify that your credentials are set up correctly by running:

    ```bash
    aws sts get-caller-identity
    ```

    This command should return your Account ID, User ID, and ARN.

## 3. Project Structure

The project is organized using a standard Terragrunt structure:

-   `live/`: Contains the top-level Terragrunt configurations for each environment (e.g., `dev`, `staging`, `prod`). This is where you will run `terragrunt` commands.
-   `modules/`: Contains reusable Terraform modules that define the infrastructure components (e.g., VPC, EC2 instances, Puppet server).

## 4. Deployment Options

### Option 1: Deploy Everything at Once (Recommended)

Terragrunt can automatically resolve dependencies and deploy all modules:
But I **strongly recommend** is to deploy every module 1 by 1 or, at least, **VPN** separately, because sometimes it might take a while to deploy associations rule which eventually might timeout. 

```bash
cd live
terragrunt run-all apply
```

### Option 2: Manual Deployment Order

If you prefer to deploy modules individually, use this exact order due to dependencies:

1. **VPC** - Network foundation
   ```bash
   cd live/vpc && terragrunt apply
   ```

2. **Route53** - DNS management
   ```bash
   cd live/route53 && terragrunt apply
   ```

3. **IAM** - Identity and access management
   ```bash
   cd live/iam && terragrunt apply
   ```

4. **Aurora** - PostgreSQL database
   ```bash
   cd live/aurora_postgress && terragrunt apply
   ```

5. **Puppet** - Configuration management server
   ```bash
   cd live/puppet && terragrunt apply
   ```

6. **App LB** - Application load balancer
   ```bash
   cd live/app_lb && terragrunt apply
   ```

7. **App** - Application servers
   ```bash
   cd live/app && terragrunt apply
   ```

8. **Nginx LB** - Nginx load balancer
   ```bash
   cd live/nginx_lb && terragrunt apply
   ```

9. **Nginx** - Nginx servers
   ```bash
   cd live/nginx && terragrunt apply
   ```

10. **VPN** - Client VPN for secure database access
    ```bash
    cd live/vpn && terragrunt apply
    ```

## 5. VPN Client Configuration

After VPN deployment, generate the client configuration:

```bash
cd live/vpn
terragrunt output -raw complete_ovpn_config > client.ovpn
```

Import `client.ovpn` into your OpenVPN client to connect and access the database.

## 6. Cleanup

To destroy, reverse the order:

```bash
# VPN → Nginx → Nginx LB → App → App LB → Puppet → Aurora → IAM → Route53 → VPC
cd live/vpn && terragrunt destroy
cd live/nginx && terragrunt destroy
cd live/nginx_lb && terragrunt destroy
cd live/app && terragrunt destroy
cd live/app_lb && terragrunt destroy
cd live/puppet && terragrunt destroy
cd live/aurora_postgress && terragrunt destroy
cd live/iam && terragrunt destroy
cd live/route53 && terragrunt destroy
cd live/vpc && terragrunt destroy
```
