$resourceLocation = "eastus"
$vmName = "windowsvm"
$vmAdminUserName = "vmadmin"
$adminCredential = Get-Credential -UserName $vmAdminUserName `
-Message "Enter a password for vm admin acct";

$vmCfg = New-AzVMConfig -VMName $vmName -VMSize "Standard_B2ms"

#Windows VM
Set-AzVMOperatingSystem -VM $vmCfg -Windows -ComputerName $vmName `
-Credential $adminCredential

#Managed Disks, 32GB Standard Storage, Name: <vmName>OSDisk
$OSDiskCfg = @{ Name = ("{0}OSDisk" -f $vmCfg.Name); StorageAccountType = "Standard_LRS"; `
    Caching = "None"; CreateOption = "FromImage"; DiskSizeInGB = 32}
#Configure for Windows Server 2016 Server Core
$mktplaceImageCfg = @{ PublisherName = "MicrosoftWindowsServer"; Offer = "WindowsServer"; `
    Skus = "2016-Datacenter-Server-Core-smalldisk"; Version = "latest" }
Set-AzVMOSDisk -VM $vmCfg -Windows @OSDiskCfg
Set-AzVMSourceImage -VM $vmCfg @mktplaceImageCfg
#Disable Boot Diags so we can set them in a different part of the script
Set-AzVMBootDiagnostic -VM $vmCfg -Disable

#Resource Groups
$vmResourceGroupName = "cltpsugcompute"
$networkingResourceGroupName = "cltpsugnetwork"
#Network Interface
$nicName = "nic1_1";

#Network Interface nic1_1: (10.1.0.4) 
$nic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $networkingResourceGroupName
Add-AzVMNetworkInterface -VM $vmCfg -NetworkInterface $nic

#Create the VM
New-AzVM -VM $vmCfg -ResourceGroupName $vmResourceGroupName -Location $resourceLocation
