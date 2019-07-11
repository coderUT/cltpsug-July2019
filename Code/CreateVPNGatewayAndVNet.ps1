$resourceLocation = "eastus"
$infrastructureResourceGroupName = "infrastructure";
$gatewayVirtualNetworkAddressSpace = "10.2.0.0/16"
$gatewaySubnetAddrSpace = "10.2.0.0/28"

$gatewayVirtualNetworkCfg = @{
    Name = "gatewayvnet";
    ResourceGroupName = $infrastructureResourceGroupName;
    Location = $resourceLocation;
    AddressPrefix = $gatewayVirtualNetworkAddressSpace;
}

$gatewaySubnetCfg = @{Name = "GatewaySubnet"; AddressPrefix = $gatewaySubnetAddrSpace;}

$gatewayPublicIPCfg = @{
    Name = "gatewaypublicip";
    ResourceGroupName = $infrastructureResourceGroupName;
    Location = $resourceLocation;
    Sku = "Basic";
    AllocationMethod = "Dynamic";
}

$virtualNetworkGatewayCfg = @{
    Name = "vpngateway";
    ResourceGroupName = $infrastructureResourceGroupName;
    GatewayType = "Vpn";
    VpnType = "RouteBased";
    GatewaySku = "Basic";
    Location=$resourceLocation;
}

$vpnClientAddressPool = "172.16.1.0/24";
$vpnClientProtocol = "SSTP"
$rootCertificateCN = "CN=InfraGwayRoot"
$clientCertificateCN = "CN=MyLaptop"

#Get/Configure the Virtual Network
try { $gatewayVnet = Get-AzVirtualNetwork -Name $gatewayVirtualNetworkCfg['Name'] `
    -ResourceGroupName $infrastructureResourceGroupName -ErrorAction Stop }
catch { $gatewayVnet = New-AzVirtualNetwork @gatewayVirtualNetworkCfg }

#Get/Configure the Subnets
try { $gatewaySubnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $gatewayVnet `
                            -Name $gatewaySubnetCfg['Name'] -ErrorAction Stop }
catch {
    Add-AzVirtualNetworkSubnetConfig -VirtualNetwork $gatewayVnet @gatewaySubnetCfg
    $gatewayVnet = ($gatewayVnet | Set-AzVirtualNetwork)
    $gatewaySubnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $gatewayVnet -Name $gatewaySubnetCfg['Name'] }

#Get/Configure the PublicIP Resource
try { $gatewayPublicIP = Get-AzPublicIpAddress -Name $gatewayPublicIPCfg['Name'] `
    -ResourceGroupName $infrastructureResourceGroupName -ErrorAction Stop }
catch { $gatewayPublicIP = New-AzPublicIpAddress @gatewayPublicIPCfg }

#Get/Create the VPN Gateway
try { $vpngateway = Get-AzVirtualNetworkGateway -Name $virtualNetworkGatewayCfg['Name'] `
-ResourceGroupName $infrastructureResourceGroupName -ErrorAction Stop }
catch {$vpngatewayIpCfg = New-AzVirtualNetworkGatewayIpConfig -Name "vpngatewayipcfg" -Subnet $gatewaySubnet `
 -PublicIpAddress $gatewayPublicIP;
$vpngateway = New-AzVirtualNetworkGateway -IpConfigurations $vpngatewayIpCfg @virtualNetworkGatewayCfg}

#Configure the VPN Gateway for P2S, SSTP
$vpngateway = ($vpngateway | Set-AzVirtualNetworkGateway -VpnClientAddressPool $vpnClientAddressPool `
 -VpnClientProtocol SSTP)

#Create Self-Signed Root and Client certificates to use Client Authentication
#Create the Self-Signed Root Certificate (which the Public Key is uploaded to the VPN Gateway as a "Root Certificate"
New-SelfSignedCertificate -Type Custom -KeySpec Signature -Subject $rootCertificateCN -KeyExportPolicy Exportable `
-HashAlgorithm sha256 -KeyLength 2048 -KeyUsageProperty Sign -KeyUsage CertSign -CertStoreLocation "Cert:\CurrentUser\My"

#Now use that Self-Signed Root Certificate to generated a Client Certificate that will be used to authenticate
#the local computer

$rootCertificate = Get-ChildItem -Path "Cert:\CurrentUser\My" | where {$_.Subject -eq $rootCertificateCN }
New-SelfSignedCertificate -Type Custom -KeySpec Signature -Subject $clientCertificateCN -KeyExportPolicy Exportable `
-HashAlgorithm sha256 -KeyLength 2048 -CertStoreLocation "Cert:\CurrentUser\My" -Signer $rootCertificate `
-TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2")

#Upload the Root Certificate
$rootCertBase64 = [System.Convert]::ToBase64String($rootCertificate.RawData)
Add-AzVpnClientRootCertificate -VpnClientRootCertificateName "InfraGwayRoot" -PublicCertData $rootCertBase64 `
-VirtualNetworkGatewayName $virtualNetworkGatewayCfg['Name'] -ResourceGroupName $infrastructureResourceGroupName
