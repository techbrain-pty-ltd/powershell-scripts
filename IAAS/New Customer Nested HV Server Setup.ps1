<#
.SYNOPSIS
    This script creates 2 Hyper-V VMs in the IaaS Environment

.DESCRIPTION
    Using Powershell, this script creates 2 nested Hyper-V Servers on the TB-IAAS-HV-01 Blade.  It attaches HDD, adds the windows ISO for setup and assigns a NIC to the TB Management Switch. 

.PARAMETER UseExitCode
    This switch will cause the script to close after the error is logged if an error occurs.

    It is used to pass the error number back to the task scheduler.

.EXAMPLE
    CreateNewTenant.ps1

    Description
    ----------
    You just need to run the PS Script from an elevated Powershell window.

.NOTES
    Author: Dave Forster
    Updated: 2019-01-29
        Tested in live environment to check for errors.  None found.
    Date Started: 2019-01-25
#>

#Set Client Abbreviation
$clientabbr = Read-Host "Please enter the client abbreviation - for example Techbrain would be TB, Early Start Australia would be ESA"
#Set Hyper-V Server Name
$servername1 = "$clientabbr-IAAS-HV-01"
$servername2 = "$clientabbr-IAAS-HV-02"
#Create the VM and Config Directory
New-Item -ItemType directory -Path "F:\Hyper-V\VHDS\$clientabbr"
$VHDPathServer1 = New-Item -ItemType directory -Path "F:\Hyper-V\VHDS\$clientabbr\$servername1"
$VHDPathServer2 = New-Item -ItemType directory -Path "F:\Hyper-V\VHDS\$clientabbr\$servername2"
New-Item -ItemType directory -Path "F:\Hyper-V\Configs\$clientabbr"
New-Item -ItemType directory -Path "F:\Hyper-V\Configs\$clientabbr\$servername1"
New-Item -ItemType directory -Path "F:\Hyper-V\Configs\$clientabbr\$servername2"
$ConfigPathServer1 = "F:\Hyper-V\Configs\$clientabbr"
$ConfigPathServer2 = "F:\Hyper-V\Configs\$clientabbr"
#Set Memory Allocation
[int64]$memoryAlloc = 1GB*(Read-Host "Please enter the initial memory allocation in GB")
#Set HDD Initial Size
[int64]$VHDInitialSize = 1GB*(Read-Host "Please enter the initial HDD size for the VM in GB")
#Set CPU Count
$cpucount = Read-Host "Please enter the number of CPUs for the virtual machine (Default is 6)"

#Create the Virtual Machine
New-VM -Name $clientabbr"-IAAS-HV-01" -MemoryStartupBytes $memoryAlloc -BootDevice VHD -NewVHDPath "$VHDPathServer1\$servername1.vhdx" -Path $ConfigPathServer1 -NewVHDSizeBytes $VHDInitialSize -Generation 2 -Switch "TB Customer Management"
New-VM -Name $clientabbr"-IAAS-HV-02" -MemoryStartupBytes $memoryAlloc -BootDevice VHD -NewVHDPath "$VHDPathServer2\$servername2.vhdx" -Path $ConfigPathServer2 -NewVHDSizeBytes $VHDInitialSize -Generation 2 -Switch "TB Customer Management"

#Expose the Virtualisation Flags to the OS
Set-VMProcessor -VMName "$clientabbr-IAAS-HV-01" -ExposeVirtualizationExtensions $true -count $cpucount
Set-VMProcessor -VMName "$clientabbr-IAAS-HV-02" -ExposeVirtualizationExtensions $true -count $cpucount

#Add the DVD and ISO to the VMs
Add-VMDvdDrive -VMName $servername1 -Path "C:\Tools\SW_DVD9_Win_Server_STD_CORE_2019_64Bit_English_DC_STD_MLF_X21-96581.iso"
Add-VMDvdDrive -VMName $servername2 -Path "C:\Tools\SW_DVD9_Win_Server_STD_CORE_2019_64Bit_English_DC_STD_MLF_X21-96581.iso"
#Set the VM to boot from ISO
$VM1DvdDrive = Get-VMDvdDrive -VMName $servername1
$VM2DvdDrive = Get-VMDvdDrive -VMName $servername2
Set-VMFirmware -VMName $servername1 -FirstBootDevice $VM1DvdDrive -EnableSecureBoot Off
Set-VMFirmware -VMName $servername2 -FirstBootDevice $VM2DvdDrive -EnableSecureBoot Off

