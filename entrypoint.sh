#!/bin/bash

# Load environment variables from .env file if it exists
if [ -f "/.env" ]; then
    echo "Loading environment variables from /.env file"
    while IFS='=' read -r key value || [ -n "$key" ]; do
        # Skip comments and empty lines
        [[ $key =~ ^#.*$ ]] || [ -z "$key" ] && continue
        # Remove leading/trailing whitespace
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        # Only set if not already set from command line
        if [ -z "${!key}" ]; then
            export "$key"="$value"
            echo "Set $key from .env file"
        else
            echo "$key already set, using existing value"
        fi
    done < /.env
fi

# Check required environment variables
if [ -z "$REGION" ] || [ -z "$ACCESS_KEY_ID" ] || [ -z "$ACCESS_KEY_SECRET" ] || [ -z "$DOMAINS" ] || [ -z "$EMAIL" ]; then
    echo "Error: Missing required environment variables. Please set: REGION, ACCESS_KEY_ID, ACCESS_KEY_SECRET, DOMAINS, EMAIL"
    exit 1
fi

# Activate the virtual environment
source /opt/venv/bin/activate

# Configure Aliyun CLI
aliyun configure set --profile akProfile --mode AK --region $REGION --access-key-id $ACCESS_KEY_ID --access-key-secret $ACCESS_KEY_SECRET

# Function to parse domains and build certbot command
process_domains() {
    local domains_array
    # Parse comma-separated list of domains
    IFS=',' read -ra domains_array <<< "$DOMAINS"

    local domain_params=""
    for domain in "${domains_array[@]}"; do
        # Trim whitespace
        domain=$(echo "$domain" | xargs)
        # Add the primary domain
        domain_params="$domain_params -d $domain"
        
        # Extract the base domain for wildcard
        # For example, for "sub.example.com", extract "example.com"
        base_domain=$(echo "$domain" | grep -oP '(^|\.)([^.]+\.[^.]+)$' | sed 's/^\.//')
        
        if [[ "$base_domain" == "$domain" ]]; then
            # If it's a top-level domain, add wildcard
            domain_params="$domain_params -d *.$domain"
        fi
    done
    
    echo $domain_params
}

# Main execution
if [ "$1" == "renew" ]; then
    echo "Renewing certificates..."
    certbot renew --manual --preferred-challenges dns \
        --manual-auth-hook "/usr/local/bin/alidns" \
        --manual-cleanup-hook "/usr/local/bin/alidns clean" \
        --agree-tos --email $EMAIL \
        --deploy-hook "/usr/local/bin/deploy-hook.sh"
    
    exit $?
fi

# Get domain parameters
DOMAIN_PARAMS=$(process_domains)

# Obtain the certificates for all domains
echo "Obtaining certificates for $DOMAIN_PARAMS"
certbot certonly $DOMAIN_PARAMS --manual --preferred-challenges dns \
    --manual-auth-hook "/usr/local/bin/alidns" \
    --manual-cleanup-hook "/usr/local/bin/alidns clean" \
    --agree-tos --email $EMAIL --non-interactive \
    --deploy-hook "/usr/local/bin/deploy-hook.sh"

# Start cron daemon
crond -f -l 2
