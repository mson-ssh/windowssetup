# activation.ps1 - Activate Windows / Office via Microsoft Activation Scripts (MAS)

function Get-WindowsActivationStatus {
    $product = Get-CimInstance -ClassName SoftwareLicensingProduct -Filter "Name like 'Windows%'" -ErrorAction SilentlyContinue |
        Where-Object { $_.PartialProductKey } |
        Select-Object -First 1

    if (-not $product) {
        return 'Unknown'
    }

    $status = $product.LicenseStatus
    switch ($status) {
        1 { return 'Activated' }
        0 { return 'Not Activated' }
        default { return "Unknown ($status)" }
    }
}

function Get-OfficeActivationStatus {
    $product = Get-CimInstance -ClassName SoftwareLicensingProduct -ErrorAction SilentlyContinue |
        Where-Object {
            $_.PartialProductKey -and (
                $_.Name -match 'Office' -or
                $_.Name -match 'Microsoft 365' -or
                $_.Description -match 'Office'
            )
        } |
        Select-Object -First 1

    if (-not $product) {
        return 'Not Installed / Unknown'
    }

    $status = $product.LicenseStatus
    switch ($status) {
        1 { return 'Activated' }
        0 { return 'Not Activated' }
        default { return "Unknown ($status)" }
    }
}

function Get-ActivationStatus {
    return Get-WindowsActivationStatus
}

function Invoke-Activation {
    param(
        [ValidateSet('HWID','KMS38','Ohook')]
        [string]$Method = 'HWID'
    )
    Write-Log "Starting Windows activation using method: $Method"

    $currentWindowsStatus = Get-WindowsActivationStatus
    $currentOfficeStatus = Get-OfficeActivationStatus
    Write-Log "Current Windows status: $currentWindowsStatus"
    Write-Log "Current Office status: $currentOfficeStatus"

    if ($Method -eq 'HWID' -and $currentWindowsStatus -eq 'Activated') {
        Write-Log 'Windows is already activated. Skipping HWID activation.' 'INFO'
        return
    }

    if ($Method -eq 'Ohook' -and $currentOfficeStatus -eq 'Activated') {
        Write-Log 'Office is already activated. Skipping Ohook activation.' 'INFO'
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
