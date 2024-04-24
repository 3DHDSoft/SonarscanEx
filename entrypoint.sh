#!/bin/bash -l
set -o pipefail
set -eu

# Creating a Docker container action - https://docs.github.com/en/actions/creating-actions/creating-a-docker-container-action
# Make entrypoint.sh file executable:
#  git update-index --chmod=+x entrypoint.sh
#
# Check permission (it should start with 100755 where 755 are the attributes for an exexutable file):
#  git ls-files -s entrypoint.sh

# Check required parameters has a value
if [ -z "$INPUT_SONARPROJECTKEY" ]; then
  echo "Input parameter sonarProjectKey is required"
  exit 1
fi
if [ -z "$INPUT_SONARPROJECTNAME" ]; then
  echo "Input parameter sonarProjectName is required"
  exit 1
fi
if [ -z "$GH_PKG_TOKEN" ]; then
  echo "Environment parameter GH_PKG_TOKEN is required"
  exit 1
fi
if [ -z "$SONAR_TOKEN" ]; then
  echo "Environment parameter SONAR_TOKEN is required"
  exit 1
fi

# List Environment variables that's set by Github Action input parameters (defined by user)
echo "Github Action input parameters"
echo "INPUT_SONARORGANIZATION: $INPUT_SONARORGANIZATION"
echo "INPUT_SONARPROJECTNAME: $INPUT_SONARPROJECTNAME"
echo "INPUT_SONARPROJECTKEY: $INPUT_SONARPROJECTKEY"
echo "INPUT_SONARHOSTNAME: $INPUT_SONARHOSTNAME"
echo "INPUT_SONARBEGINARGUMENTS: $INPUT_SONARBEGINARGUMENTS"
echo "INPUT_DOTNETPREBUILDCMD: $INPUT_DOTNETPREBUILDCMD"
echo "INPUT_DOTNETBUILDARGUMENTS: $INPUT_DOTNETBUILDARGUMENTS"
echo "INPUT_DOTNETTESTARGUMENTS: $INPUT_DOTNETTESTARGUMENTS"
echo "INPUT_DOTNETDISABLETESTS: $INPUT_DOTNETDISABLETESTS"
echo "INPUT_GITHUBRUNNUMBER: $INPUT_GITHUBRUNNUMBER"

# Environment variables that need to be mapped in Github Action
#     env:
#       GH_PKG_TOKEN: "${{ secrets.GH_PKG_TOKEN }}"
#       SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
#       GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
#
# GH_PKG_TOKEN=[github_pkg_token]
# SONAR_TOKEN=[sonarqube_token]
# GITHUB_TOKEN=[github_token]

# Environment variables automatically set by Github Actions automatically passed on to the docker container
#
# Example pull request
# GITHUB_REPOSITORY=owner/repo
# GITHUB_EVENT_NAME=pull_request
# GITHUB_REF=refs/pull/1/merge
# GITHUB_HEAD_REF=somenewcodewithouttests
# GITHUB_BASE_REF=main
#
# Example normal push
# GITHUB_REPOSITORY=owner/repo
# GITHUB_EVENT_NAME="push"
# GITHUB_REF=refs/heads/main
# GITHUB_HEAD_REF=""
# GITHUB_BASE_REF=""

# ---------------------------------------------
# DEBUG: How to run container manually
# ---------------------------------------------
# export GH_PKG_TOKEN=[github_pkg_token]
# export SONAR_TOKEN="sonarqube_token"

# Simulate Github Action input variables
# export INPUT_SONARORGANIZATION="organization"
# export INPUT_SONARPROJECTNAME="projectname"
# export INPUT_SONARPROJECTKEY="projectkey"
# export INPUT_SONARHOSTNAME="https://sonarcloud.io"
# export INPUT_SONARBEGINARGUMENTS=""
# export INPUT_DOTNETPREBUILDCMD=""
# export INPUT_DOTNETBUILDARGUMENTS=""
# export INPUT_DOTNETTESTARGUMENTS=""
# export INPUT_DOTNETDISABLETESTS=""
# export INPUT_GITHUBRUNNUMBER=""

