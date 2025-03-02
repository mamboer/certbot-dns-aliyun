FROM alpine:latest

# Install dependencies
RUN apk --no-cache add wget tar sudo certbot bash python3 py3-pip jq && \
    apk --no-cache add --virtual build-dependencies gcc musl-dev python3-dev libffi-dev openssl-dev make

# Install aliyun-cli
RUN wget https://aliyuncli.alicdn.com/aliyun-cli-linux-latest-amd64.tgz && \
    tar xzvf aliyun-cli-linux-latest-amd64.tgz && \
    mv aliyun /usr/local/bin && \
    rm aliyun-cli-linux-latest-amd64.tgz

# Copy and install certbot-dns-aliyun plugin
RUN wget https://cdn.jsdelivr.net/gh/justjavac/certbot-dns-aliyun@main/alidns.sh && \
    mv alidns.sh /usr/local/bin/alidns && \
    chmod +x /usr/local/bin/alidns

# Create virtual environment for Python packages
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install Python dependencies in virtual environment
RUN pip install --upgrade pip && \
    pip install aliyun-python-sdk-core aliyun-python-sdk-alidns

# Copy scripts
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY deploy-hook.sh /usr/local/bin/deploy-hook.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/deploy-hook.sh

# Set environment variables (to be provided during runtime)
ENV REGION=""
ENV ACCESS_KEY_ID=""
ENV ACCESS_KEY_SECRET=""
# Domains separated by comma (e.g. example.com,test.domain.com)
ENV DOMAINS=""
ENV EMAIL=""
ENV CRON_SCHEDULE="0 0 * * *"

# Note: All the above environment variables can also be provided via a .env file
# mounted at /.env in the container. Command line environment variables take precedence.

# Setup cron job for certbot renew
RUN echo "$CRON_SCHEDULE /usr/local/bin/entrypoint.sh renew" > /etc/crontabs/root

# Create directory for certificates
RUN mkdir -p /etc/letsencrypt/certs

# Make sure cron is running
RUN touch /var/log/cron.log

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
