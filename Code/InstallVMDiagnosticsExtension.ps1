$resourceLocation = "eastus"

#Resource Groups
$vmResourceGroupName = "cltpsugcompute"
$storageResourceGroupName = "cltpsugstorage";

$vmdiagsStorageAccountName = "cltpsugvmdiags";
#Create a VM Diagnostics Storage Account if necesssary
try { Get-AzStorageAccount -Name $vmdiagsStorageAccountName `
       -ResourceGroupName $storageResourceGroupName -ErrorAction Stop}
catch {
    New-AzStorageAccount -Name $vmdiagsStorageAccountName `
                         -ResourceGroupName $storageResourceGroupName `
                         -Location $resourceLocation `
                         -SkuName Standard_LRS -Kind StorageV2
}

$vmName = "windowsvm"
#Access VM Runtime Object
try { 
$vmRunTime = Get-AzVM -Name $vmName -ResourceGroupName $vmResourceGroupName `
-Status -ErrorAction Stop
$vmCfg = Get-AzVM -Name $vmName -ResourceGroupName $vmResourceGroupName
}
catch {
    Write-Output ("Error accessing VM {0} status" -f $vmName)
    Exit
}

#Status code is "PowerState/deallocated" if stopped and deallocated
#VM needs to be running to install VM extensions
if(($vmRunTime.Statuses | where {$_.Code -eq "PowerState/running"}).Count -eq 1) {
    #Check the Guest Agent Status
    if(($vmRunTime.VMAgent.Statuses | where {($_.Code -eq "ProvisioningState/succeeded") -and `
            ($_.DisplayStatus -eq "Ready")}).Count -eq 1) {
        
        #Update The WadCfg Template
        $diagnosticsTemplateCfgPath = ("{0}\WadCfg.template.xml" -f (Get-Location).Path)
        $diagnosticsCfgPath = ("{0}\WadCfg.xml" -f (Get-Location).Path)

        $wadxml = [xml](Get-Content $diagnosticsTemplateCfgPath)
        $wadxml.DiagnosticsConfiguration.PublicConfig.WadCfg.DiagnosticMonitorConfiguration.Metrics.`
        SetAttribute("resourceId",$vmCfg.Id)
        $wadxml.Save($diagnosticsCfgPath)
                
        Set-AzVMDiagnosticsExtension -VMName $vmName -ResourceGroupName $vmResourceGroupName `
                                     -autoUpgradeMinorVersion $true `
                                     -DiagnosticsConfigurationPath $diagnosticsCfgPath `
                                     -StorageAccountName $vmdiagsStorageAccountName
    } else {
        Write-Output ("VM {0}, VMAgent must be provisioned and ready to install VM Extensions" -f $vmName)
    }
} else {
    Write-Output ("VM {0} needs to be running to install VM Extensions" -f $vmName)
}







