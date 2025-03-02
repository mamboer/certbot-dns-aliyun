#!/bin/bash

# This script is called by certbot after successful certificate renewal
# $RENEWED_LINEAGE contains the path to the renewed certificate

echo "Certificate renewal successful for $RENEWED_LINEAGE"

# Create destination directory if it doesn't exist
mkdir -p /etc/letsencrypt/certs

# Copy all certificate files to the certs directory
echo "Copying certificates from $RENEWED_LINEAGE to /etc/letsencrypt/certs"
cp -L "$RENEWED_LINEAGE/fullchain.pem" "/etc/letsencrypt/certs/"
cp -L "$RENEWED_LINEAGE/privkey.pem" "/etc/letsencrypt/certs/"
cp -L "$RENEWED_LINEAGE/cert.pem" "/etc/letsencrypt/certs/"
cp -L "$RENEWED_LINEAGE/chain.pem" "/etc/letsencrypt/certs/"

# Set proper permissions
chmod 644 /etc/letsencrypt/certs/*.pem

# Execute host script if it exists and is executable
if [ -f "/host-scripts/post-certbot-renewal.sh" ] && [ -x "/host-scripts/post-certbot-renewal.sh" ]; then
    echo "Executing host post-certbot-renewal script..."
    /host-scripts/post-certbot-renewal.sh
    echo "Host post-certbot-renewal script executed with exit code: $?"
else
    echo "No executable host post-certbot-renewal script found at /host-scripts/post-certbot-renewal.sh"
fi

# Add custom actions here if needed
# For example: restart web server, send notification, etc.

echo "Deploy hook completed successfully"