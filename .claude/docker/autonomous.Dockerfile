# Autonomous Claude Execution Container
# Provides isolated environment for --dangerously-skip-permissions execution

FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install base dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    jq \
    ca-certificates \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js (required for Claude CLI)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Claude CLI
RUN npm install -g @anthropic-ai/claude-code

# Create workspace directory
WORKDIR /workspace

# Git configuration for commits
RUN git config --global user.email "claude@autonomous.local" \
    && git config --global user.name "Claude Autonomous" \
    && git config --global init.defaultBranch main

# Environment variables for autonomous operation
ENV CLAUDE_AUTONOMOUS=1
ENV CLAUDE_SKIP_PERMISSIONS=1

# Health check - verify claude is available
RUN claude --version || echo "Claude CLI installed"

# Default entrypoint runs claude with passed arguments
ENTRYPOINT ["claude"]

# Default command shows help
CMD ["--help"]
