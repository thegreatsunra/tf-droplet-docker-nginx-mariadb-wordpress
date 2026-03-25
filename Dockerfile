FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    shellcheck \
    curl \
    git \
    gnupg \
    python3 \
    python3-pip \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install OpenTofu
RUN curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh | \
    sh -s -- --install-method standalone --opentofu-version 1.11.5

# Install Go Task
RUN sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin

# Install Ansible, ansible-lint, and pre-commit
COPY ansible/requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir --break-system-packages -r /tmp/requirements.txt && \
    pip install --no-cache-dir --break-system-packages pre-commit

WORKDIR /project

# Pre-populate pre-commit hook environments at build time.
# Copied first so this layer is only invalidated when the config changes.
COPY .pre-commit-config.yaml .
RUN git init && pre-commit install-hooks

# Copy the full project
COPY . .

# Stage all files so pre-commit can discover them, and ensure scripts are executable
RUN chmod +x ansible/run-playbook.bash scripts/migrate-databases.bash scripts/migrate-wordpress.bash && git add -A

CMD ["sh", "-c", "task test && task lint"]
