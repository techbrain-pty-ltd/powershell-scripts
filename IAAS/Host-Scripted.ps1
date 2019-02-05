#Globals

Function pause ($message)
{
    # Check if running Powershell ISE
    if ($psISE)
    {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show("$message")
    }
    else
    {
        Write-Host "$message" -ForegroundColor Yellow
        $x = $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

#Start Script

#Confirm WinRM is enabled
Write-Host "Setting up WinRM and adding the management server to the trusted hosts"
winrm set winrm/config/client @{TrustedHosts="172.16.100.11"}
Restart-Service WinRM

#Set Firewall to Off
Write-Host "Setting firewall to off..."
netsh advfirewall set allprofiles state off

#Set the PageFile to 6GB on C:\ Drive
Write-Host "Setting a static PageFile..."
$PageFile = Get-WmiObject Win32_ComputerSystem -EnableAllPrivileges
$PageFile.AutomaticManagedPagefile = $False
$PageFile.Put()
$NewPageFile = gwmi -Query "select * from Win32_PageFileSetting where name='C:\\pagefile.sys'"
$NewPageFile.InitialSize = [int]"6144"
$NewPageFile.MaximumSize = [int]"6144"
$NewPageFile.Put()

#Install the Hyper-V Role
Write-Host "Installing the Hyper-V Role"
Install-WindowsFeature -Name Hyper-V -IncludeManagementTools -Restart
Write-Host "Started..."

#Rename the Network Adapters
Write-Host "Renaming the Network Ports..."
Rename-NetAdapter -Name "Ethernet" -NewName "Techbrain Management"
Rename-NetAdapter -Name "Ethernet 2" -NewName "Management HyperV Switch"
Rename-NetAdapter -Name "Ethernet 3" -NewName "VMNetwork HyperV Switch"
Rename-NetAdapter -Name "Ethernet 4" -NewName "Cluster HyperV Switch"
Rename-NetAdapter -Name "Ethernet 5" -NewName "LiveMigration HyperV Switch"
Rename-NetAdapter -Name "Ethernet 6" -NewName "DMZ HyperV Switch"
Write-Host "Done..."

#Create the switches
Write-Host "Creating the Hyper-V Switches..."
New-VMSwitch -Name HyperV-Management-Switch –NetAdapterName "Management HyperV Switch" –MinimumBandwidthMode Weight –AllowManagementOS $true
New-VMSwitch -Name HyperV-VMNetwork-Switch –NetAdapterName "VMNetwork HyperV Switch" –MinimumBandwidthMode Weight –AllowManagementOS $true
New-VMSwitch -Name HyperV-Cluster-Switch –NetAdapterName "Cluster HyperV Switch" –MinimumBandwidthMode Weight –AllowManagementOS $true
New-VMSwitch -Name HyperV-LiveMigration-Switch –NetAdapterName "LiveMigration HyperV Switch" –MinimumBandwidthMode Weight –AllowManagementOS $true
New-VMSwitch -Name HyperV-DMZ-Switch –NetAdapterName "DMZ HyperV Switch" –MinimumBandwidthMode Weight –AllowManagementOS $true
Write-Host "Done..."

#Create the Network Adapters
Write-Host "Adding the Management Network Adapters..."
$designation = Read-Host "Please enter the Customer designation - eg. ESA for Early Start or TB for TechBrain"
Add-VMNetworkAdapter -ManagementOS -SwitchName "HyperV-Management-Switch" -Name "$designation-Domain-Connection"
Add-VMNetworkAdapter -ManagementOS -SwitchName "HyperV-Cluster-Switch" -Name "$designation-Cluster-Connection"
Add-VMNetworkAdapter -ManagementOS -SwitchName "HyperV-LiveMigration-Switch" -Name "$designation-LiveMigration-Connection"
Write-Host "Done..."

#Set the VLAN ID to Trunk on all Interfaces
Write-Host "Setting the VLAN Trunks on all switches and management networks..."
Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName "$designation-Domain-Connection" -Access -VlanId 1
Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName "$designation-Cluster-Connection" -Access -VlanId 3
Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName "$designation-LiveMigration-Connection" -Access -VlanId 4
Write-Host "Done..."

#Add IP Addresses to Interfaces
Write-Host "Adding IP Address to Management Interface..."
#Management
$managementIPServer1 = Read-Host "Please enter the New IP Address for the domain that you have assigned to this server:"
$managementNetmaskServer1 = Read-Host "Please enter the Management Subnetmask in CIDR format (eg. for 255.255.255.0 you should enter 24):"
$managementDGServer1 = Read-Host "Please enter the Default Gateway for this IP address:"
New-NetIPAddress -InterfaceAlias "$designation-Domain-Connection" -IPAddress $managementIPServer1 -PrefixLength $managementNetmaskServer1 -DefaultGateway $managementDGServer1 -Confirm:$false
Write-Host "Done..."
#Cluster
Write-Host "Adding IP Address to Cluster Interface..."
$clusterIPServer1 = Read-Host "Please enter the Cluster IP Address assigned to this server:"
$clusterNetmaskServer1 = Read-Host "Please enter the Cluster Subnetmask in CIDR format (eg. for 255.255.255.0 you should enter 24):"
$clusterDGServer1 = Read-Host "Please enter the Cluster Default Gateway IP address:"
New-NetIPAddress -InterfaceAlias "$designation-Cluster-Connection" -IPAddress $clusterIPServer1 -PrefixLength $clusterNetmaskServer1 -DefaultGateway $clusterDGServer1 -Confirm:$false
Write-Host "Done..."
#LiveMigration
Write-Host "Adding IP Address to LiveMigration Interface..."
$livemigrationIPServer1 = Read-Host "Please enter the Live Migration IP Address assigned to this server:"
$livemigrationNetmaskServer1 = Read-Host "Please enter the Live Migration Subnetmask in CIDR format (eg. for 255.255.255.0 you should enter 24):"
$livemigrationDGServer1 = Read-Host "Please enter the Live Migration Default Gateway IP address:"
New-NetIPAddress -InterfaceAlias "$designation-LiveMigration-Connection" -IPAddress $livemigrationIPServer1 -PrefixLength $livemigrationNetmaskServer1 -DefaultGateway $livemigrationDGServer1 -Confirm:$false
Write-Host "Done..."

#Add the ISO & Script location to the new Hyper-V Server
Write-Host "Updating the local host file for Management purposes..."
If ((Get-Content "$($env:windir)\system32\Drivers\etc\hosts" ) -notcontains "172.21.101.250 TB-IAAS-HV-01")  
 {ac -Encoding UTF8  "$($env:windir)\system32\Drivers\etc\hosts" "172.21.101.250 TB-IAAS-HV-01" };
Write-Host "Added TB Management to the local host file"

#Copy the ISO and scripts to the C:\Tools folder
Write-Host "Creating the tools folder..."
mkdir "C:\Tools"
Write-Host "Mounting the SMB Share..."
New-PSDrive -Name "T" -PSProvider "Filesystem" -Root "\\TB-IAAS-HV-01\share"
Write-Host "Copying ISO and Scripts"
copy T:\*.* C:\Tools\
Remove-PSDrive -Name "T"
Write-Host "Completed configuration"