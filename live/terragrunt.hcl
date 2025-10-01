# Configure Terragrunt to automatically retry failed attempts
terraform {
  extra_arguments "retry_lock" {
    commands = get_terraform_commands_that_need_locking()
    arguments = [
      "-lock-timeout=20m"
    ]
  }
}

# Input values that are common across all environments
inputs = {
  region = "eu-central-1"
  
  # Global DNS configuration
  internal_domain = "internal.cashabl.local"
  puppet_server_hostname = "puppet.internal.cashabl.local"
}
