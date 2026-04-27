# WinSetup Pro

Công cụ cài đặt và tối ưu Windows tự động với giao diện WPF.

## Cài đặt nhanh

### Cách 1: Quick Launch (Nhanh nhất - Khuyên dùng)

```powershell
& ([scriptblock]::Create((irm "https://raw.githubusercontent.com/mson-ssh/windowssetup/main/quick.ps1")))
```

> ⚡ **Siêu nhanh:** Load trực tiếp từ GitHub vào RAM, không cần tải ZIP hay giải nén.

### Cách 2: ZIP Installer (Ổn định hơn)

```powershell
irm https://raw.githubusercontent.com/mson-ssh/windowssetup/main/install.ps1 | iex
```

> 📦 **Ổn định:** Tải toàn bộ project dưới dạng ZIP, giải nén và chạy local.

## Tính năng

- ✅ Cài đặt phần mềm tự động (browsers, messaging, dev tools, runtimes...)
- ✅ Kích hoạt Windows/Office (HWID, KMS38, Ohook)
- ✅ Tối ưu hệ thống (tắt telemetry, dark mode, power plan...)
- ✅ Giao diện WPF thân thiện
- ✅ Hỗ trợ winget, chocolatey, scoop

## Cấu trúc dự án

```
winsetup-pro/
├── setup.ps1           # Entry point (chạy từ irm)
├── run.ps1             # Chạy local để test
├── main.ps1            # GUI WPF
├── config/
│   └── apps.json       # Danh sách phần mềm
└── modules/
    ├── logger.ps1      # Ghi log
    ├── installer.ps1   # Cài đặt app
    ├── activation.ps1  # Kích hoạt Windows/Office
    └── optimizer.ps1   # Tối ưu hệ thống
```

## License

MIT
