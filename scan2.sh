#!/bin/bash

# Function to execute a command and save its output to a file
execute_command() {
    local cmd="$1"
    local output_file="$2"
    echo "Executing: $cmd"
    output=$(eval "$cmd" 2>&1)
    status=$?
    echo "$output" > "$output_file"
    if [ $status -ne 0 ]; then
        echo "Error executing $cmd. Check $output_file for details."
    else
        echo "Output saved to $output_file"
    fi
}

# Log in to Azure (this will open a browser for authentication)
az login

# Set the desired subscription
az account set --subscription "Dev_Azure_10000_CloudSandbox1"

# Get the list of resource groups
resource_groups=$(az group list --query "[].name" -o tsv)

# Get the list of VM names
vm_names=$(az vm list --query "[].name" -o tsv)

# Get the list of locations
locations=$(az account list-locations --query "[].name" -o tsv)

# Get the list of web app names
web_app_names=$(az webapp list --query "[].name" -o tsv)

# Directory to store the outputs
mkdir -p azure_scan_results
cd azure_scan_results

# Execute commands for each resource group
for resource_group in $resource_groups; do
    commands=(
        "az network vnet-gateway list --resource-group $resource_group --query \"[].{Name:name, VPNType:vpnType, GatewayType:gatewayType, IPConfigurations:ipConfigurations}\" --output json"
        "az network vpn-connection list --resource-group $resource_group --query \"[].{Name:name, ConnectionStatus:connectionStatus, SharedKey:sharedKey}\" --output json"
        "az network local-gateway list --resource-group $resource_group --query \"[].{Name:name, Properties:properties, IPConfigurations:ipConfigurations}\" --output json"
        "az network manager list --resource-group $resource_group --query \"[].{Name:name, Properties:properties, NetworkGroups:networkGroups}\" --output json"
        "az cdn waf policy list --resource-group $resource_group --query \"[].{Name:name, PolicySettings:policySettings, Rules:rules}\" --output json"
        "az network front-door waf-policy list --resource-group $resource_group --query \"[].{Name:name, PolicySettings:policySettings, Rules:rules}\" --output json"
        "az search service list --resource-group $resource_group --query \"[].{Name:name, Properties:properties, QueryKeys:queryKeys}\" --output json"
    )

    for cmd in "${commands[@]}"; do
        output_file="${resource_group}_$(echo "$cmd" | awk '{print $3}' | tr '-' '_').json"
        execute_command "$cmd" "$output_file"
    done

    for web_app_name in $web_app_names; do
        cmd="az webapp deployment slot list --resource-group $resource_group --name $web_app_name --query \"[].{Name:name, Properties:properties, Configurations:configurations}\" --output json"
        output_file="${resource_group}_${web_app_name}_webapp_deployment_slot.json"
        execute_command "$cmd" "$output_file"
    done
done

# Execute commands for each location
for location in $locations; do
    cmd="az network watcher connection-monitor list --location $location --query \"[].{Name:name, Properties:properties, Endpoints:endpoints}\" --output json"
    output_file="${location}_network_watcher_connection_monitor.json"
    execute_command "$cmd" "$output_file"
done

# Execute commands for each combination of resource group and VM name
for resource_group in $resource_groups; do
    for vm_name in $vm_names; do
        cmd="az vm extension list --resource-group $resource_group --vm-name $vm_name --query \"[].{Name:name, Properties:properties, Settings:settings}\" --output json"
        output_file="${resource_group}_${vm_name}_vm_extension.json"
        execute_command "$cmd" "$output_file"
    done
done

