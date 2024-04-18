# Sonar Cloud Scanner Custom GitHub Action (docker image) project notes

## Set GitHub variables and secrets in local environment variables

Request secrets from project manager.

```powershell
[Environment]::SetEnvironmentVariable('GH_PKG_USER', '3DHDSoft', 'User')
[Environment]::SetEnvironmentVariable('Git_Email', 'action@github.com', 'User')
[Environment]::SetEnvironmentVariable('Git_Username', 'GitHub Action', 'User')
[Environment]::SetEnvironmentVariable('GH_PKG_TOKEN', 'ghp_XXX...', 'User')
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
gh variable set GH_PKG_USER --body "$Env:GH_PKG_USER" -R 3DHDSoft/SonarscanEx
gh variable set GIT_EMAIL --body "$Env:Git_Email" -R 3DHDSoft/SonarscanEx
gh variable set GIT_USERNAME --body "$Env:Git_Username" -R 3DHDSoft/SonarscanEx
gh secret set GH_PKG_TOKEN --body "$Env:GH_PKG_TOKEN" -R 3DHDSoft/SonarscanEx
dotnet new tool-manifest --force
dotnet tool install Husky
dotnet husky install
```
