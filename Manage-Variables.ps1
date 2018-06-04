<#
.SYNOPSIS
Export or import variables to/from an Azure Automation Account
.EXAMPLE
Export all variables (unencrypted)

$resourceGroupName = "MyResourceGroup"
$automationAccountName = "MyAutomationAccount"
$path = "variables.csv"

Manage-Variables.ps1 -ResourceGroupName $ResourceGroupName -AutomationAccountName $automationAccountName -Path $path -Mode Export
.EXAMPLE
Import all variables (unencrypted)

$resourceGroupName = "MyResourceGroup"
$automationAccountName = "MyAutomationAccount"
$path = "variables.csv"

Manage-Variables.ps1 -ResourceGroupName $ResourceGroupName -AutomationAccountName $automationAccountName -Path $path -Mode Import
#>
param (
    [Parameter(Mandatory = $true)]    
    [string]$AutomationAccountName,
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory = $true)]
    [ValidatePattern(".csv$")]
    [string]$Path,
    [Parameter(Mandatory = $true)]
    [ValidateSet("Import", "Export")]
    [string]$Mode)

try {
    Get-AzureRmSubscription -ErrorAction STOP
}
catch {
    Login-AzureRmAccount
}

$aa = Get-AzureRmAutomationAccount -Name $AutomationAccountName -ResourceGroupName $ResourceGroupName

if ($Mode -eq "Export") {
    $aa | Get-AzureRmAutomationVariable | Select-Object Name, Value | Export-Csv $Path -NoTypeInformation
}

if ($Mode -eq "Import") {
    Import-CSV $Path | New-AzureRmAutomationVariable -AutomationAccountName $AutomationAccountName `
        -ResourceGroupName $ResourceGroupName `
        -Encrypted $false
}