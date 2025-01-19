#!/bin/bash
# Start the overall timer
overall_start=$(date +%s)
echo "Processing current folder..."
# Start the timer for the current folder
start=$(date +%s)
# Execute Terraform commands
terraform init || { echo "Terraform init failed"; exit 1; }
terraform fmt -recursive || { echo "Terraform fmt failed"; exit 1; }
terraform validate || { echo "Terraform validate failed"; exit 1; }
terraform plan -lock=false || { echo "Terraform plan failed"; exit 1; }
terraform apply --auto-approve -lock=false || { echo "Terraform apply failed"; exit 1; }
# Calculate the time taken for this folder
end=$(date +%s)
duration=$((end - start))
minutes=$((duration / 60))
seconds=$((duration % 60))
echo "Current folder processed successfully in $minutes min $seconds sec."
# Calculate the overall time taken
overall_end=$(date +%s)
overall_duration=$((overall_end - overall_start))
overall_minutes=$((overall_duration / 60))
overall_seconds=$((overall_duration % 60))
echo "All operations completed successfully in $overall_minutes min $overall_seconds sec."





