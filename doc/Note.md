# Sonar Cloud Scanner Custom GitHub Action (docker image) project notes

## Set GitHub variables and secrets in local environment variables

Request secrets from project manager.

```powershell
[Environment]::SetEnvironmentVariable('GH_PKG_USER_ORG', '3DHDSoft', 'User')
[Environment]::SetEnvironmentVariable('Git_Email', 'action@github.com', 'User')
[Environment]::SetEnvironmentVariable('Git_Username', 'GitHub Action', 'User')
[Environment]::SetEnvironmentVariable('GH_PKG_TOKEN_ORG', 'ghp_XXX...', 'User')
[Environment]::SetEnvironmentVariable('SONAR_TOKEN_SonarscanEx', 'd{40}', 'User')
```

## GitHub CLI Login

```powershell
$Env:GH_PKG_TOKEN | gh auth login --with-token
```

## Setup Project

```powershell
cd D:\Projects\Util\SonarscanEx
git remote add origin https://github.com/3DHDSoft/SonarscanEx.git
git branch -M main
gh secret set GH_PKG_TOKEN_ORG --body "$Env:GH_PKG_TOKEN_ORG" -R 3DHDSoft/SonarscanEx
gh secret set SONAR_TOKEN --body "$Env:SONAR_TOKEN_VersionizeEx" -R 3DHDSoft/SonarscanEx
gh variable set GH_PKG_USER_ORG --body "$Env:GH_PKG_USER_ORG" -R 3DHDSoft/SonarscanEx
gh variable set GIT_EMAIL --body "$Env:Git_Email" -R 3DHDSoft/SonarscanEx
gh variable set GIT_USERNAME --body "$Env:Git_Username" -R 3DHDSoft/SonarscanEx
gh variable set SONAR_ORGANIZATION --body "$Env:SonarOrganization" -R 3DHDSoft/SonarscanEx
dotnet new tool-manifest --force
dotnet tool install Husky
dotnet husky install
```
