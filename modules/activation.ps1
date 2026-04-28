# activation.ps1 - Activate Windows / Office via Microsoft Activation Scripts (MAS)

function Get-ActivationStatus {
    try {
        $product = Get-CimInstance -ClassName SoftwareLicensingProduct -Filter "Name like 'Windows%'" -ErrorAction Stop |
            Where-Object { $_.PartialProductKey } |
            Select-Object -First 1

        if (-not $product) {
            Write-Log 'Activation status could not be determined from SoftwareLicensingProduct.' 'WARN'
            return 'Unknown'
        }

        $status = $product.LicenseStatus
        switch ($status) {
            1 { return 'Activated' }
            0 { return 'Not Activated' }
            default { return "Unknown ($status)" }
        }
    } catch {
        Write-Log "Activation status check failed: $_" 'WARN'
        return 'Unknown'
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
