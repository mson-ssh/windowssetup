# activation.ps1 - Kich hoat Windows / Office qua Microsoft Activation Scripts (MAS)

function Get-ActivationStatus {
    $status = (Get-CimInstance -ClassName SoftwareLicensingProduct -Filter "Name like 'Windows%'" |
        Where-Object { $_.PartialProductKey } |
        Select-Object -First 1).LicenseStatus
    switch ($status) {
        1 { return 'Da kich hoat' }
        0 { return 'Chua kich hoat' }
        default { return "Trang thai: $status" }
    }
}

function Invoke-Activation {
    param(
        [ValidateSet('HWID','KMS38','Ohook')]
        [string]$Method = 'HWID'
    )
    Write-Log "Bat dau kich hoat Windows bang phuong phap: $Method"

    $currentStatus = Get-ActivationStatus
    Write-Log "Trang thai hien tai: $currentStatus"

    if ($currentStatus -eq 'Da kich hoat' -and $Method -eq 'HWID') {
        Write-Log 'Windows da duoc kich hoat. Bo qua.' 'INFO'
        return
    }

    try {
        # Tich hop Microsoft Activation Scripts (MAS) - nguon mo
        # Xem: https://massgrave.dev
        Invoke-RestMethod 'https://get.activated.win' | Invoke-Expression
        Write-Log 'Kich hoat thanh cong' 'OK'
    } catch {
        Write-Log "Loi khi kich hoat: $_" 'ERROR'
    }
}
