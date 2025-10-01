Step 1: Deploy the backend (create-backend project)

1.1.Go to the create-backend folder:

cd create-backend

1.2.Initialize Terraform (this downloads providers):

terraform init

1.3.Preview what will be created:

terraform plan

1.4.Apply the configuration to create the RG, storage account, and blob container:

terraform apply

At this point, our remote state storage is ready.

Step 2: Make sure your main project is configured to use the remote backend

2.1 Go to your main project folder:

cd aks-infra

2.2 Make sure backend.tf is pointing to the storage account and container we created.

2.3 Initialize Terraform — this will configure the remote backend:

terraform init

Terraform may ask: Do you want to copy existing state to the new backend?
Type yes if prompted.

Step 3: Deploy your AKS + Flask infrastructure

3.1 Still inside the aks-infra folder, preview the plan:

terraform plan

Check that all resources look correct: RG, AKS, namespace, deployment, service, locks, etc.

3.2 Apply the plan:

terraform apply

Terraform will now:

Create the resource group for your AKS cluster

Create the AKS cluster

Apply the managed resource lock

Configure the Kubernetes provider

Deploy the namespace, Flask deployment, and service