# Simulate Github Action built-in environment variables
# export GITHUB_REPOSITORY=owner/repo
# export GITHUB_EVENT_NAME="push"
# export GITHUB_REF=refs/heads/main
# export GITHUB_SHA="GUID (40 char)"
# export GITHUB_HEAD_REF=""
# export GITHUB_BASE_REF=""
#
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
#   -e GITHUB_SHA \
#   -e GITHUB_HEAD_REF \
#   -e GITHUB_BASE_REF \
#   -v "/var/run/docker.sock":"/var/run/docker.sock" \
#   -v $(pwd):"/github/workspace" \
#   SonarscanEx

#-----------------------------------
# Build Sonarscanner begin command
#-----------------------------------
sonar_begin_cmd="/dotnet-sonarscanner begin /k:\"${INPUT_SONARPROJECTKEY}\" /n:\"${INPUT_SONARPROJECTNAME}\" /d:sonar.token=\"${SONAR_TOKEN}\" /d:sonar.host.url=\"${INPUT_SONARHOSTNAME}\""
if [ -n "$INPUT_SONARORGANIZATION" ]; then
  sonar_begin_cmd="$sonar_begin_cmd /o:\"${INPUT_SONARORGANIZATION}\""
fi
if [ -n "$INPUT_SONARBEGINARGUMENTS" ]; then
  sonar_begin_cmd="$sonar_begin_cmd $INPUT_SONARBEGINARGUMENTS"
fi

# Check Github environment variable GITHUB_EVENT_NAME to determine if this is a pull request or not.
if [[ $GITHUB_EVENT_NAME == 'pull_request' ]]; then
  # Sonarqube wants these variables if build is started for a pull request
  # Sonarcloud parameters: https://sonarcloud.io/documentation/analysis/pull-request/
  # sonar.pullrequest.key               Unique identifier of your PR. Must correspond to the key of the PR in GitHub or TFS. E.G.: 5
  # sonar.pullrequest.branch            The name of your PR Ex: feature/my-new-feature
  # sonar.pullrequest.base              The long-lived branch into which the PR will be merged. Default: main E.G.: main
  # sonar.pullrequest.github.repository SLUG of the GitHub Repo (owner/repo)

  # Extract Pull Request numer from the GITHUB_REF variable
  PR_NUMBER=$(echo $GITHUB_REF | awk 'BEGIN { FS = "/" } ; { print $3 }')

  # Add pull request specific parameters in sonar scanner
  sonar_begin_cmd="$sonar_begin_cmd /d:sonar.pullrequest.key=$PR_NUMBER /d:sonar.pullrequest.branch=$GITHUB_HEAD_REF /d:sonar.pullrequest.base=$GITHUB_BASE_REF /d:sonar.pullrequest.github.repository=$GITHUB_REPOSITORY /d:sonar.pullrequest.provider=github"
fi

#-----------------------------------
# Build Sonarscanner end command
#-----------------------------------
sonar_end_cmd="/dotnet-sonarscanner end /d:sonar.token=\"${SONAR_TOKEN}\""

#-----------------------------------
# Build pre build command
#-----------------------------------
dotnet_prebuild_cmd="echo NO_PREBUILD_CMD"
if [ -n "$INPUT_DOTNETPREBUILDCMD" ]; then
  dotnet_prebuild_cmd="$INPUT_DOTNETPREBUILDCMD"
fi

#-----------------------------------
# Build dotnet build command
#-----------------------------------
dotnet_build_cmd="dotnet build"
if [ -n "$INPUT_DOTNETBUILDARGUMENTS" ]; then
  dotnet_build_cmd="$dotnet_build_cmd $INPUT_DOTNETBUILDARGUMENTS"
fi

