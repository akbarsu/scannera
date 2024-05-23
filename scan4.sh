#!/bin/bash

# Function to execute a command and append its output to a consolidated JSON file
execute_command() {
    local cmd="$1"
    local resource_type="$2"
    local output_file="${resource_type}.json"
    local output=$($cmd 2>&1)
    local status=$?
    if [ $status -eq 0 ]; then
        echo "$output" >> "$output_file"
    else
        echo "Error executing command: $cmd" >> "error.log"
        echo "$output" >> "error.log"
    fi
}

# Login to Azure
az login

# Set the desired subscription
az account set --subscription "Dev_Azure_10001_CloudSandbox2"

# Retrieve the list of resource groups
resource_groups=($(az group list --query "[].name" -o tsv))

# Retrieve the list of VMs
vm_names=($(az vm list --query "[].name" -o tsv))

# Retrieve the list of web apps
web_app_names=($(az webapp list --query "[].name" -o tsv))

# Create output directory
mkdir -p azure_resources

# Change to the output directory
cd azure_resources

# Execute commands for each resource group in parallel
for rg in "${resource_groups[@]}"; do
    execute_command "az vm list --resource-group $rg --query '[].{Name:name, ResourceGroup:resourceGroup}' -o json" "virtual_machines" &
    execute_command "az webapp list --resource-group $rg --query '[].{Name:name, ResourceGroup:resourceGroup}' -o json" "web_apps" &
    execute_command "az network vnet list --resource-group $rg --query '[].{Name:name, ResourceGroup:resourceGroup, AddressSpace:addressSpace, Subnets:subnets}' -o json" "virtual_networks" &
    execute_command "az network nsg list --resource-group $rg --query '[].{Name:name, ResourceGroup:resourceGroup, SecurityRules:securityRules}' -o json" "network_security_groups" &
    execute_command "az network public-ip list --resource-group $rg --query '[].{Name:name, ResourceGroup:resourceGroup, IpAddress:ipAddress}' -o json" "public_ips" &
    execute_command "az network lb list --resource-group $rg --query '[].{Name:name, ResourceGroup:resourceGroup, FrontendIpConfigurations:frontendIpConfigurations, BackendAddressPools:backendAddressPools}' -o json" "load_balancers" &
    execute_command "az network application-gateway list --resource-group $rg --query '[].{Name:name, ResourceGroup:resourceGroup, Sku:sku, GatewayIpConfigurations:gatewayIpConfigurations}' -o json" "application_gateways" &
    execute_command "az storage account list --resource-group $rg --query '[].{Name:name, ResourceGroup:resourceGroup, Sku:sku, Kind:kind}' -o json" "storage_accounts" &
    execute_command "az keyvault list --resource-group $rg --query '[].{Name:name, ResourceGroup:resourceGroup, Sku:sku, VaultUri:vaultUri}' -o json" "key_vaults" &
    execute_command "az cdn waf policy list --resource-group $rg --query '[].{Name:name, ResourceGroup:resourceGroup, PolicySettings:policySettings, Rules:rules}' -o json" "cdn_waf_policies" &
    execute_command "az network front-door waf-policy list --resource-group $rg --query '[].{Name:name, ResourceGroup:resourceGroup, PolicySettings:policySettings, Rules:rules}' -o json" "front_door_waf_policies" &
    execute_command "az search service list --resource-group $rg --query '[].{Name:name, ResourceGroup:resourceGroup, Properties:properties, QueryKeys:queryKeys}' -o json" "search_services" &
    execute_command "az webapp deployment slot list --resource-group $rg --query '[].{Name:name, ResourceGroup:resourceGroup, Properties:properties, Configurations:configurations}' -o json" "webapp_deployment_slots" &
done
wait

# Execute commands for each VM in parallel
for vm in "${vm_names[@]}"; do
    execute_command "az vm show --name $vm --query '{Name:name, HardwareProfile:hardwareProfile, StorageProfile:storageProfile, NetworkProfile:networkProfile}' -o json" "virtual_machine_details" &
done
wait

# Execute commands for each web app in parallel
for app in "${web_app_names[@]}"; do
    execute_command "az webapp show --name $app --query '{Name:name, State:state, HostNames:hostNames, SiteConfig:siteConfig}' -o json" "web_app_details" &
done
wait

