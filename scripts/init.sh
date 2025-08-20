#!/bin/bash

# Custom engine init stage script
# This script handles the initialization stage

echo "Running custom engine init stage..."
echo "Initializing Terraform configuration..."

terraform init

# Add your custom initialization logic here
# For example:
# - Validate configuration
# - Set up environment variables
# - Check prerequisites

echo "Init stage completed successfully!"
