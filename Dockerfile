FROM mcr.microsoft.com/azurelinux/base/core:3.0

ARG TF_VERSION=1.13.5
ARG YQ_VERSION=v4.42.1
ARG NODE_VERSION=18.19.1
ARG ANSIBLE_VERSION=2.16.5

# Set proper locale for Ansible

# Install core utilities and system tools
RUN tdnf install -y \
  sshpass \
  ca-certificates \
  curl \
  gawk \
  glibc-i18n \
  jq \
  openssl-devel \
  openssl-libs \
  sudo \
  tar \
  unzip \
  util-linux \
  acl \
  which \
  wget \
  zip \
  rsync \
  less \
  findutils \
  python3-devel \
  gcc \
  make && \
  tdnf clean all

# Setup locales properly
RUN localedef -i en_US -f UTF-8 en_US.UTF-8

# Install development tools and languages
RUN tdnf install -y \
  dotnet-sdk-8.0 \
  python3 \
  python3-pip \
  python3-virtualenv \
  powershell \
  git \
  gh && \
  tdnf clean all

# Install Terraform
RUN curl -fsSo terraform.zip \
 https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip && \
 unzip terraform.zip && \
  install -Dm755 terraform /usr/bin/terraform && \
  rm -f terraform terraform.zip

# Install Azure CLI
RUN rpm --import https://packages.microsoft.com/keys/microsoft.asc && \
    echo -e "[azure-cli]\nname=Azure CLI\nbaseurl=https://packages.microsoft.com/yumrepos/azure-cli\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo && \
    tdnf install -y azure-cli && \
    tdnf clean all

# Install Node.js
RUN curl -fsSL https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz | tar -xz -C /usr/local --strip-components=1 && \
  ln -s /usr/local/bin/node /usr/bin/node && \
  ln -s /usr/local/bin/npm /usr/bin/npm

# Install yq, as there are two competing versions and Azure Linux uses the jq wrappers, which breaks the GitHub Workflows
RUN curl -sSfL https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64.tar.gz | tar zx && \
  install -Dm755 yq_linux_amd64 /usr/bin/yq && \
  rm -rf yq_linux_amd64.tar.gz yq_linux_amd64 install-man-page.sh yq.1

# Set locales in environment file
RUN echo "LC_ALL=en_US.UTF-8" >> /etc/environment && \
    echo "LANG=en_US.UTF-8" >> /etc/environment

# Install Python dependencies and Ansible with required collections
RUN pip3 install --no-cache-dir \
    ansible-core==${ANSIBLE_VERSION} \
    argcomplete \
    jmespath \
    netaddr \
    pywinrm \
    setuptools \
    wheel \
    chmod \
    pyyaml

COPY SAP-automation-samples /source/SAP-automation-samples

COPY . /source

ENV SAP_AUTOMATION_REPO_PATH=/source
ENV SAMPLE_REPO_PATH=/source/SAP-automation-samples

RUN useradd -m -s /bin/bash azureadm && \
    usermod -aG sudo azureadm && \
    passwd -d azureadm && \
    echo "export LC_ALL=en_US.UTF-8" >> /home/azureadm/.bashrc && \
    echo "export LANG=en_US.UTF-8" >> /home/azureadm/.bashrc
# Password for azureadm user is not set. Use SSH key-based authentication or set password securely at runtime.

# Configure SSH for Ansible (both root and azureadm)
RUN mkdir -p /root/.ssh /home/azureadm/.ssh && \
    chmod 700 /root/.ssh /home/azureadm/.ssh && \
    echo "Host *\n  StrictHostKeyChecking no\n  UserKnownHostsFile=/dev/null" > /root/.ssh/config && \
    echo "Host *\n  StrictHostKeyChecking no\n  UserKnownHostsFile=/dev/null" > /home/azureadm/.ssh/config && \
    chmod 600 /root/.ssh/config /home/azureadm/.ssh/config && \
    chown -R azureadm:azureadm /home/azureadm/.ssh

# Set ownership of source directory to azureadm
RUN chown -R azureadm:azureadm /source

WORKDIR /source

USER azureadm

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD terraform version && ansible --version && az version || exit 1
