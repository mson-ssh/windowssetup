# activation.ps1 - Activate Windows / Office via Microsoft Activation Scripts (MAS)

function Get-ActivationStatus {
    $status = (Get-CimInstance -ClassName SoftwareLicensingProduct -Filter "Name like 'Windows%'" |
        Where-Object { $_.PartialProductKey } |
        Select-Object -First 1).LicenseStatus
    switch ($status) {
        1 { return 'Activated' }
        0 { return 'Not Activated' }
        default { return "Unknown ($status)" }
    }
}

function Invoke-Activation {
    param(
        [ValidateSet('HWID','KMS38','Ohook')]
        [string]$Method = 'HWID'
    )
    Write-Log "Starting Windows activation using method: $Method"

    $currentStatus = Get-ActivationStatus
    Write-Log "Current status: $currentStatus"

    if ($currentStatus -eq 'Activated' -and $Method -eq 'HWID') {
        Write-Log 'Windows is already activated. Skipping.' 'INFO'
        return
    }

    try {
        # Uses Microsoft Activation Scripts (MAS) - open source
        # See: https://massgrave.dev
        Invoke-RestMethod 'https://get.activated.win' | Invoke-Expression
        Write-Log 'Activation successful' 'OK'
    } catch {
        Write-Log "Activation error: $_" 'ERROR'
    }
}
