# WinSetup Pro

Công cụ cài đặt và tối ưu Windows tự động với giao diện WPF.

## Cài đặt nhanh

Chạy lệnh sau trong PowerShell **với quyền Administrator**:

```powershell
irm https://raw.githubusercontent.com/mson-ssh/windowssetup/main/install.ps1 | iex
```

**Cách hoạt động:**
1. 📥 Tải toàn bộ project từ GitHub dưới dạng ZIP
2. 📦 Giải nén vào thư mục tạm
3. 🚀 Chạy GUI WPF
4. 🧹 Tự động dọn dẹp sau khi xong

## Tính năng

- ✅ Cài đặt phần mềm tự động (browsers, messaging, dev tools, runtimes...)
- ✅ Kích hoạt Windows/Office (HWID, KMS38, Ohook)
- ✅ Tối ưu hệ thống (tắt telemetry, dark mode, power plan...)
- ✅ Giao diện WPF thân thiện
- ✅ Hỗ trợ winget, chocolatey, scoop

## Cấu trúc dự án

```
winsetup-pro/
├── install.ps1         # Entry point (chạy từ irm)
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
