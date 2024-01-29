# AWS VPC Nuke Script

## Description
This script is a highly destructive tool designed to delete all VPCs in your AWS account across all regions. It should be used with extreme caution as it will permanently delete all your AWS VPCs, EC2 instances, network interfaces, security groups, and other related resources.

## Warning
**EXTREME WARNING: THIS SCRIPT IS HIGHLY DESTRUCTIVE.**
- Do not run this script unless you are absolutely sure of what it does.
- This script can end careers or result in legal action if used incorrectly.
- The actions performed by this script are irreversible.

## Use Case
This script is useful for cleaning up environments, especially in cases where Terraform state issues prevent normal teardown in ephemeral and isolated environments.

## Requirements
- [AWS CLI](https://aws.amazon.com/cli/) must be installed and configured with appropriate permissions.
- Ensure you have a backup or have thoroughly reviewed the resources in your AWS account before executing this script.

## How to Run
1. **Read the entire script.** Understand what it does.
2. Run the script in a terminal.
3. You will be prompted twice for confirmation. You must type 'delete' to proceed.

## Author
- Original Author: David Connett

## Disclaimer
This script is provided as-is with no warranty or guarantee of any kind. Use at your own risk.

## Functionality
- Deletes all non-default security groups, EKS clusters, subnets, internet gateways, NAT gateways, EC2 instances, and network interfaces in each VPC.
- Processes each AWS region separately.
- Parallel execution for faster completion.

## Contribution
- Any improvements or suggestions are welcome. Please ensure any changes consider the destructive nature of this script.

## License
This project is licensed under the terms of the MIT license.
