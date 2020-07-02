# Install the AWS provider plugin
terraform init

# Dry-run check
terraform plan

# Provision the infrastructure
terraform apply --var-file=variables.tfvars