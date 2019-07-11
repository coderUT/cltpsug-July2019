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

$windowsVMName = "windowsvm"
$windowsVM = Get-AzVM -Name $windowsVMName `
 -ResourceGroupName $vmResourceGroupName
Set-AzVMBootDiagnostic -VM $windowsVM -Enable `
 -StorageAccountName $bootdiagsStorageAccountName `
 -ResourceGroupName $storageResourceGroupName
Update-AzVM -VM $windowsVM -ResourceGroupName $vmResourceGroupName