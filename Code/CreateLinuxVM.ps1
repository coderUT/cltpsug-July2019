$resourceLocation = "eastus"
$vmName = "linuxvm"
$vmAdminUserName = "vmadmin"
$adminCredential = Get-Credential -UserName $vmAdminUserName `
-Message "Enter a password for vm admin acct";
#Read in an SSH Public Key or set to empty string
$publicKey = ""

$vmCfg = New-AzVMConfig -VMName $vmName -VMSize "Standard_B2ms"

#Linux VM
Set-AzVMOperatingSystem -VM $vmCfg -Linux -ComputerName $vmName `
-Credential $adminCredential
if($publicKey.Length -gt 0) {
    Write-Output "Configuring Admin SSH Public Key"
    Add-AzVMSshPublicKey -VM $vmCfg -KeyData $publicKey `
    -Path ("/home/{0}/.ssh/authorized_keys" -f $vmAdminUserName)
}

#Managed Disks, 32GB Standard Storage, Name: <vmName>OSDisk
$OSDiskCfg = @{ Name = ("{0}OSDisk" -f $vmCfg.Name); StorageAccountType = "Standard_LRS"; `
    Caching = "None"; CreateOption = "FromImage"; DiskSizeInGB = 32}
#Configure for Ubuntu 18.04-LTS
$mktplaceImageCfg = @{ PublisherName = "Canonical"; Offer = "UbuntuServer"; `
    Skus = "18.04-LTS"; Version = "latest" }
Set-AzVMOSDisk -VM $vmCfg -Linux @OSDiskCfg
Set-AzVMSourceImage -VM $vmCfg @mktplaceImageCfg
#Disable Boot Diags so we can set them in a different part of the script
Set-AzVMBootDiagnostic -VM $vmCfg -Disable

#Resource Groups
$vmResourceGroupName = "cltpsugcompute"
$networkingResourceGroupName = "cltpsugnetwork"
#Network Interface
$nicName = "nic2_1";

#Network Interface nic2_1: (10.1.1.4) 
$nic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $networkingResourceGroupName
Add-AzVMNetworkInterface -VM $vmCfg -NetworkInterface $nic

#Create the VM
New-AzVM -VM $vmCfg -ResourceGroupName $vmResourceGroupName -Location $resourceLocation

