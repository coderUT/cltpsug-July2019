$resourceLocation = "eastus"

$infrastructureResourceGroupName = "infrastructure";
$hubVNetName = "gatewayvnet"

$networkResourceGroupName = "cltpsugnetwork";
$spokeVNetName = "vnet"

$hubVNet = Get-AzVirtualNetwork -Name $hubVNetName `
            -ResourceGroupName $infrastructureResourceGroupName
$spokeVNet = Get-AzVirtualNetwork -Name $spokeVNetName `
            -ResourceGroupName $networkResourceGroupName

#Create the Peering from "Hub" to "Spoke"
Add-AzVirtualNetworkPeering -Name "hubToSpoke" -VirtualNetwork $hubVNet `
    -RemoteVirtualNetworkId $spokeVNet.Id -AllowGatewayTransit


#Create the Peering from "Spoke" to "Hub"
Add-AzVirtualNetworkPeering -Name "spokeToHub" -VirtualNetwork $spokeVNet `
    -RemoteVirtualNetworkId $hubVNet.Id -UseRemoteGateways