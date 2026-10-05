# TerPwshIns

PowerShell installer for Termux with a dedicated Debian environment.

**Made By Aryan Giri | giriaryan694-a11y**

---

## What is TerPwshIns?

**TerPwshIns** installs PowerShell 7.6.6 inside a dedicated Debian `proot-distro` container on ARM64 Termux.

It also connects the PowerShell environment to your existing Termux environment by sharing:

- Termux binaries
- Termux home directory

This lets you use PowerShell while still accessing tools and files from Termux.

---

## Why use it?

Termux is a great way to learn Linux through everyday use.

Instead of only reading about commands, filesystems, PATH variables, permissions, package managers, and shell scripting, you can actually use them regularly on your Android device.

For example, everyday Termux usage teaches you things like:

```text
cd
ls
mkdir
cp
mv
rm
chmod
$PATH
apt
git
python
````

Over time, Linux concepts become much more natural because you are using them rather than just memorizing them.

TerPwshIns extends that learning experience to PowerShell.

You can move between Linux-style tools and PowerShell commands while working with the same Termux files and binaries.

---

## How it works

TerPwshIns creates a dedicated Debian container named:

```text
pwsh
```

PowerShell is installed inside:

```text
/root/powershell
```

The Termux `pwsh` command launches that container and starts PowerShell.

The wrapper mounts two Termux directories:

```text
$PREFIX  →  /termux
$HOME    →  /termux-home
```

So the environment looks approximately like:

```text
Termux
│
├── $PREFIX
│   └── bin
│
├── $HOME
│
└── pwsh
     │
     ▼
Dedicated Debian container
│
├── PowerShell
├── /root/powershell
├── /termux/bin
└── /termux-home
```

---

## Shared Termux binaries

Termux normally stores its executable binaries under:

```text
/data/data/com.termux/files/usr/bin
```

TerPwshIns mounts `$PREFIX` as:

```text
/termux
```

Therefore the Termux binary directory becomes:

```text
/termux/bin
```

The PowerShell profile adds it to the PATH:

```powershell
$env:PATH = "/root/powershell:/termux/bin:" + $env:PATH
```

This allows PowerShell to find commands installed through Termux.

For example:

```powershell
python --version
```

```powershell
git --version
```

```powershell
curl --version
```

The important point is that PowerShell accesses them through:

```text
/termux/bin
```

rather than the original Android Termux path.

---

## Shared Termux home

Your normal Termux home directory is mounted as:

```text
/termux-home
```

Inside PowerShell:

```powershell
Set-Location /termux-home
```

or:

```powershell
cd /termux-home
```

Then list your normal Termux files:

```powershell
Get-ChildItem
```

You can also access individual files:

```powershell
Get-Content /termux-home/example.txt
```

Create a file directly in the shared Termux home:

```powershell
New-Item /termux-home/test.txt
```

This means files created in `/termux-home` are also available from your normal Termux shell.

---

## Useful paths

| Purpose                 | Path                                                        |
| ----------------------- | ----------------------------------------------------------- |
| PowerShell installation | `/root/powershell`                                          |
| Termux binaries         | `/termux/bin`                                               |
| Termux home             | `/termux-home`                                              |
| PowerShell profile      | `/root/.config/powershell/Microsoft.PowerShell_profile.ps1` |

---

## Installation

### Using the repository

```bash
bash install-pwsh.sh --install
```

### Using curl

You can execute the installer directly from GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/giriaryan694-a11y/TerPwshIns/refs/heads/main/install-pwsh.sh | bash -s -- --install
```

The installer expects:

```text
ARM64 / aarch64
```

---

## Options

### Install

```bash
bash install-pwsh.sh --install
```

Installs the dedicated PowerShell environment.

### Reinstall

```bash
bash install-pwsh.sh --reinstall
```

Removes the existing `pwsh` container and installs it again.

### Remove

```bash
bash install-pwsh.sh --rm
```

or:

```bash
bash install-pwsh.sh --remove
```

Removes the dedicated PowerShell environment and Termux wrapper.

### Skip updates

```bash
bash install-pwsh.sh --install --skip-update
```

Skips repository updates where possible.

For a completely fresh Debian container, the script may still run `apt-get update` once because Debian needs package indexes before packages can be installed.

### Help

```bash
bash install-pwsh.sh --help
```

---

## After installation

Start PowerShell directly from Termux:

```bash
pwsh
```

Check the PowerShell version:

```bash
pwsh -Command '$PSVersionTable'
```

Or from inside PowerShell:

```powershell
$PSVersionTable
```

---

## Working with the shared Termux home

From PowerShell:

```powershell
Set-Location /termux-home
```

List files:

```powershell
Get-ChildItem
```

Show hidden files:

```powershell
Get-ChildItem -Force
```

Create a directory:

```powershell
New-Item -ItemType Directory projects
```

Move into it:

```powershell
Set-Location projects
```

Create a file:

```powershell
New-Item test.txt
```

Because `/termux-home` is your real Termux home mounted into the container, these files can also be accessed from Termux.

---

## Running Termux tools from PowerShell

Because `/termux/bin` is added to PATH, commands installed through Termux can be available from PowerShell.

Example:

```powershell
python --version
```

```powershell
git --version
```

Check the PATH:

```powershell
$env:PATH
```

You should see:

```text
/root/powershell:/termux/bin:...
```

---

## Separate Debian environment

TerPwshIns does not replace your normal Debian container.

Your existing Debian environment remains separate:

```bash
proot-distro login debian
```

The PowerShell environment uses:

```bash
proot-distro login pwsh
```

So you can keep using both independently.

---

## Learning Linux with Termux

One of the useful things about Termux is that Linux concepts become part of normal daily computer usage.

You might start with something simple:

```bash
cd ~/projects
```

Then gradually learn:

```text
filesystem
├── directories
├── permissions
├── PATH
├── processes
├── packages
├── networking
└── shell scripting
```

You are learning these concepts by actually using them.

TerPwshIns is built around the same idea.

It gives you a PowerShell environment without completely disconnecting it from the Termux environment you already use.

You can learn:

```text
Linux shell
     ↓
Termux
     ↓
Debian
     ↓
PowerShell
     ↓
Shared binaries + files
```

This makes the setup useful not only for running PowerShell, but also for learning how different command-line environments interact.

---

## Repository

```text
https://github.com/giriaryan694-a11y/TerPwshIns
```

Installer:

```text
install-pwsh.sh
```

Direct installer:

```text
https://raw.githubusercontent.com/giriaryan694-a11y/TerPwshIns/refs/heads/main/install-pwsh.sh
```

---

## Credits

**Made By Aryan Giri | giriaryan694-a11y**

```
