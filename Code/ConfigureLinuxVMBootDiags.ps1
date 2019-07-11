$resourceLocation = "eastus"
#Resource Groups
$vmResourceGroupName = "cltpsugcompute"
$storageResourceGroupName = "cltpsugstorage"

$bootdiagsStorageAccountName = "cltpsugbootdiags"
#Create a Diagnostics Storage Account if necessary
try { Get-AzStorageAccount -Name $bootdiagsStorageAccountName `
    -ResourceGroupName $storageResourceGroupName -ErrorAction Stop}
catch {
    
    New-AzStorageAccount -Name $bootdiagsStorageAccountName `
    -ResourceGroupName $storageResourceGroupName `
    -Location $resourceLocation -SkuName Standard_LRS `
    -Kind StorageV2
}

$linuxVMName = "linuxvm"
$linuxVM = Get-AzVM -Name $linuxVMName `
 -ResourceGroupName $vmResourceGroupName
Set-AzVMBootDiagnostic -VM $linuxVM -Enable `
 -StorageAccountName $bootdiagsStorageAccountName `
 -ResourceGroupName $storageResourceGroupName
Update-AzVM -VM $linuxVM -ResourceGroupName $vmResourceGroupName