#-----------------------------------
# Build dotnet test command
#-----------------------------------
dotnet_test_cmd="dotnet test"
if [ -n "$INPUT_DOTNETTESTARGUMENTS" ]; then
  dotnet_test_cmd="$dotnet_test_cmd $INPUT_DOTNETTESTARGUMENTS"
fi

#-----------------------------------
# Get GitHub run number
#-----------------------------------
is_first_run=false
if [ -n "$INPUT_GITHUBRUNNUMBER" -a $INPUT_GITHUBRUNNUMBER == "1" ]; then
  is_first_run=true
  echo "First GitHub Action run."
fi

#-----------------------------------
# Execute shell commands
#-----------------------------------
echo "Shell commands"

# Run Sonarscanner .NET Core "begin" command
echo "sonar_begin_cmd: $sonar_begin_cmd"
sh -c "$sonar_begin_cmd"

# Run dotnet pre build command
echo "dotnet_prebuild_cmd: $dotnet_prebuild_cmd"
sh -c "${dotnet_prebuild_cmd}"

# Run dotnet build command
echo "dotnet_build_cmd: $dotnet_build_cmd"
sh -c "${dotnet_build_cmd}"

# Run dotnet test command (unless user choose not to)
if ! [[ "${INPUT_DOTNETDISABLETESTS,,}" == "true" || "${INPUT_DOTNETDISABLETESTS}" == "1" ]]; then
  echo "dotnet_test_cmd: $dotnet_test_cmd"
  sh -c "${dotnet_test_cmd}"
fi

# Run Sonarscanner .NET Core "end" command
echo "sonar_end_cmd: $sonar_end_cmd"
sh -c "$sonar_end_cmd"

# After the first commit and GitHub actions run SonarCloud will show 'Not computed. The next scan will generate a Quality Gate'.
# This is normal and expected. To fix this trigger an extra scan if the first GithHub Action run.
#  - Main Branch Status - https://docs.sonarsource.com/sonarcloud/getting-started/first-analysis/#main-branch-status
#  - Part 2: Automating code quality scanning using Sonar Cloud and GitHub Actions - https://community.ops.io/jei/part-2-automating-code-quality-scanning-using-sonar-cloud-and-github-actions-2322
if [ is_first_run ]; then
  sh -c "$sonar_end_cmd"
fi


#--------------------------------------
# Get SonarCloud Code Analysis html url
#--------------------------------------
# Login to GitHub api
#echo $GH_PKG_TOKEN | gh auth login --with-token

# Get Commit info
GH_BASEURL=https://api.github.com
echo "GH_BASEURL: $GH_BASEURL"
echo "GITHUB_REPOSITORY: $GITHUB_REPOSITORY"
echo "GITHUB_SHA: $GITHUB_SHA"

echo "gh_sha=$GITHUB_SHA" >>$GITHUB_OUTPUT

# GitHub API
GH_API=$GH_BASEURL/repos/$GITHUB_REPOSITORY/commits/$GITHUB_SHA/check-runs # GitHub API - https://docs.github.com/en/rest?apiVersion=2022-11-28
echo "GH_API: $GH_API"

json_data=$(curl --get -Ss -H "Authorization:Bearer ${GH_PKG_TOKEN}" -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" "${GH_API}")
echo "json_data: $json_data"

if [ -z "$json_data" ]; then
  echo "json_data is empty."
  exit 0
fi

# Chech for Not Found message
message=$(jq -r '.message' <<< "$json_data")
if [ "$message" == "Not Found" ]; then
  echo "Message Not Found."
  exit 0
fi

# Find check_runs[].name = "SonarCloud Code Analysis" and get 'html_url' field
html_url=$(jq -r '.check_runs[] | select(.name == "SonarCloud Code Analysis").html_url' <<<"$json_data")
echo "html_url: $html_url"

if [ -z "$html_url" ]; then
  echo "html_url is empty."
  exit 0
fi

echo "html_url=$html_url" >>$GITHUB_OUTPUT
