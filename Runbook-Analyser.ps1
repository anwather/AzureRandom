$connectionName = "AzureRunAsConnection"
try {
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$servicePrincipalConnection) {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    }
    else {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

$AutomationAccounts = Get-AzureRMAutomationAccount

$reportedViolations = @('PSAvoidUsingConvertToSecureStringWithPlainText',
    'PSUsePSCredentialType',
    'PSAvoidUsingPlainTextForPassword',
    'PSAvoidUsingInvokeExpression',
    'PSAvoidUsingUserNameAndPassWordParams')

$builtInRunbooks = @('AzureAutomationTutorialScript',
    'AzureClassicAutomationTutorialScript')

$outputArray = @()
foreach ($AutomationAccount in $AutomationAccounts) {
    $Runbooks = $AutomationAccount | Get-AzureRMAutomationRunbook | Where-Object {$_.RunbookType -match "^PowerShell$|^Script$" -and $_.Name -notin $builtInRunbooks}

    foreach ($runbook in $Runbooks) {
        $output = $null
        $AutomationAccount | Export-AzureRmAutomationRunbook -Name $runbook.Name -OutputFolder $env:Temp -Verbose -Force
        $output = Invoke-ScriptAnalyzer -Path "$env:Temp\$($runbook.Name).ps1"
        if ($null -ne $output) {
            $violations = $null
            $violations = $output | Where-Object RuleName -in $reportedViolations
            if ($null -ne $violations) {
                foreach ($v in $violations) {
                    $obj = $null
                    $obj = @{
                        AutomationAccountName = $AutomationAccount.AutomationAccountName
                        ResourceGroupName     = $AutomationAccount.ResourceGroupName
                        Runbook               = $runbook.Name
                        RuleName              = $v.RuleName
                    }
                    $outputArray += New-Object -TypeName PSCustomObject -Property $obj

                }
                Set-AzureRmAutomationRunbook -Tag @{CodeViolation = "True"} -Name $runbook.Name -ResourceGroupName $AutomationAccount.ResourceGroupName -AutomationAccountName $AutomationAccount.AutomationAccountName

            }
        }
    }
}

Write-Output $outputArray