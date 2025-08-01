FROM codercom/code-server:latest

USER root

# Update system packages and install nginx
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    gnupg \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    git \
    build-essential \
    nginx \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js and npm (using NodeSource repository for latest version)
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && \
    sudo apt-get install -y nodejs

# Install .NET SDK
RUN wget https://dot.net/v1/dotnet-install.sh \
    && chmod +x dotnet-install.sh \
    && sudo ./dotnet-install.sh -c LTS --install-dir /usr/share/dotnet \
    && sudo ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet

# Add .NET to PATH for all users
RUN echo 'export PATH="$PATH:/usr/share/dotnet"' | sudo tee -a /etc/bash.bashrc

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

# Install .NET global tools
RUN dotnet tool install --global dotnet-ef \
    && dotnet tool install --global dotnet-aspnet-codegenerator

# Switch back to coder user
USER coder

# Set up environment variables
ENV NODE_ENV=development
ENV DOTNET_ENVIRONMENT=Development
ENV ASPNETCORE_URLS=http://localhost:5000
ENV PATH="${PATH}:/home/coder/.dotnet/tools"

# Pre-install VS Code extensions
RUN code-server --install-extension ms-vscode.vscode-typescript-next \
    && code-server --install-extension ms-dotnettools.csharp \
    && code-server --install-extension ms-dotnettools.vscode-dotnet-runtime \
    && code-server --install-extension bradlc.vscode-tailwindcss \
    && code-server --install-extension esbenp.prettier-vscode \
    && code-server --install-extension ms-vscode.vscode-json \
    && code-server --install-extension ms-vscode.vscode-eslint

COPY --chown=coder:coder vscode-settings/ /home/coder/workspace/.vscode/

WORKDIR /home/coder/workspace

EXPOSE 8080 3000 5000 5001

CMD ["code-server", "--bind-addr", "0.0.0.0:8080", "--auth", "none"]
