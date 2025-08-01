FROM codercom/code-server:latest

USER root

# Update system packages and install essential tools
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    gnupg \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js and npm (using NodeSource repository for latest LTS)
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get update && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install .NET SDK
RUN wget https://dot.net/v1/dotnet-install.sh && \
    chmod +x dotnet-install.sh && \
    ./dotnet-install.sh -c LTS --install-dir /usr/share/dotnet && \
    ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet && \
    rm dotnet-install.sh

# Add .NET to PATH for all users
RUN echo 'export PATH="$PATH:/usr/share/dotnet"' >> /etc/bash.bashrc

# Install global npm packages
RUN npm install -g \
    typescript \
    ts-node \
    nodemon \
    prettier \
    eslint \
    @angular/cli \
    create-react-app \
    vite \
    concurrently

# Switch back to coder user for .NET tools installation
USER coder

# Install .NET global tools
RUN dotnet tool install --global dotnet-ef && \
    dotnet tool install --global dotnet-aspnet-codegenerator

# Pre-install VS Code extensions
RUN code-server --install-extension ms-vscode.vscode-typescript-next && \
    code-server --install-extension ms-dotnettools.csharp && \
    code-server --install-extension ms-dotnettools.vscode-dotnet-runtime && \
    code-server --install-extension bradlc.vscode-tailwindcss && \
    code-server --install-extension esbenp.prettier-vscode && \
    code-server --install-extension ms-vscode.vscode-json && \
    code-server --install-extension ms-vscode.vscode-eslint

# Create .vscode directory and copy settings if they exist
RUN mkdir -p /home/coder/workspace/.vscode

# Copy VS Code settings (only if the directory exists)
COPY --chown=coder:coder vscode-settings/ /home/coder/workspace/.vscode/ 2>/dev/null || true

# Set up environment variables
ENV NODE_ENV=development \
    DOTNET_ENVIRONMENT=Development \
    ASPNETCORE_URLS=http://localhost:5000 \
    PATH="${PATH}:/home/coder/.dotnet/tools"

WORKDIR /home/coder/workspace

# Expose ports for code-server and development servers
EXPOSE 8080 3000 5000 5001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080 || exit 1

CMD ["code-server", "--bind-addr", "0.0.0.0:8080", "--auth", "none"]
