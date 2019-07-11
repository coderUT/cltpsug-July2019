$resourceLocation = "eastus"

#Resource Group Name
$vmResourceGroupName = "cltpsugcompute"
$networkResourceGroupName = "cltpsugnetwork"
$storageResourceGroupName = "cltpsugstorage"
$infrastructureResourceGroupName = "infrastructure";

#Project Tag
$tags = @{'Project'='cltpsug'}

#Create the Resource Groups w/Tags
try { $vmRG = Get-AzResourceGroup -Name $vmResourceGroupName `
	-ErrorAction Stop 
	Set-AzResourceGroup -Name $vmResourceGroupName -Tag $tags }
catch { $vmRg = New-AzResourceGroup -Name $vmResourceGroupName `
                    -Location $resourceLocation `
                    -Tag $tags }

try { $networkRg = Get-AzResourceGroup -Name $networkResourceGroupName `
	-ErrorAction Stop 
	Set-AzResourceGroup -Name $networkResourceGroupName -Tag $tags }
catch { $networkRg = New-AzResourceGroup -Name $networkResourceGroupName `
                    -Location $resourceLocation `
                    -Tag $tags }

try { $storageRg = Get-AzResourceGroup -Name $storageResourceGroupName `
	-ErrorAction Stop 
	Set-AzResourceGroup -Name $storageResourceGroupName -Tag $tags }
catch { $storageRg = New-AzResourceGroup -Name $storageResourceGroupName `
                    -Location $resourceLocation `
                    -Tag $tags }

#Configure the Policy to apply the 'Project' Tag to all child Resources
$policyTagParameter = @{'tagName'='Project'}
$policyDefinition = Get-AzPolicyDefinition -BuiltIn `
| where {$_.Properties.displayName -eq 'Append tag and `its value from the resource group'}

#Apply Policy to Resource Groups
$policyAssignmentName = "Append Project Tag to Resources"

try { Get-AzPolicyAssignment -Name $policyAssignmentName -Scope $vmRg.ResourceId `
    -ErrorAction Stop }
catch { New-AzPolicyAssignment -Name $policyAssignmentName `
-Scope $vmRg.ResourceId -PolicyDefinition $policyDefinition `
-PolicyParameterObject $policyTagParameter }

try { Get-AzPolicyAssignment -Name $policyAssignmentName -Scope $networkRg.ResourceId `
    -ErrorAction Stop }
catch { New-AzPolicyAssignment -Name $policyAssignmentName `
-Scope $networkRg.ResourceId -PolicyDefinition $policyDefinition `
-PolicyParameterObject $policyTagParameter }

try { Get-AzPolicyAssignment -Name $policyAssignmentName -Scope $storageRg.ResourceId `
    -ErrorAction Stop }
catch { New-AzPolicyAssignment -Name $policyAssignmentName `
-Scope $storageRg.ResourceId -PolicyDefinition $policyDefinition `
-PolicyParameterObject $policyTagParameter }

#Create Resource Group without Tags
try { $infrastructureResourceGroup = Get-AzResourceGroup -Name $infrastructureResourceGroupName `
        -ErrorAction Stop }
catch { $infrastructureResourceGroup = New-AzResourceGroup -Name $infrastructureResourceGroupName `
                                                -Location $resourceLocation }