# Execute other commands in parallel
execute_command "az network vnet list --query '[].{Name:name, ResourceGroup:resourceGroup, AddressSpace:addressSpace, Subnets:subnets}' -o json" "virtual_networks_global" &
execute_command "az network nsg list --query '[].{Name:name, ResourceGroup:resourceGroup, SecurityRules:securityRules}' -o json" "network_security_groups_global" &
execute_command "az network public-ip list --query '[].{Name:name, ResourceGroup:resourceGroup, IpAddress:ipAddress}' -o json" "public_ips_global" &
execute_command "az network lb list --query '[].{Name:name, ResourceGroup:resourceGroup, FrontendIpConfigurations:frontendIpConfigurations, BackendAddressPools:backendAddressPools}' -o json" "load_balancers_global" &
execute_command "az network application-gateway list --query '[].{Name:name, ResourceGroup:resourceGroup, Sku:sku, GatewayIpConfigurations:gatewayIpConfigurations}' -o json" "application_gateways_global" &
execute_command "az storage account list --query '[].{Name:name, ResourceGroup:resourceGroup, Sku:sku, Kind:kind}' -o json" "storage_accounts_global" &
execute_command "az keyvault list --query '[].{Name:name, ResourceGroup:resourceGroup, Sku:sku, VaultUri:vaultUri}' -o json" "key_vaults_global" &
execute_command "az network route-table list --query '[].{Name:name, ResourceGroup:resourceGroup, Routes:routes}' -o json" "route_tables" &
execute_command "az network private-endpoint list --query '[].{Name:name, ResourceGroup:resourceGroup, PrivateLinkServiceConnections:privateLinkServiceConnections}' -o json" "private_endpoints" &
execute_command "az network bastion list --query '[].{Name:name, ResourceGroup:resourceGroup, DnsName:dnsName}' -o json" "bastions" &
execute_command "az network vpn-gateway list --query '[].{Name:name, ResourceGroup:resourceGroup, GatewayType:gatewayType, VpnType:vpnType}' -o json" "vpn_gateways" &
execute_command "az network ddos-protection list --query '[].{Name:name, ResourceGroup:resourceGroup, VirtualNetworks:virtualNetworks}' -o json" "ddos_protection_plans" &
execute_command "az network express-route list --query '[].{Name:name, ResourceGroup:resourceGroup, CircuitProvisioningState:circuitProvisioningState, ServiceProviderProvisioningState:serviceProviderProvisioningState}' -o json" "express_route_circuits" &
execute_command "az sql server list --query '[].{Name:name, ResourceGroup:resourceGroup, Location:location, FullyQualifiedDomainName:fullyQualifiedDomainName}' -o json" "sql_servers" &
execute_command "az sql db list --query '[].{Name:name, ResourceGroup:resourceGroup, ServerName:serverName, Edition:edition}' -o json" "sql_databases" &
execute_command "az acr list --query '[].{Name:name, ResourceGroup:resourceGroup, Sku:sku, AdminUserEnabled:adminUserEnabled}' -o json" "container_registries" &
execute_command "az aks list --query '[].{Name:name, ResourceGroup:resourceGroup, KubernetesVersion:kubernetesVersion, ProvisioningState:provisioningState}' -o json" "kubernetes_clusters" &
execute_command "az cosmosdb list --query '[].{Name:name, ResourceGroup:resourceGroup, DatabaseAccountOfferType:databaseAccountOfferType, DocumentEndpoint:documentEndpoint}' -o json" "cosmos_db_accounts" &
execute_command "az monitor log-profiles list --query '[].{Name:name, RetentionPolicy:retentionPolicy, Locations:locations}' -o json" "monitor_log_profiles" &
execute_command "az monitor diagnostic-settings list --query '[].{Name:name, StorageAccountId:storageAccountId, WorkspaceId:workspaceId, LogAnalyticsDestinationType:logAnalyticsDestinationType}' -o json" "monitor_diagnostic_settings" &
execute_command "az monitor activity-log list --offset 7d --query '[].{Authorization:authorization, Claims:claims, HttpRequest:httpRequest, ResourceId:resourceId, SubscriptionId:subscriptionId}' -o json" "activity_logs" &
execute_command "az monitor scheduled-query-rules list --query '[].{Name:name, Properties:properties, Conditions:conditions, Actions:actions}' -o json" "scheduled_query_rules" &
wait

# Print completion message
echo "Script execution completed. Output files generated in the 'azure_resources' directory."
