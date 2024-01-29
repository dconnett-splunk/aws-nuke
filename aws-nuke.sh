#!/bin/bash
#
# ******* DO NOT RUN THIS SCRIPT *******
# Don't run this script -> it deletes all VPCs in your AWS account across all regions
# This is a destructive script, use at your own risk
# This script is cursed
# ******* DO NOT RUN THIS SCRIPT *******
#
# ******* EXTREME WARNING: DO NOT RUN THIS SCRIPT UNLESS ABSOLUTELY SURE *******
# This script is a digital equivalent of a nuclear bomb for your AWS environment.
# It will irreversibly delete ALL VPCs in your AWS account across every single region.
#
# You should be seriously scared of running this script unless you are 100% sure.
# This is the kind of script that can permanently end careers if used incorrectly...
# In fact, it may even land you in jail depending on where you work.
#
# No, seriously, STOP AND THINK before running this script!
#
# Here is another warning, just in case you missed the first two...
#
# ********** WARNING: HIGHLY DESTRUCTIVE SCRIPT **********
# This script deletes all EC2 instances, network interfaces, security groups, and VPCs
# in your AWS account across all regions. It is intended for use in environments where
# such actions are appropriate and have been carefully considered.
#
# This script is particularly useful for cleaning up environments where Terraform state
# issues prevent normal teardown in ephemeral and isolated environments.
#
# Please use with extreme caution. The actions performed by this script are irreversible.
#
# Note, there is no logic for waiting for resources to be deleted. Manually rerun the script
# to ensure all resources are deleted.
#
# This script is provided as-is with no warranty or guarantee of any kind. Use at your own risk.
#
# Author: David Connett

export AWS_PAGER=""

# Scary confirmation prompt
echo "--------------------------------------------------------------------------"
echo "!! DANGER ZONE: You are about to execute a highly destructive script !!"
echo "This will PERMANENTLY DELETE all your AWS VPCs, EC2 instances, network interfaces,"
echo "security groups, and other related resources across ALL regions."
echo "This action CANNOT BE UNDONE. Think carefully before proceeding."
echo "--------------------------------------------------------------------------"

read -p "If you understand the consequences and still want to proceed, type 'delete': " confirmation
if [ "$confirmation" != "delete" ]; then
    echo "Aborting script"
    exit 1
fi

read -p "Are you REALLY sure? Hit enter to continue or CTRL-C to abort: " confirmation
if [ "$confirmation" != "" ]; then
    echo "Aborting script"
    exit 1
fi

delete_security_groups() {
    region=$1
    vpc=$2
    # List all non-default security groups in the specified VPC
    sg_ids=$(aws ec2 describe-security-groups --region "$region" --filters "Name=vpc-id,Values=$vpc" "Name=group-name,Values=!default" --query "SecurityGroups[*].GroupId" --output text)
    for sg_id in $sg_ids; do
        echo "Deleting Security Group: $sg_id"
        aws ec2 delete-security-group --region "$region" --group-id $sg_id
    done
}

delete_eks_clusters() {
    region=$1
    eks_clusters=$(aws eks list-clusters --region "$region" --query "clusters" --output text)
    for cluster in $eks_clusters; do
        echo "Deleting EKS Cluster: $cluster"
        aws eks delete-cluster --name "$cluster" --region "$region"
    done
}

delete_subnets() {
    region=$1
    vpc=$2
    subnets=$(aws ec2 describe-subnets --region "$region" --filters "Name=vpc-id,Values=$vpc" --query "Subnets[*].SubnetId" --output text)
    for subnet in $subnets; do
        echo "Deleting Subnet: $subnet"
        aws ec2 delete-subnet --region "$region" --subnet-id $subnet
    done
}

delete_igws() {
    region=$1
    vpc=$2
    igws=$(aws ec2 describe-internet-gateways --region "$region" --filters "Name=attachment.vpc-id,Values=$vpc" --query "InternetGateways[*].InternetGatewayId" --output text)
    for igw in $igws; do
        echo "Deleting Internet Gateway: $igw"
        aws ec2 detach-internet-gateway --region "$region" --internet-gateway-id $igw --vpc-id $vpc
        echo "Waiting for Internet Gateway to detach"
        aws ec2 delete-internet-gateway --region "$region" --internet-gateway-id $igw

    done
}

delete_nat_gateways() {
    region=$1
    vpc=$2
    nat_gws=$(aws ec2 describe-nat-gateways --region "$region" --filter "Name=vpc-id,Values=$vpc" --query "NatGateways[*].NatGatewayId" --output text)
    for nat_gw in $nat_gws; do
        echo "Deleting NAT Gateway: $nat_gw"
        aws ec2 delete-nat-gateway --region "$region" --nat-gateway-id $nat_gw
    done
}

delete_ec2_instances() {
    region=$1
    vpc=$2
    instances=$(aws ec2 describe-instances --region "$region" --filters "Name=vpc-id,Values=$vpc" --query "Reservations[*].Instances[*].InstanceId" --output text)
    for instance in $instances; do
        echo "Terminating EC2 Instance: $instance"
        aws ec2 terminate-instances --region "$region" --instance-ids $instance
    done
}

delete_network_interfaces() {
    region=$1
    vpc=$2
    nics=$(aws ec2 describe-network-interfaces --region "$region" --filters "Name=vpc-id,Values=$vpc" --query "NetworkInterfaces[*].NetworkInterfaceId" --output text)
    for nic in $nics; do
        echo "Deleting Network Interface: $nic"
        aws ec2 delete-network-interface --region "$region" --network-interface-id $nic
    done
}

delete_vpc() {
    region=$1
    vpc=$2
    aws ec2 delete-vpc --region "$region" --vpc-id $vpc
}

export -f delete_security_groups
export -f delete_eks_clusters
export -f delete_subnets
export -f delete_igws
export -f delete_nat_gateways
export -f delete_ec2_instances
export -f delete_network_interfaces
export -f delete_vpc

# Get all AWS regions as an array
regions=($(aws ec2 describe-regions --query "Regions[].RegionName" --output text))

# Process each VPC in parallel
for region in "${regions[@]}"; do

    delete_eks_clusters "$region"

    vpcs=$(aws ec2 describe-vpcs --region "$region" --query "Vpcs[*].VpcId" --output text)
    echo $vpcs | xargs -n 1 -P 10 -I {} bash -c 'delete_ec2_instances "$0" "$1" && \
                                                 delete_network_interfaces "$0" "$1" && \
                                                 delete_subnets "$0" "$1" && \
                                                 delete_igws "$0" "$1" && \
                                                 delete_nat_gateways "$0" "$1" && \
                                                 delete_security_groups "$0" "$1" && \
                                                 delete_vpc "$0" "$1"' "$region" {}
done
