# Working with the Container registry - https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry
# Creating a Docker container action - https://docs.github.com/en/actions/creating-actions/creating-a-docker-container-action
# Manual deploy:
# --------------
#  docker build -t ghcr.io/3dhdsoft/SonarscanEx:1.0.0 .
#  docker inspect ghcr.io/3dhdsoft/SonarscanEx
#  docker image ls ghcr.io/3dhdsoft/SonarscanEx
#  echo $Env:GH_PKG_TOKEN | docker login ghcr.io/3dhdsoft -u 3dhdsoft --password-stdin
#  docker push ghcr.io/3dhdsoft/SonarscanEx:1.0.0
#  docker rmi ghcr.io/3dhdsoft/SonarscanEx:1.0.0

# Build local Docker image
# docker build -t SonarscanEx .
# Execute Docker container
# docker run --name SonarscanEx -w /github/workspace --rm \
#   -e INPUT_SONARORGANIZATION \
#   -e INPUT_SONARPROJECTNAME \
#   -e INPUT_SONARPROJECTKEY \
#   -e INPUT_SONARHOSTNAME \
#   -e INPUT_SONARBEGINARGUMENTS \
#   -e INPUT_DOTNETPREBUILDCMD \
#   -e INPUT_DOTNETBUILDARGUMENTS \
#   -e INPUT_DOTNETTESTARGUMENTS \
#   -e INPUT_DOTNETDISABLETESTS \
#   -e INPUT_GITHUBRUNNUMBER \
#   -e GH_PKG_TOKEN \
#   -e SONAR_TOKEN \
#   -e GITHUB_EVENT_NAME \
#   -e GITHUB_REPOSITORY \
#   -e GITHUB_REF \
#   -e GITHUB_HEAD_REF \
#   -e GITHUB_BASE_REF \
#   -v "/var/run/docker.sock":"/var/run/docker.sock" \
#   -v $(pwd):"/github/workspace" \
#   SonarscanEx

FROM mcr.microsoft.com/dotnet/sdk:8.0

LABEL com.github.actions.name SonarscanEx
LABEL com.github.actions.description "SonarScanner for .NET."
LABEL com.github.actions.icon check-square
LABEL com.github.actions.color blue
LABEL org.opencontainers.image.source https://github.com/3DHDSoft/SonarscanEx
LABEL org.opencontainers.image.description "SonarScanner for .NET."
LABEL org.opencontainers.image.version v1.0.0
LABEL org.opencontainers.image.licenses MIT
LABEL repository https://github.com/3DHDSoft/SonarscanEx
LABEL homepage https://github.com/3DHDSoft/SonarscanEx
LABEL maintainer 3DHDSoft

# Version numbers of used software
ENV SONAR_SCANNER_DOTNET_TOOL_VERSION=6.2.0 \
    DOTNETCORE_RUNTIME_VERSION=8.0 \
    NODE_VERSION=21 \
    JRE_VERSION=17

# Add Microsoft Debian apt-get feed
RUN wget https://packages.microsoft.com/config/debian/10/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && dpkg -i packages-microsoft-prod.deb

# Update ans install HTTPS support
RUN apt-get update -y && \
    apt-get install --no-install-recommends -y apt-transport-https

# Install gh (GitHub CLI)
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
  chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
  apt-get update -y

# Install gh (GitHub CLI) - https://github.com/cli/cli/blob/trunk/docs/install_linux.md#debian-ubuntu-linux-raspberry-pi-os-apt
RUN apt-get install --no-install-recommends -y gh

# Install jq
RUN apt-get install --no-install-recommends -y jq

# Fix JRE Install https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=863199
RUN mkdir -p /usr/share/man/man1

# Install the .NET Runtime for SonarScanner
RUN apt-get install --no-install-recommends -y aspnetcore-runtime-$DOTNETCORE_RUNTIME_VERSION

# Install NodeJS
RUN apt-get install --no-install-recommends -y dirmngr gnupg apt-transport-https ca-certificates software-properties-common && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_VERSION.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    apt-get update -y && \
    apt-get install --no-install-recommends -y nodejs

# Install Java Runtime for SonarScanner
RUN apt-get install --no-install-recommends -y openjdk-$JRE_VERSION-jre

# Install SonarScanner .NET global tool
RUN dotnet tool install dotnet-sonarscanner --tool-path . --version $SONAR_SCANNER_DOTNET_TOOL_VERSION

# Install Mono for .NET Framework (Legacy) - https://linuxize.com/post/how-to-install-mono-on-ubuntu-20-04/
# RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF && \
#     echo "deb https://download.mono-project.com/repo/debian stable-buster main" | tee /etc/apt/sources.list.d/mono-official-stable.list && \
#     apt-get update -y && \
#     apt-get install --no-install-recommends -y mono-devel

# Cleanup
RUN apt-get -q -y autoremove && \
    apt-get -q clean -y && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
