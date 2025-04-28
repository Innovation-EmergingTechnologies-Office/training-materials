#!/bin/bash

# Check if required parameters are provided
if [ $# -lt 1 ]; then
    echo "Usage:"
    echo "  Create: $0 create <aws-profile> <subnet-id> <security-group-id> <keypair-name> [instance-name]"
    echo "  Delete: $0 delete <aws-profile> [instance-name]"
    echo "Examples:"
    echo "  $0 create myprofile subnet-1234abcd sg-5678efgh mykeypair custom-name"
    echo "  $0 create myprofile subnet-1234abcd sg-5678efgh mykeypair"
    echo "  $0 delete myprofile microk8s-instance"
    exit 1
fi

COMMAND="$1"
AWS_PROFILE="$2"
INSTANCE_NAME="${3:-microk8s-instance}"  # Default to 'microk8s-instance' if not provided

# Function to get user confirmation
confirm() {
    read -r -p "${1:-Are you sure? [y/N]} " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            true
            ;;
        *)
            false
            ;;
    esac
}

case "$COMMAND" in
    create)
        if [ $# -lt 5 ]; then
            echo "Error: Create command requires at least 5 parameters"
            echo "Usage: $0 create <aws-profile> <subnet-id> <security-group-id> <keypair-name> [instance-name]"
            exit 1
        fi
        # Assign parameters to variables
        SUBNET_ID="$3"
        SECURITY_GROUP_ID="$4"
        KEYPAIR_NAME="$5"
        # Generate default instance name if not provided
        CURRENT_DATE=$(date +%Y%m%d)
        INSTANCE_NAME="${6:-microk8s-$CURRENT_DATE}"
        
        # Set AWS profile
        export AWS_PROFILE="$AWS_PROFILE"
        
        echo "Deploying EC2 instance with the following parameters:"
        echo "AWS Profile: $AWS_PROFILE"
        echo "Instance Name: $INSTANCE_NAME"
        echo "Subnet ID: $SUBNET_ID"
        echo "Security Group ID: $SECURITY_GROUP_ID"
        echo "Keypair Name: $KEYPAIR_NAME"

        # Ubuntu 22.04 LTS AMI ID (may vary by region, this is for us-east-1)
        AMI_ID=$(aws ec2 describe-images \
            --owners 099720109477 \
            --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" "Name=state,Values=available" \
            --query "sort_by(Images, &CreationDate)[-1].ImageId" \
            --output text)

        echo "Using Ubuntu 22.04 AMI: $AMI_ID"

        # User data script to install microk8s
        USER_DATA=$(cat <<EOF
#!/bin/bash
apt-get update
apt-get upgrade -y

# Disable UFW firewall
ufw disable
systemctl disable ufw
systemctl stop ufw

# Continue with MicroK8s installation
snap install microk8s --classic
microk8s status --wait-ready
usermod -a -G microk8s ubuntu
chown -R ubuntu:ubuntu /home/ubuntu/.kube
microk8s enable dns dashboard storage ingress prometheus observability

# Create a systemd service for dashboard port-forwarding
cat << 'SERVICEEOF' > /etc/systemd/system/k8s-dashboard-proxy.service
[Unit]
Description=Kubernetes Dashboard Proxy
After=snap.microk8s.daemon-kubelite.service

[Service]
Type=simple
User=ubuntu
ExecStart=/snap/bin/microk8s kubectl port-forward -n kube-system service/kubernetes-dashboard 10443:443 --address 0.0.0.0
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICEEOF

# Create a systemd service for Grafana port-forwarding
cat << 'SERVICEEOF' > /etc/systemd/system/grafana-proxy.service
[Unit]
Description=Grafana Proxy
After=snap.microk8s.daemon-kubelite.service

[Service]
Type=simple
User=ubuntu
ExecStart=/snap/bin/microk8s kubectl port-forward -n observability service/kube-prom-stack-grafana 3000:80 --address 0.0.0.0
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICEEOF

# Enable and start the services
systemctl enable k8s-dashboard-proxy grafana-proxy
systemctl start k8s-dashboard-proxy grafana-proxy

echo "MicroK8s installation completed"
EOF
)

        # Launch EC2 instance without public IP
        echo "Launching EC2 instance without public IP..."
        INSTANCE_ID=$(aws ec2 run-instances \
            --image-id "$AMI_ID" \
            --instance-type t3.large \
            --key-name "$KEYPAIR_NAME" \
            --security-group-ids "$SECURITY_GROUP_ID" \
            --subnet-id "$SUBNET_ID" \
            --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":50,\"VolumeType\":\"gp3\"}}]" \
            --user-data "$USER_DATA" \
            --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" \
            --no-associate-public-ip-address \
            --query "Instances[0].InstanceId" \
            --output text)

        if [ -z "$INSTANCE_ID" ]; then
            echo "Failed to launch EC2 instance"
            exit 1
        fi

        echo "EC2 instance $INSTANCE_ID launched successfully"

        # Wait for instance to be running
        echo "Waiting for instance to be in running state..."
        aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

        # Get private IP address
        PRIVATE_IP=$(aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --query "Reservations[0].Instances[0].PrivateIpAddress" \
            --output text)

        echo "EC2 instance is now running"
        echo "Instance ID: $INSTANCE_ID"
        echo "Private IP: $PRIVATE_IP"
        echo ""
        echo "You can connect to the instance using a bastion host or VPN connection"
        echo "ssh -i /path/to/$KEYPAIR_NAME.pem ubuntu@$PRIVATE_IP"
        echo ""
        echo "MicroK8s is being installed. It may take a few minutes to complete."
        echo "After connecting, check installation status with: sudo microk8s status"
        echo ""
        echo "To access the Kubernetes Dashboard and Observability tools remotely:"
        echo ""
        echo "1. Check the services status with:"
        echo "   sudo systemctl status k8s-dashboard-proxy"
        echo "   sudo systemctl status grafana-proxy"
        echo ""
        echo "2. Retrieve the dashboard token with:"
        echo "   microk8s kubectl -n kube-system get secret \\"
        echo "     \$(microk8s kubectl -n kube-system get secret | grep default-token | awk '{print \$1}') \\"
        echo "     -o jsonpath=\"{.data.token}\" | base64 --decode"
        echo ""
        echo "3. Access the dashboard from your local machine at:"
        echo "   https://$PRIVATE_IP:10443"
        echo ""
        echo "4. Access Grafana (observability) from your local machine at:"
        echo "   http://$PRIVATE_IP:3000"
        echo "   (default username: admin, password: prom-operator)"
        echo ""
        echo "Note: Ensure your security group allows inbound traffic on ports 10443 and 3000"
        echo "      You may need to use a bastion host or VPN to reach the private IP address"
        ;;
        
    delete)
        if [ $# -lt 2 ]; then
            echo "Error: Delete command requires at least AWS profile"
            echo "Usage: $0 delete <aws-profile> [instance-name]"
            exit 1
        fi
        
        echo "Searching for instance '$INSTANCE_NAME' using AWS Profile: $AWS_PROFILE..."
        
        # Find instance by tag
        INSTANCE_ID=$(aws ec2 describe-instances \
            --profile "$AWS_PROFILE" \
            --filters "Name=tag:Name,Values=$INSTANCE_NAME" \
            --query "Reservations[0].Instances[0].InstanceId" \
            --output text)
        
        if [ -z "$INSTANCE_ID" ] || [ "$INSTANCE_ID" = "None" ]; then
            echo "No instance found with name: $INSTANCE_NAME"
            exit 1
        fi
        
        # Get instance details before deletion
        PRIVATE_IP=$(aws ec2 describe-instances \
            --profile "$AWS_PROFILE" \
            --instance-ids "$INSTANCE_ID" \
            --query "Reservations[0].Instances[0].PrivateIpAddress" \
            --output text)
            
        echo "Found instance:"
        echo "  Instance ID: $INSTANCE_ID"
        echo "  Private IP:  $PRIVATE_IP"
        echo "  Name:       $INSTANCE_NAME"
        
        if ! confirm "Do you want to terminate this instance? [y/N] "; then
            echo "Operation cancelled"
            exit 0
        fi
        
        echo "Terminating instance $INSTANCE_ID..."
        aws ec2 terminate-instances --profile "$AWS_PROFILE" --instance-ids "$INSTANCE_ID"
        
        echo "Waiting for instance termination..."
        aws ec2 wait instance-terminated --profile "$AWS_PROFILE" --instance-ids "$INSTANCE_ID"
        
        echo "Instance terminated successfully"
        ;;
    *)
        echo "Invalid command. Use 'create' or 'delete'"
        exit 1
        ;;
esac