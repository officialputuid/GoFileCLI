<div align="center">

# 📦 GoFileCLI (gfcli)

**Quickly upload and download files with GoFile.io from your terminal**

[![Shell Script](https://img.shields.io/badge/Shell-Script-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://github.com/officialputuid/GoFileCLI)
[![GoFile.io](https://img.shields.io/badge/GoFile-.io-00A8E8?style=for-the-badge)](https://gofile.io)

</div>

---

## ✨ Features

- 📤 **Upload Files** - Upload files to GoFile.io directly from CLI
- 📥 **Download Files** - Download files or folders from GoFile.io by content ID or full link
- ⚡ **Fast & Simple** - Lightweight script with minimal dependencies
- ⬆️ **Inline Commands** - Supports quick upload (`-u`) and download (`-d`) inline without menu
- 🌐 **Cross-Platform** - Works on Linux, STB/Armbian, and Termux

## 📋 Requirements

Before installation, ensure you have the following installed:

- `curl` - For HTTP requests
- `jq` - For JSON parsing
- `sha256sum` - For hashing password (usually preinstalled)

```
# Install on Debian/Ubuntu
sudo apt install curl jq

# Install on Termux
pkg install curl jq
```

## 🚀 Installation

Simply:
```
sudo wget https://raw.githubusercontent.com/officialputuid/GoFileCLI/refs/heads/main/gfcli.sh && bash gfcli.sh
```

or choose the installation method based on your platform:

| Platform    | Installation Command                                                                                             |
|:-----------:|:--------------------------------------------------------------------------------------------------------------:|
| **Linux**   | `sudo wget https://raw.githubusercontent.com/officialputuid/GoFileCLI/refs/heads/main/gfcli.sh -O /usr/local/bin/gfcli && sudo chmod +x /usr/local/bin/gfcli` |
| **STB/Armbian** | `sudo wget https://raw.githubusercontent.com/officialputuid/GoFileCLI/refs/heads/main/gfcli.sh -O /usr/bin/gfcli && sudo chmod +x /usr/bin/gfcli`        |
| **Termux**  | `wget https://raw.githubusercontent.com/officialputuid/GoFileCLI/refs/heads/main/gfcli.sh -O $HOME/gfcli && chmod +x $HOME/gfcli && mv $HOME/gfcli /data/data/com.termux/files/usr/bin/` |

> **Note:** For Termux, `sudo` is not needed as it doesn't use sudo by default.

## 💻 Usage

After installation, run the tool using one of these methods:

```
bash gfcli.sh
```
```
gfcli | gfcli -u | gfcli -d
```

### 💻 Interactive Menu

Run the command without arguments to use the interactive menu:

```
bash gfcli.sh

1) Download
2) Upload
3) Exit
Choose [1/2/3]:
```

### 💻 Inline Commands

For quick single commands without menu interaction:

- Upload a file:

  ```
  gfcli -u /path/to/file
  ```

- Download by full link or content ID, with optional password:

  ```
  gfcli -d https://gofile.io/d/<content_id> / <content_id>  [password]
  ```

💻 Examples:

```
gfcli -u ~/downloads/example.txt
gfcli -d https://gofile.io/d/id12345 password
gfcli -d id12345
```

## 🙏 Credits

- **[GoFile.io](https://gofile.io)** - An amazing platform to upload unlimited files of any size to fast servers, completely free!
- Built with ❤️ by [@officialputuid](https://github.com/officialputuid)
