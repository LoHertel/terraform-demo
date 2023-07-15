## Run in GCP

> ***Note:** You need a [GCP account](https://console.cloud.google.com/freetrial) for running this demo. Note that GCP also offers [$300 free credits for 90 days](https://cloud.google.com/free/docs/free-cloud-features#free-trial).*

You can run this demo with interactive instructions by clicking the buttom below.

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/LoHertel/terraform-demo&cloudshell_git_branch=main&cloudshell_tutorial=tutorial.md)

After clicking the button *Open in Google Cloud Shell*, the Google Cloud Shell Editor will open and ask for your authorization to clone this repository. The interactive instructions for this demo will open on the right side of the Cloud Shell Editor.
*Note: There might be an error message showing that third-party cookies are necessary. You can allow third-party cookies for the Cloud Shell Editor. See [here for more information](https://cloud.google.com/code/docs/shell/limitations#private_browsing_and_disabled_third-party_cookies).*

> ***Note:** If you have closed the instructions pane and want to reopen it, run the following command in the cloudshell terminal window:*
> ```sh
> cloudshell launch-tutorial project-walkthrough.md
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

## Upgrade Terraform Provider Version

The version of the used provider is locked in the following file: `.terraform.lock.hcl`.  
Each time the project is initialized (`terraform init`), the locked version will be installed.
If you want to upgrade the providers to the latest version (which still satisfies the defined version requirement for the provider in `main.tf`), run the following command to update the lock file:
```bash
terraform providers lock \
    -platform=windows_amd64 \
    -platform=darwin_amd64 \
    -platform=linux_amd64 \
    -platform=darwin_arm64 \
    -platform=linux_arm64
```
This command includes hash values of the provider package for all operating systems.