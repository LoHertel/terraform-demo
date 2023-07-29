# Introduction to Productionize Terraform

This repository demonstrates basic approaches to use Terraform as Infrastructure as Code (IaC) tool for managing multiple environments in a GitOps fashion.  
It contains:
* Approaches for deploying changes to multiple environments
* Terraform Modules for writing DRY configurations *(DRY = don't repeat yourself)*
* GitHub Action workflows for validating PRs (CI) and for deployments

This repository aims to give you a set of best practices for using Terraform and provides examples.

## Multiple Environments
There are several approaches for managing multiple environments (e.g. `dev`, `test` or `prod` environments) with Terraform.
* Terraform Workspaces
* Branch per Environment
* Folder per Environment


## Run Demo in GCP

This demo creates a staging and production environment using free tier resources from Google Cloud Platform (GCP). As long as you are not maxing out your free tier limits already, this demo will not incur any cost (as of July 2023). Do not forget to destroy all resources, after finishing the demo. This step is part of the tutorial.

> ***Note:** You need a [GCP account](https://console.cloud.google.com/freetrial) for running this demo. GCP also offers [$300 free credits for 90 days](https://cloud.google.com/free/docs/free-cloud-features#free-trial) when signing up.*

You can run this demo with interactive instructions by clicking the buttom below.

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/LoHertel/terraform-demo&cloudshell_git_branch=main&cloudshell_tutorial=tutorial.md)

After clicking the "*Open in Google Cloud Shell*" button, the Google Cloud Shell Editor will open and ask for your consent to clone this repository. The interactive instructions for this demo will open on the right side of the Cloud Shell Editor.
*Note: There might be an error message showing up that third-party cookies are necessary, if your browser blocks them by default. You can enable third-party cookies specifically for the Cloud Shell Editor. See [here for more information](https://cloud.google.com/code/docs/shell/limitations#private_browsing_and_disabled_third-party_cookies).*

> ***Note:** If you have closed the instructions pane and want to reopen it, run the following command in the cloudshell terminal window:*
> ```sh
> cloudshell launch-tutorial tutorial.md
> ```

If you don't want to use Google Cloud Shell Editor, you could go through the instructions manually by following the steps below.



## Local Setup

### Install Terraform
Check if Terraform is already installed on your system by running the following command:
```bash
terraform -v
```

If it is not installed, visit the [official website](https://developer.hashicorp.com/terraform/downloads) for specific setup instructions for your system.
Select your operating system on the website and follow the instructions.

E.g. for Ubuntu the instructions are:
```bash
# add hashicorp's public key to your keyring
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
```

```bash
# add hashicorp's repo as source for apt
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
```

```bash
# install terraform
sudo apt update && sudo apt install terraform
```

Run this command again to verify, that the installation was successful:
```bash
terraform -v
```

### Install gcloud CLI tool

Check if `gcloud` is already installed on your system by running the following command:
```bash
gcloud -v
```

If it is not installed, visit the [official website](https://cloud.google.com/sdk/docs/install) for specific setup instructions for your system.
Select your operating system on the website and follow the instructions.

E.g. for Ubuntu the instructions are:
```bash
# add GCP's public key to your keyring
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
```

```bash
# add GCP repo as source for apt
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
```

```bash
# install gcloud
sudo apt update && sudo apt install google-cloud-cli
```

Run this command again to verify, that the installation was successful:
```bash
gcloud -v
```

## Tutorial

After having setup your local environment, you can follow the tutorial.

> ***Note**: Step xx of the tutorial has instructions for Google Cloud Shell Editor. Run the following instead locally...*


## Best Practices, Tips and Tricks

* [Upgrade Terraform Provider Versions](#upgrade-terraform-provider-versions)
* [Manage Multiple Versions of Terraform](#manage-multiple-versions-of-terraform)
* [Auto-Formatter as Pre-Commit Hook](#auto-formatter-as-pre-commit-hook)
* [Generate Documentation from Terraform Code](#generate-documentation-from-terraform-code)
* [Best Practices Guides](#best-practices-guides)

### Upgrade Terraform Provider Versions

The versions of the used providers are locked in the following file for each code base: `.terraform.lock.hcl`. 
At the moment, only the used providers are locked, the versions of the used remote modules are not locked. For modules, Terraform will always select the newest available module version that meets the specified version constraints in `main.tf`. For locked providers, Terraform will always load the locked version in `.terraform.lock.hcl`.

Each time the project is initialized (`terraform init`), the locked provider versions will be installed. This ensures that all team members and CI pipelines use an identical provider version.
If you want to upgrade providers to the newest version (which still satisfies the version requirements defined in `main.tf`), run the following command to upgrade the lock file (and it will also upgrade your state file to be compatible with the new provider versions):
```bash
terraform init -upgrade &&
terraform providers lock \
    -platform=windows_amd64 \
    -platform=darwin_amd64 \
    -platform=linux_amd64 \
    -platform=darwin_arm64 \
    -platform=linux_arm64
```
This command includes hash values of the provider packages for all five supported operating systems and CPU architectures.  
In this way you ensure that the lock file contains the package hashes for all platforms. Otherwise your colleagues or CI pipelines on a different OS might have problems running the code, because the checksum verification will fail.

Please do not forget to commit the updated lock file to your project's repository.

Consult the Terraform documentation for more information on the [dependency lock file](https://developer.hashicorp.com/terraform/language/files/dependency-lock).

### Manage Multiple Versions of Terraform

When you want to test your codebase with a newer Terraform version it comes handy using `tfenv` as Terraform version manager. It helps too, when you need to work on multiple projects which require different versions of Terraform.
More information: https://github.com/tfutils/tfenv 

### Auto-Formatter as Pre-Commit Hook

You could activate a pre-commit hook, which automatically formats your terraform code, when you make a git commit.

Create a file `.git/hooks/pre-commit` if it doesnt exist and make it excecutable:
```bash
[[ -f .git/hooks/pre-commit ]] || { touch .git/hooks/pre-commit; chmod +x .git/hooks/pre-commit; }
```

Paste the following code into `.git/hooks/pre-commit` with your prefered editor:
```bash
#!/bin/sh

# Auto-Formatting Terraform Code 
STAGED_TF_FILES=$(git diff-index --cached --name-only --diff-filter=AM HEAD | sed 's| |\\ |g' | grep -E '\.tf$')

if [ ${#STAGED_TF_FILES} -gt 0 ] # if files found
then 
    
    FORMATTED_FILES=$(terraform fmt $STAGED_TF_FILES)

    if [ ${#FORMATTED_FILES} -gt 0 ] # if files formatted
    then
        
        git add -f $FORMATTED_FILES
        echo "auto-formatted for commit: $FORMATTED_FILES"

    fi
fi
```


### Generate Documentation from Terraform Code

More information: https://github.com/terraform-docs/terraform-docs

### Best Practices Guides

Here is a list of best practices guides for Terraform:

* [Google](https://cloud.google.com/docs/terraform/best-practices-for-terraform)