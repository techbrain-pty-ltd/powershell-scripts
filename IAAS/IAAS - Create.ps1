netsh advfirewall set allprofiles state off
$PageFile = Get-WmiObject Win32_ComputerSystem -EnableAllPrivileges
$PageFile.AutomaticManagedPagefile = $False
$PageFile.Put()
$NewPageFile = gwmi -Query "select * from Win32_PageFileSetting where name='C:\\pagefile.sys'"
$NewPageFile.InitialSize = [int]"6144"
$NewPageFile.MaximumSize = [int]"6144"
$NewPageFile.Put()
$NICname = Get-NetAdapter | %{$_.name}
New-NetLbfoTeam -Name ESA-IAAS-HV-02-NIC-TEAM-1 –TeamMembers $NICname -TeamingMode SwitchIndependent -LoadBalancingAlgorithm HyperVPort -Confirm:$false
Set-NetLbfoTeam -Name ESA-IAAS-HV-02-NIC-TEAM-1 -TeamingMode SwitchIndependent
New-VMSwitch -Name ESA-HyperV-Switch –NetAdapterName ESA-IAAS-HV-02-NIC-TEAM-1 –MinimumBandwidthMode Weight –AllowManagementOS $false
Add-VMNetworkAdapter –ManagementOS –Name ESA-Management –SwitchName ESA-HyperV-Switch
Set-VMNetworkAdapterVlan –ManagementOS –VMNetworkAdapterName ESA-Management –Access –VlanId 1
Rename-NetAdapter -Name "vEthernet (ESA-Management)" -NewName ESA-Management
New-NetIPAddress -InterfaceAlias ESA-Management -IPAddress 172.21.101.2 -PrefixLength 24 -De2faultGateway 172.21.101.254 -Confirm:$false
Set-DnsClientServerAddress -InterfaceAlias ESA-Management -ServerAddresses 172.21.101.10, 172.21.101.11
Set-VMNetworkAdapter -ManagementOS -name ESA-Management -MinimumBandwidthWeight 10
Add-VMNetworkAdapter –ManagementOS –Name ESA-Cluster –SwitchName ESA-HyperV-Switch
Set-VMNetworkAdapterVlan –ManagementOS –VMNetworkAdapterName ESA-Cluster – –VlanId 4
Rename-NetAdapter -Name "vEthernet (ESA-Cluster)" -NewName ESA-Cluster
New-NetIPAddress -InterfaceAlias ESA-Cluster -IPAddress 172.21.102.2 -PrefixLength 24 -Confirm:$false
Set-VMNetworkAdapter -ManagementOS -name ESA-Cluster -MinimumBandwidthWeight 15
Add-VMNetworkAdapter –ManagementOS –Name ESA-VMNetwork –SwitchName ESA-HyperV-Switch
Set-VMNetworkAdapterVlan –ManagementOS –VMNetworkAdapterName ESA-VMNetwork –Access –VlanId 2
Rename-NetAdapter -Name "vEthernet (ESA-VMNetwork)" -NewName ESA-VMNetwork
New-NetIPAddress -InterfaceAlias ESA-VMNetwork -IPAddress 172.21.103.2 -PrefixLength 24 -Confirm:$false
Set-VMNetworkAdapter -ManagementOS -name ESA-VMNetwork -MinimumBandwidthWeight 30
Add-VMNetworkAdapter –ManagementOS –Name ESA-LiveMigration –SwitchName ESA-HyperV-Switch
Set-VMNetworkAdapterVlan –ManagementOS –VMNetworkAdapterName ESA-LiveMigration –Access –VlanId 5
Rename-NetAdapter -Name "vEthernet (ESA-LiveMigration)" -NewName ESA-LiveMigration
New-NetIPAddress -InterfaceAlias ESA-LiveMigration -IPAddress 172.21.104.2 -PrefixLength 24 -Confirm:$false
Set-VMNetworkAdapter -ManagementOS -name ESA-LiveMigration -MinimumBandwidthWeight 15
Add-VMNetworkAdapter –ManagementOS –Name TB-Management –SwitchName ESA-HyperV-Switch
Set-VMNetworkAdapterVlan –ManagementOS –VMNetworkAdapterName TB-Management –Access –VlanId 0
Rename-NetAdapter -Name "vEthernet (TB-Management)" -NewName TB-Management
New-NetIPAddress -InterfaceAlias TB-Management -IPAddress 172.21.100.5 -PrefixLength 24 -Confirm:$false
Set-VMNetworkAdapter -ManagementOS -name TB-Management -MinimumBandwidthWeight 10

sconfig



dcpromo.exe /unattend /NewDomain:forest /ReplicaOrNewDomain:Domain /NewDomainDNSName:domain.tld /DomainLevel:4 /ForestLevel:4 /SafeModeAdminPassword:"cwKhYH1%wr1B"



Set-Service -Name msiscsi -StartupType Automatic
Start-Service msiscsi
Enable-WindowsOptionalFeature –Online –FeatureName MultiPathIO
Enable-MSDSMAutomaticClaim -BusType iSCSI
Set-MSDSMGlobalDefaultLoadBalancePolicy -Policy RR
