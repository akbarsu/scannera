#!/bin/bash

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

# Commands to execute
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
    "az network vnet-gateway list --resource-group $resource_groups --query \"[].{Name:name, VPNType:vpnType, GatewayType:gatewayType, IPConfigurations:ipConfigurations}\" --output json"
    "az network intent-policy list --query \"[].{Name:name, PolicySettings:policySettings, Rules:rules}\" --output json"
    "az network firewall list --query \"[].{Name:name, IPConfigurations:ipConfigurations, Rules:rules}\" --output json"
    "az network vhub list --query \"[].{Name:name, AddressPrefixes:addressPrefixes, RouteTables:routeTables}\" --output json"
    "az network asg list --query \"[].{Name:name, SecurityRules:securityRules}\" --output json"
    "az network bastion list --query \"[].{Name:name, IPConfigurations:ipConfigurations}\" --output json"
    "az network ddos-protection list --query \"[].{Name:name, ProtectionPlanSettings:protectionPlanSettings}\" --output json"
    "az network vpn-connection list --resource-group $resource_groups --query \"[].{Name:name, ConnectionStatus:connectionStatus, SharedKey:sharedKey}\" --output json"
    "az network private-link-service show --query \"[].{Name:name, ConnectionStatus:connectionStatus, PrivateLinkServiceID:privateLinkServiceId}\" --output json"
    "az network vwan list --query \"[].{Name:name, Properties:properties, Hubs:hubs}\" --output json"
    "az network service-endpoint policy list --query \"[].{Name:name, Definitions:serviceEndpointPolicyDefinitions}\" --output json"
    "az network express-route gateway list --query \"[].{Name:name, Properties:properties, Connections:connections}\" --output json"
    "az network vpn-site list --query \"[].{Name:name, Properties:properties, IPConfigurations:ipConfigurations}\" --output json"
    "az network public-ip prefix list --query \"[].{Name:name, Properties:properties, IPRanges:ipPrefixes}\" --output json"
    "az network ip-group list --query \"[].{Name:name, Properties:properties, IPAddresses:ipAddresses}\" --output json"
    "az network local-gateway list --resource-group $resource_groups --query \"[].{Name:name, Properties:properties, IPConfigurations:ipConfigurations}\" --output json"
    "az network manager list --resource-group $resource_groups --query \"[].{Name:name, Properties:properties, NetworkGroups:networkGroups}\" --output json"
    "az vm extension list --resource-group $resource_groups --vm-name $vm_names --query \"[].{Name:name, Properties:properties, Settings:settings}\" --output json"
    "az network watcher connection-monitor list --location $locations --query \"[].{Name:name, Properties:properties, Endpoints:endpoints}\" --output json"
    "az vm list --query \"[].{Name:name, Properties:properties, NetworkInterfaces:networkInterfaces}\" --output json"
    "az cdn waf policy list --resource-group $resource_groups --query \"[].{Name:name, PolicySettings:policySettings, Rules:rules}\" --output json"
    "az storage account list --query \"[].{Name:name, Properties:properties, NetworkRules:networkRules}\" --output json"
    "az sql server list --query \"[].{Name:name, Properties:properties, FirewallRules:firewallRules}\" --output json"
    "az network front-door waf-policy list --resource-group $resource_groups --query \"[].{Name:name, PolicySettings:policySettings, Rules:rules}\" --output json"
    "az search service list --resource-group $resource_groups --query \"[].{Name:name, Properties:properties, QueryKeys:queryKeys}\" --output json"
    "az acr list --query \"[].{Name:name, Properties:properties, NetworkRules:networkRules}\" --output json"
    "az aks list --query \"[].{Name:name, Properties:properties, NodePools:nodePools}\" --output json"
    "az webapp deployment slot list --resource-group $resource_groups --name $web_app_names --query \"[].{Name:name, Properties:properties, Configurations:configurations}\" --output json"
    "az cosmosdb list --query \"[].{Name:name, Properties:properties, ConnectionStrings:connectionStrings}\" --output json"
    "az webapp list --query \"[].{Name:name, Properties:properties, Configurations:configurations}\" --output json"
    "az keyvault list --query \"[].{Name:name, Properties:properties, AccessPolicies:accessPolicies}\" --output json"
)

# Directory to store the outputs
mkdir -p azure_scan_results
cd azure_scan_results

# Execute each command and save the output to a JSON file
for cmd in "${commands[@]}"; do
    echo "Executing: $cmd"
    output_file="$(echo $cmd | grep -o -P '(?<=az ).*?(?= list)').json"
    eval $cmd > "$output_file"
    if [ $? -ne 0 ]; then
        echo "Error executing $cmd, see $output_file for details."
    else
        echo "Output successfully saved to $output_file"
    fi
done

echo "All commands executed. Check the azure_scan_results directory for output files."
