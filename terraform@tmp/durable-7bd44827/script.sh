
                            az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET -t $AZURE_TENANT_ID
                            az account set -s $AZURE_SUBSCRIPTION_ID
                            az resource list
                            terraform init
                            terraform plan -out=tfplan
                            terraform apply -auto-approve tfplan
                        