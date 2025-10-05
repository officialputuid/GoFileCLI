<div align="center">

# 📦 GoFileCLI (gfcli)

**Quickly upload and download files with GoFile.io from your terminal**

[![Shell Script](https://img.shields.io/badge/Shell-Script-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://github.com/officialputuid/GoFileCLI)
[![GoFile.io](https://img.shields.io/badge/GoFile-.io-00A8E8?style=for-the-badge)](https://gofile.io)

</div>

---

## ✨ Features

- 📤 **Upload Files** - Upload files to GoFile.io directly from CLI
- 📥 **Download Files** - Download files from GoFile.io with ease
- ⚡ **Fast & Simple** - Lightweight script with minimal dependencies
- 🌐 **Cross-Platform** - Works on Linux, STB/Armbian, and Termux

## 📋 Requirements

Before installation, ensure you have the following installed:

- `curl` - For HTTP requests
- `jq` - For JSON parsing

```bash
# Install on Debian/Ubuntu
sudo apt install curl jq

# Install on Termux
pkg install curl jq
```

## 🚀 Installation

Simply:
```bash
sudo wget https://raw.githubusercontent.com/officialputuid/GoFileCLI/refs/heads/main/gfcli.sh && bash gfcli.sh
```

or choose the installation method based on your platform:

| Platform | Installation Command |
|:--------:|:--------------------:|
| **Linux** | `sudo wget https://raw.githubusercontent.com/officialputuid/GoFileCLI/refs/heads/main/gfcli.sh -O /usr/local/bin/gfcli && sudo chmod +x /usr/local/bin/gfcli` |
| **STB/Armbian** | `sudo wget https://raw.githubusercontent.com/officialputuid/GoFileCLI/refs/heads/main/gfcli.sh -O /usr/bin/gfcli && sudo chmod +x /usr/bin/gfcli` |
| **Termux** | `wget https://raw.githubusercontent.com/officialputuid/GoFileCLI/refs/heads/main/gfcli.sh -O $HOME/gfcli && chmod +x $HOME/gfcli && mv $HOME/gfcli /data/data/com.termux/files/usr/bin/` |

> **Note:** For Termux, `sudo` is not needed as it doesn't use sudo by default.

## 💻 Usage

After installation, run the tool using one of these methods:

| Method | Command |
|:------:|:-------:|
| **Direct script** | `bash gfcli.sh` |
| **Installed binary** | `gfcli` |

### Interactive Menu

Once you run the command, you'll be presented with an interactive menu:

```bash
1) Download
2) Upload
3) Exit
Choose [1/2/3]:
```

Simply select the option by entering the corresponding number:
- **Option 1:** Download files from GoFile.io
- **Option 2:** Upload files to GoFile.io

## 🙏 Credits

- **[GoFile.io](https://gofile.io)** - An amazing platform to upload unlimited files of any size to fast servers, completely free!
- Built with ❤️ by [@officialputuid](https://github.com/officialputuid)