#Add the required NICs to the servers
Add-VMNetworkAdapter -VMName "$clientabbr-IAAS-HV-01" -SwitchName "Customer Switch" -Name "Management NIC"
Set-VMNetworkAdapter -VMName "$clientabbr-IAAS-HV-01" -Name "Management NIC" -MacAddressSpoofing On
Add-VMNetworkAdapter -VMName "$clientabbr-IAAS-HV-01" -SwitchName "Customer Switch" -Name "VMNetwork NIC"
Set-VMNetworkAdapter -VMName "$clientabbr-IAAS-HV-01" -Name "VMNetwork NIC" -MacAddressSpoofing On
Add-VMNetworkAdapter -VMName "$clientabbr-IAAS-HV-01" -SwitchName "Customer Switch" -Name "Cluster NIC"
Set-VMNetworkAdapter -VMName "$clientabbr-IAAS-HV-01" -Name "Cluster NIC" -MacAddressSpoofing On
Add-VMNetworkAdapter -VMName "$clientabbr-IAAS-HV-01" -SwitchName "Customer Switch" -Name "LiveMigration NIC"
Set-VMNetworkAdapter -VMName "$clientabbr-IAAS-HV-01" -Name "LiveMigration NIC" -MacAddressSpoofing On
Add-VMNetworkAdapter -VMName "$clientabbr-IAAS-HV-01" -SwitchName "Customer Switch" -Name "DMZ NIC"
Set-VMNetworkAdapter -VMName "$clientabbr-IAAS-HV-01" -Name "DMZ NIC" -MacAddressSpoofing On
Add-VMNetworkAdapter -VMName "$clientabbr-IAAS-HV-02" -SwitchName "Customer Switch" -Name "Management NIC"
Set-VMNetworkAdapter -VMName "$clientabbr-IAAS-HV-02" -Name "Management NIC" -MacAddressSpoofing On
Add-VMNetworkAdapter -VMName "$clientabbr-IAAS-HV-02" -SwitchName "Customer Switch" -Name "VMNetwork NIC"
Set-VMNetworkAdapter -VMName "$clientabbr-IAAS-HV-02" -Name "VMNetwork NIC" -MacAddressSpoofing On
Add-VMNetworkAdapter -VMName "$clientabbr-IAAS-HV-02" -SwitchName "Customer Switch" -Name "Cluster NIC"
Set-VMNetworkAdapter -VMName "$clientabbr-IAAS-HV-02" -Name "Cluster NIC" -MacAddressSpoofing On
Add-VMNetworkAdapter -VMName "$clientabbr-IAAS-HV-02" -SwitchName "Customer Switch" -Name "LiveMigration NIC"
Set-VMNetworkAdapter -VMName "$clientabbr-IAAS-HV-02" -Name "LiveMigration NIC" -MacAddressSpoofing On
Add-VMNetworkAdapter -VMName "$clientabbr-IAAS-HV-02" -SwitchName "Customer Switch" -Name "DMZ NIC"
Set-VMNetworkAdapter -VMName "$clientabbr-IAAS-HV-02" -Name "DMZ NIC" -MacAddressSpoofing On
Set-VMNetworkAdapterVlan -VMName "$clientabbr-IAAS-HV-01" -VMNetworkAdapterName "Management NIC" -Trunk -AllowedVlanIdList 1-1024 -NativeVlanID 0
Set-VMNetworkAdapterVlan -VMName "$clientabbr-IAAS-HV-01" -VMNetworkAdapterName "VMNetwork NIC" -Trunk -AllowedVlanIdList 1-1024 -NativeVlanID 0
Set-VMNetworkAdapterVlan -VMName "$clientabbr-IAAS-HV-01" -VMNetworkAdapterName "Cluster NIC" -Trunk -AllowedVlanIdList 1-1024 -NativeVlanID 0
Set-VMNetworkAdapterVlan -VMName "$clientabbr-IAAS-HV-01" -VMNetworkAdapterName "LiveMigration NIC" -Trunk -AllowedVlanIdList 1-1024 -NativeVlanID 0
Set-VMNetworkAdapterVlan -VMName "$clientabbr-IAAS-HV-01" -VMNetworkAdapterName "DMZ NIC" -Trunk -AllowedVlanIdList 1-1024 -NativeVlanID 0
Set-VMNetworkAdapterVlan -VMName "$clientabbr-IAAS-HV-02" -VMNetworkAdapterName "Management NIC" -Trunk -AllowedVlanIdList 1-1024 -NativeVlanID 0
Set-VMNetworkAdapterVlan -VMName "$clientabbr-IAAS-HV-02" -VMNetworkAdapterName "VMNetwork NIC" -Trunk -AllowedVlanIdList 1-1024 -NativeVlanID 0
Set-VMNetworkAdapterVlan -VMName "$clientabbr-IAAS-HV-02" -VMNetworkAdapterName "Cluster NIC" -Trunk -AllowedVlanIdList 1-1024 -NativeVlanID 0
Set-VMNetworkAdapterVlan -VMName "$clientabbr-IAAS-HV-02" -VMNetworkAdapterName "LiveMigration NIC" -Trunk -AllowedVlanIdList 1-1024 -NativeVlanID 0
Set-VMNetworkAdapterVlan -VMName "$clientabbr-IAAS-HV-02" -VMNetworkAdapterName "DMZ NIC" -Trunk -AllowedVlanIdList 1-1024 -NativeVlanID 0

#Start the VMs
Start-VM -Name $servername1
Start-VM -Name $servername2

Write-Host "Thank you.  Your VM's have been created and are awaiting Operating System Installation.  Please connect to the console and install Windows 2019 Core ONLY."
Write-Host "Please ensure you set an IP address on the single NIC to an address on the 172.21.100.0/24 Network (exlcuding 172.21.100.200 and above) once built - use sconfig.exe to set"