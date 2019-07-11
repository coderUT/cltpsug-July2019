$resourceLocation = "eastus"
$resourceGroupName = "cltpsugnetwork"
$virtualNetworkAddrSpace = "10.1.0.0/16"
$subnet1AddrSpace = "10.1.0.0/24"
$subnet2AddrSpace = "10.1.1.0/24"

$virtualNetworkCfg = @{
    Name = "vnet";
    ResourceGroupName = $resourceGroupName;
    Location = $resourceLocation;
    AddressPrefix = $virtualNetworkAddrSpace;
}

$subnet1Cfg = @{Name = "subnet1"; AddressPrefix = $subnet1AddrSpace;}
$subnet2Cfg = @{Name = "subnet2"; AddressPrefix = $subnet2AddrSpace;}    

#Get/Configure the Virtual Network
try { $vnet = Get-AzVirtualNetwork -Name $virtualNetworkCfg['Name'] `
    -ResourceGroupName $resourceGroupName -ErrorAction Stop }
catch { $vnet = New-AzVirtualNetwork @virtualNetworkCfg }

#Get/Configure the Subnets
try { $subnet1 = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet `
                            -Name $subnet1Cfg['Name'] -ErrorAction Stop }
catch {
    Add-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet @subnet1Cfg
    $vnet = ($vnet | Set-AzVirtualNetwork)
    $subnet1 = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $subnet1Cfg['Name'] }

try { $subnet2 = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet `
                            -Name $subnet2Cfg['Name'] -ErrorAction Stop}
catch {
    Add-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet @subnet2Cfg
    $vnet = ($vnet | Set-AzVirtualNetwork)
    $subnet2 = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $subnet2Cfg['Name'] }


#Get/Configure the Network Interfaces
$subnet1Nic1Cfg = @{
    Name = "nic1_1"; ResourceGroupName = $resourceGroupName;
    Location = $resourceLocation;
}
$subnet2Nic1Cfg = @{
    Name = "nic2_1"; ResourceGroupName = $resourceGroupName;
    Location = $resourceLocation
}

$subnet1Nic1IPCfg = @{Name = "ipcfg1"; PrivateIpAddress = "10.1.0.4";}
$subnet2Nic1IPCfg1 = @{Name = "ipcfg1"; PrivateIpAddress = "10.1.1.4";}

#Create the 10.1.0.4 Network Interface (Subnet 1)
try { $nic1_1 = Get-AzNetworkInterface -Name $subnet1Nic1Cfg['Name'] `
        -ResourceGroupName $resourceGroupName -ErrorAction Stop }
catch {
    $nic1_1ipcfg1 = New-AzNetworkInterfaceIpConfig @subnet1Nic1IPCfg -Subnet $subnet1
    $nic1_1 = New-AzNetworkInterface -IpConfiguration $nic1_1ipcfg1 @subnet1Nic1Cfg
    $vnet = Get-AzVirtualNetwork -Name $virtualNetworkCfg['Name'] -ResourceGroupName $resourceGroupName
    $subnet1 = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $subnet1Cfg['Name']
}

#Create the 10.1.1.4 Network Interface (Subnet 2)
try { $nic2_1 = Get-AzNetworkInterface -Name $subnet2Nic1Cfg['Name'] `
        -ResourceGroupName $resourceGroupName -ErrorAction Stop }
catch {
    $nic2_1ipcfg1 = New-AzNetworkInterfaceIpConfig @subnet2Nic1IPCfg1 -Subnet $subnet2
    $nic2_1 = New-AzNetworkInterface -IpConfiguration $nic2_1ipcfg1 @subnet2Nic1Cfg
    $vnet = Get-AzVirtualNetwork -Name $virtualNetworkCfg['Name'] -ResourceGroupName $resourceGroupName
    $subnet2 = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $subnet1Cfg['Name']
}