# Execute common commands
commands=(
    "az network public-ip list --query \"[].{Name:name, IPAddress:ipAddress, DNSSettings:dnsSettings}\" --output json"
    "az network nsg list --query \"[].{Name:name, SecurityRules:securityRules, DefaultSecurityRules:defaultSecurityRules}\" --output json"
    "az network vnet list --query \"[].{Name:name, AddressSpace:addressSpace, Subnets:subnets, DNSSettings:dnsSettings}\" --output json"
    "az network private-endpoint list --query \"[].{Name:name, NetworkInterfaces:networkInterfaces, PrivateLinkServiceConnections:privateLinkServiceConnections}\" --output json"
    "az network nat gateway list --query \"[].{Name:name, PublicIPAddresses:publicIpAddresses, Subnets:subnets}\" --output json"
    "az network lb list --query \"[].{Name:name, FrontendIPConfigurations:frontendIpConfigurations, BackendPools:backendAddressPools, LoadBalancingRules:loadBalancingRules}\" --output json"
    "az network application-gateway list --query \"[].{Name:name, FrontendIPConfigurations:frontendIpConfigurations, BackendPools:backendAddressPools, HTTPSettings:httpSettingsCollection}\" --output json"
    "az network route-table list --query \"[].{Name:name, Routes:routes, Subnets:subnets}\" --output json"
    "az network application-gateway waf-policy list --query \"[].{Name:name, PolicySettings:policySettings, Rules:customRules}\" --output json"
    "az network firewall policy list --query \"[].{Name:name, Rules:ruleCollectionGroups, Settings:threatIntelMode}\" --output json"
    "az network firewall list --query \"[].{Name:name, IPConfigurations:ipConfigurations, Rules:rules}\" --output json"
    "az network vhub list --query \"[].{Name:name, AddressPrefixes:addressPrefixes, RouteTables:routeTables}\" --output json"
    "az network asg list --query \"[].{Name:name, SecurityRules:securityRules}\" --output json"
    "az network bastion list --query \"[].{Name:name, IPConfigurations:ipConfigurations}\" --output json"
    "az network ddos-protection list --query \"[].{Name:name, ProtectionPlanSettings:protectionPlanSettings}\" --output json"
    "az network vwan list --query \"[].{Name:name, Properties:properties, Hubs:hubs}\" --output json"
    "az network service-endpoint policy list --query \"[].{Name:name, Definitions:serviceEndpointPolicyDefinitions}\" --output json"
    "az network express-route gateway list --query \"[].{Name:name, Properties:properties, Connections:connections}\" --output json"
    "az network vpn-site list --query \"[].{Name:name, Properties:properties, IPConfigurations:ipConfigurations}\" --output json"
    "az network public-ip prefix list --query \"[].{Name:name, Properties:properties, IPRanges:ipPrefixes}\" --output json"
    "az network ip-group list --query \"[].{Name:name, Properties:properties, IPAddresses:ipAddresses}\" --output json"
    "az vm list --query \"[].{Name:name, Properties:properties, NetworkInterfaces:networkInterfaces}\" --output json"
    "az storage account list --query \"[].{Name:name, Properties:properties, NetworkRules:networkRules}\" --output json"
    "az sql server list --query \"[].{Name:name, Properties:properties, FirewallRules:firewallRules}\" --output json"
    "az acr list --query \"[].{Name:name, Properties:properties, NetworkRules:networkRules}\" --output json"
    "az aks list --query \"[].{Name:name, Properties:properties, NodePools:nodePools}\" --output json"
    "az cosmosdb list --query \"[].{Name:name, Properties:properties, ConnectionStrings:connectionStrings}\" --output json"
    "az webapp list --query \"[].{Name:name, Properties:properties, Configurations:configurations}\" --output json"
    "az keyvault list --query \"[].{Name:name, Properties:properties, AccessPolicies:accessPolicies}\" --output json"
)

for cmd in "${commands[@]}"; do
    output_file="$(echo "$cmd" | awk '{print $3}' | tr '-' '_').json"
    execute_command "$cmd" "$output_file"
done

# Execute commands for each resource group (private link service)
for resource_group in $resource_groups; do
    cmd="az network private-link-service show --resource-group $resource_group --query \"[].{Name:name, ConnectionStatus:connectionStatus, PrivateLinkServiceID:privateLinkServiceId}\" --output json"
    output_file="${resource_group}_network_private_link_service.json"
    execute_command "$cmd" "$output_file"
done

echo "All commands executed. Check the azure_scan_results directory for output files."
