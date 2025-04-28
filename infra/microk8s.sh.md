# MicroK8s EC2 Deployment Script
Bash script (`microk8s.sh`) for automating the deployment and management of an EC2 instance running MicroK8s on AWS. The script supports creating and deleting EC2 instances with MicroK8s pre-installed and configured.

## Features

- **Create Command**: Provisions an EC2 instance with MicroK8s installed and configured.
- **Delete Command**: Terminates an EC2 instance by name.
- **MicroK8s Configuration**:
  - Installs MicroK8s with essential add-ons (`dns`, `dashboard`, `storage`, `ingress`, `prometheus`, `observability`).
  - Sets up systemd services for port-forwarding:
    - Kubernetes Dashboard (`https://<private-ip>:10443`)
    - Grafana (`http://<private-ip>:3000`)
- **Firewall Management**: Disables UFW on the instance to avoid conflicts with MicroK8s.
- **AWS Integration**:
  - Uses AWS CLI to manage EC2 instances.
  - Supports specifying AWS profiles for authentication.

## Prerequisites

1. **AWS CLI**: Ensure the AWS CLI is installed and configured with the required profiles.
2. **Bash Shell**: The script is designed to run in a Bash shell environment.
3. **IAM Permissions**: The AWS profile used must have permissions to manage EC2 instances.
4. **Key Pair**: Ensure you have an existing AWS key pair for SSH access to the instance.

## Usage

### General Syntax

```bash
microk8s.sh <command> <aws-profile> <subnet-id> <security-group-id> <keypair-name> [instance-name]
```

### Commands

#### Create

Provisions a new EC2 instance with MicroK8s installed.

```bash
./microk8s.sh create <aws-profile> <subnet-id> <security-group-id> <keypair-name> [instance-name]
```

- **Parameters**:
  - `<aws-profile>`: The AWS CLI profile to use.
  - `<subnet-id>`: The ID of the subnet where the instance will be launched.
  - `<security-group-id>`: The ID of the security group to associate with the instance.
  - `<keypair-name>`: The name of the AWS key pair for SSH access.
  - `[instance-name]`: (Optional) The name of the instance. Defaults to `microk8s-<current-date>`.

- **Example**:
  ```bash
  ./microk8s.sh create myprofile subnet-1234abcd sg-5678efgh mykeypair custom-instance
  ```

#### Delete

Terminates an existing EC2 instance by name.

```bash
./microk8s.sh delete <aws-profile> [instance-name]
```

- **Parameters**:
  - `<aws-profile>`: The AWS CLI profile to use.
  - `[instance-name]`: The name of the instance to delete.

- **Example**:
  ```bash
  ./microk8s.sh delete myprofile custom-instance
  ```

### Outputs

After creating an instance, the script provides:
- The instance Name, ID and private IP address.
- Instructions to connect to the instance via SSH.
- Instructions to access the Kubernetes Dashboard and Grafana.

### Notes

- Ensure your security group allows inbound traffic on ports `10443` and `3000` for accessing the Kubernetes Dashboard and Grafana.
- Use a bastion host or VPN to connect to the private IP address if the instance does not have a public IP.
