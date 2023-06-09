
# Terraform Tutorial
<walkthrough-tutorial-duration duration="30"></walkthrough-tutorial-duration>

Welcome to this *Terraform* tutorial. It will guide you through setting up Terraform for GCP and introduce you to the basic concepts of Terraform.  
Most steps are automated to make the setup as easy as possible. 

## Overview

The septup will have the following steps:
1. create Google Cloud project for Terraform state files  
    a. authorize APIs and billing for this project  
    b. set preferred cloud location  
    c. create Cloud Storage bucket  
2. create service account for Terraform
3. create infrastructure with Terraform
4. deploy infrastructure changes in Github Actions
4. remove created infrastructure

It costs approx. $1 credit to run the project for an hour.

> ***Note:** If you have closed this instructions pane and want to reopen it, run the following command in the Cloud Shell terminal window:*
> ```sh
> cloudshell launch-tutorial tutorial.md
> ```

&nbsp;  
Click on **Start** to open the instructions for creating a new project.

## 1. Create Google Cloud Project for Terraform State Files

Terraform is a stateful application. It is a [good practice](https://developer.hashicorp.com/terraform/language/state/remote) to store the Terraform state file on a remote storage, in order to version the state description of the infrastructure, to prevent data loss, and to give other members of a team the opportunity to change the infrastructure as well. 

Here you will create a Google Cloud Project for storing the state of your Terraform managed infrastructure centrally.

> ***Tip:** If you have opened the instructions in Google Cloud Shell, you could click on the grey Cloud Shell icon <walkthrough-cloud-shell-icon></walkthrough-cloud-shell-icon> at the top right corner of the shell command to transfer the code to the Cloud Shell terminal window, then press enter in the terminal window to execute the command.*
&nbsp; 

1. Generate a name for your project with a random id:
```sh
NAME_PREFIX="org-example-$(shuf -i 100000-999999 -n 1)"
```
&nbsp;  

2. Create the project with the generated name
*(**Note:** You might need to authorise the terminal session)*:
```sh
gcloud projects create $NAME_PREFIX-tf-state --name="TF-Demo Terraform State Files"
```
&nbsp;  

3. Activate the created project in Cloud Shell *(this will help us accessing the project ressources via the terminal window and saves the project id in the variable $GOOGLE_CLOUD_PROJECT)*:
```sh
gcloud config set project $NAME_PREFIX-tf-state
```
&nbsp;  

> ***Note:** If you want to reopen your project, because the Cloud Shell session has timed out, you can use the following command:*
> ```sh
> NAME_PREFIX=$(gcloud projects list --filter='PROJECT_ID:org-example-*' --limit=1 --format='value(PROJECT_ID)' | grep -o -E '^org-example-[[:digit:]]{6}')
> gcloud config set project $NAME_PREFIX-tf-state
> ```

&nbsp;  
Click **Next** to start authorizing the necessary APIs for this project.


## 1a. Authorize APIs and Billing

Execute the following command to authorize these APIs for the project:
* storage

```sh 
gcloud services enable compute.googleapis.com storage-component.googleapis.com 
```

> ***Note:** If there is an error message, that a billing account is missing for this new project, follow these additional steps:*
> 1. Go to the [Google Cloud Platform billing config](https://console.cloud.google.com/billing/projects).
> 2. Click on the three dots next to the new project and select "Change billing". 
> 3. Choose your billing account and confirm by clicking "Set account".
> 4. Execute the shell command above again to enable the APIs.

&nbsp;  
Click **Next** configure the cloud location.

## 1b. Set Preferred Cloud Location

Execute the following command to set a **region** as cloud location for this project:  

```sh
gcloud config set compute/region us-east1
```
> ***Note:** The region will be set to `us-east1`. `us-east1` is part of the free tier offering. If you would like to use another location, [choose your preferred region](https://cloud.google.com/storage/docs/locations#location-r) and change it in the shell command above.*

&nbsp;  

Execute the following command to set a **corresponding zone** to the selected region above:  
```sh
gcloud config set compute/zone "$(gcloud config get compute/region)-d"
```
> ***Note:** The zone will be set to `us-east1-d`. If you would like to use another zone, change the letter `d` to your preferred zone letter. All available zones for a region could be [found here](https://cloud.google.com/compute/docs/regions-zones#available).*

&nbsp;  

Execute the following command to store the selected region and zone in variables for further usage in this walkthrough: 
```sh
GOOGLE_CLOUD_REGION=$(gcloud config get compute/region)
GOOGLE_CLOUD_ZONE=$(gcloud config get compute/zone)
```

&nbsp;  
Click **Next** to configure a service account for Terraform.


## 1c. Create Bucket for Terraform State Files

It is a [good practice](https://www.terraform.io/language/state/remote) to store the Terraform state file on a remote storage, in order to version the state description of the infrastructure, to prevent data loss and to give other members of a team the opportunity to change the infrastructure as well. 

Set a name for the bucket, in which the Terraform remote state file will be stored:
```sh
TF_BUCKET_NAME = "$NAME_PREFIX-tf-state"
```

Execute the following command to create a bucket for the Terraform remote state files:
```sh
gsutil mb -p $GOOGLE_CLOUD_PROJECT -c STANDARD -l $GOOGLE_CLOUD_REGION gs://$TF_BUCKET_NAME
```
&nbsp;  

Enable object versioning on the bucket to track changes in the state file and therefore document infrastructure changes:
```sh
gsutil versioning set on gs://$TF_BUCKET_NAME
```
&nbsp;  
Click **Next** to inform yourself about a service account for Terraform.


## 2. Create Google Cloud Projects for Staging and Production Environment

### Staging Environment

1. Create the project with the generated name:
```sh
gcloud projects create $NAME_PREFIX-stage --name="TF-Demo Stage"
```

2. Execute the following command to authorize these APIs for the project:
    * storage

```sh 
gcloud services enable --project=$NAME_PREFIX-stage compute.googleapis.com storage-component.googleapis.com
```

> ***Note:** If there is an error message, that a billing account is missing for this new project, follow these additional steps:*
> 1. Go to the [Google Cloud Platform billing config](https://console.cloud.google.com/billing/projects).
> 2. Click on the three dots next to the new project and select "Change billing". 
> 3. Choose your billing account and confirm by clicking "Set account".
> 4. Execute the shell command above again to enable the APIs.


### Production Environment

1. Create the project with the generated name:
```sh
gcloud projects create $NAME_PREFIX-prod --name="TF-Demo Prod"
```

2. Execute the following command to authorize these APIs for the project:
    * storage

```sh 
gcloud services enable --project=$NAME_PREFIX-prod compute.googleapis.com storage-component.googleapis.com
```

> ***Note:** If there is an error message, that a billing account is missing for this new project, follow these additional steps:*
> 1. Go to the [Google Cloud Platform billing config](https://console.cloud.google.com/billing/projects).
> 2. Click on the three dots next to the new project and select "Change billing". 
> 3. Choose your billing account and confirm by clicking "Set account".
> 4. Execute the shell command above again to enable the APIs.



## 2. Service Account for Terraform

It is a good practice to create a separate service account for Terraform. Terraform needs priviliges for creating, changing and destroying resources. 

In production grade environments Terraform is used to manage multiple Google Cloud Projects for separating productive and non-productive resources. For using IAM roles and service accounts beyond the scope of one project, you need to setup the Google Cloud Identity service and create an organization.

Because this would be an additional process, which takes time and makes the setup more complex, you are advised to run Terraform with your personal Google Cloud Platform account instead of a service account for this tutorial. Your account can manage all resources from all your projects already.

Your personal Google Cloud Platform account is already authorized to run commands in Cloudshell.


* roles/resourcemanager.projectCreator
* roles/resourcemanager.projectDeleter
* roles/resourcemanager.projectIamAdmin
* roles/serviceusage.serviceUsageAdmin

&nbsp;  
Click **Next** to start creating the cloud infrastructure with Terraform.

## 3. Create Infrastructure with Terraform

Change directory
```sh
cd setup
```
&nbsp; 

Create SSH keys for the Google Compute Engine:
```sh
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "GCE OS Login"
```
&nbsp; 

```sh
gcloud compute os-login ssh-keys add --key-file=$HOME/.ssh/id_ed25519.pub --project=$NAME_PREFIX-stage --ttl=1y
gcloud compute os-login ssh-keys add --key-file=$HOME/.ssh/id_ed25519.pub --project=$NAME_PREFIX-prod --ttl=1y
```

Initialize the remote state file (.tfstate):
```sh
terraform init -backend-config="bucket=$TF_BUCKET_NAME"
```
&nbsp; 

Create an execution plan to build the defined infrastructure:
```sh
terraform plan -var="project=$GOOGLE_CLOUD_PROJECT" -var="region=$GOOGLE_CLOUD_REGION" -var="zone=$GOOGLE_CLOUD_ZONE"
```
&nbsp; 

Execute the plan and build the infrastructure (*it might take a couple of minutes to finish it*):
```sh
terraform apply -auto-approve -var="project=$GOOGLE_CLOUD_PROJECT" -var="region=$GOOGLE_CLOUD_REGION" -var="zone=$GOOGLE_CLOUD_ZONE"
```

Now you have created the necessary infrastructure.  


&nbsp;  
Click **Next** to setup Airflow.

## 6. Setup Airflow

Get **IP address** of compute engine:
```sh
IP_ADDRESS="$(gcloud compute instances describe airflow-host --format='get(networkInterfaces[0].accessConfigs[0].natIP)')"
```
&nbsp; 

Insert current **project settings** in environment file `.env`:
```sh
cp ../airflow/template.env ../airflow/.env

sed -i "s/^\(GCP_PROJECT_ID=\).*$/\1$GOOGLE_CLOUD_PROJECT/gm" ../airflow/.env

sed -i "s/^\(GCP_GCS_BUCKET=\).*$/\1$GOOGLE_CLOUD_PROJECT-$GOOGLE_CLOUD_REGION-data-lake/gm" ../airflow/.env

sed -i "s/^\(GCP_LOCATION=\).*$/\1$GOOGLE_CLOUD_REGION/gm" ../airflow/.env
```
&nbsp; 

Create target folders and **transfer data** to the VM:
```sh
ssh -o StrictHostKeyChecking=no local@$IP_ADDRESS "mkdir -p ~/app/airflow ~/app/dbt ~/app/credentials"

scp -r ../airflow ../dbt ../credentials local@$IP_ADDRESS:~/app

ssh local@$IP_ADDRESS "chmod o+r ~/app/credentials/* && chmod o+w ~/app/dbt"
```
&nbsp; 

**Connect** to the VM:
```sh
ssh local@$IP_ADDRESS
```
&nbsp; 

**Install Docker** and Docker Compose:
```sh
sudo apt update

sudo apt install -y apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update

sudo apt-get -y install docker-ce docker-ce-cli containerd.io

sudo curl -L "https://github.com/docker/compose/releases/download/v2.4.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose

sudo systemctl start docker

sudo usermod -aG docker $USER

newgrp docker
```
&nbsp; 

Build and **start the airflow** containers:
```sh
cd app/airflow
/usr/local/bin/docker-compose build
/usr/local/bin/docker-compose up airflow-init
/usr/local/bin/docker-compose up -d
```

&nbsp;  
Click **Next** to run the data pipeline in airflow.

## 7. Run Data Pipeline

> ***Note:** If you are not connected to `local@airflow-host`, execute the following command:*
> ```sh
> IP_ADDRESS="$(gcloud compute instances describe airflow-host --format='get(networkInterfaces[0].accessConfigs[0].natIP)')"
> ssh local@$IP_ADDRESS
> ```
&nbsp; 

**Connect to airflow** sheduler:
```sh
docker exec -it diplomats-airflow-scheduler-1 bash
```
&nbsp; 

**Start dag** by unpausing it:
```sh
airflow dags unpause ingest_diplomats_dag
```
&nbsp;  

Use this command to **see the dag's current status**: *(you might need to wait a bit until the dag is completed and refresh the command to see the new status)*
```sh 
airflow tasks states-for-dag-run ingest_diplomats_dag $(date -d "yesterday" '+%Y-%m-%d') 
```
If the state of every task in the dag shows `success`, the run is completed. The dag is sheduled to run daily and will check, whether a new version of the PDF list with diplomats was published online. If a new version is found, the data will be extracted, versioned and added to the BigQuery tables.
&nbsp;  

**Close the connection** to the airflow sheduler container and return to the airflow host:
```sh
exit
```
&nbsp; 

**Close the connection** to the airflow host and return to cloud shell
```sh
exit
```

&nbsp;  
Click **Next** to see the results

## 8. Open Data Studio Report

If you open BigQuery, you will see five tables in the `datamart` dataset. These tables contain the data for the Data Studio Report
```sh
bq ls --max_results 10 "$GOOGLE_CLOUD_PROJECT:datamart"
```
&nbsp;  

**Open the Report** using the following link to see how many diplomats from other countries are acredited in Germany at the moment, how many of them are male and female and how long are they staying on post on average: 
[https://datastudio.google.com/reporting/c67883ee-7b3a-481f-a28f-e001b0c3c743](https://datastudio.google.com/reporting/c67883ee-7b3a-481f-a28f-e001b0c3c743)

[![Report](https://www.lorenz-hertel.net/dashboard.png "Report")](https://datastudio.google.com/reporting/c67883ee-7b3a-481f-a28f-e001b0c3c743)

You went through the setup, ran the data pipeline and have seen the result.

&nbsp;  
Click **Next** to clean up the project and remove the infrastructure.

## 9. Clean Up Project 

1. **Remove infrastructure** using Terraform:
```sh
cd ~/cloudshell_open/diplomats-in-germany/setup
terraform destroy -auto-approve -var="project=$GOOGLE_CLOUD_PROJECT" -var="region=$GOOGLE_CLOUD_REGION" -var="zone=$GOOGLE_CLOUD_ZONE"
```
&nbsp;  

2. **Delete Google Cloud project** and type `Y` when you will get prompted to confirm the deletion
*(**Note:** The following command is going to delete the currently active project in Cloud Shell. Use `echo $GOOGLE_CLOUD_PROJECT` to review, which project is active)*:  
```sh
gcloud projects delete $GOOGLE_CLOUD_PROJECT
```  
If you feel uncertain, you could delete the project from Google Cloud manually: [Visit Ressource Manager](https://console.cloud.google.com/cloud-resource-manager)
&nbsp;  

3. **Remove cloned project repository** from your persistent Google Cloud Shell storage:
```sh
cd ~/cloudshell_open
rm -rf diplomats-in-germany
```

&nbsp;  
Click **Next** to complete the walkthrough.

## Congratulations
<walkthrough-conclusion-trophy></walkthrough-conclusion-trophy>

You went through the whole project, from setup, over running the data pipelines, to using the resulting dashboard. I hope you have liked the project.

Do not forget to remove the infrastructure, if you have not done so already.

This project is my capstone of [DataTalksClub](https://datatalks.club/)'s highly recommended [Data Engineering Zoomcamp](https://github.com/DataTalksClub/data-engineering-zoomcamp). Pay a visit to them, they are amazing!