# Carlos A. Gomes dotfiles

Dotfiles are used to customize and automate you daily work on the terminal using
scripts and aliases.

The "dotfiles" name is derived from the configuration files in Unix-like systems
that start with a dot.

#### e.g.:

- `.bash_aliases`
- `.gitconfig`

## Installation

### Using Git and the bootstrap script

Clone the repository:

```bash
git clone https://github.com/carlos-algms/dotfiles.git
cd dotfiles
```

The bootstrapper script will create symbolic links in the home folder replacing
existing files, so remember to backup.

**Files to backup:**

- `~/.bashrc`
- `~/.bash_profile`
- `~/.zshrc`

#### Mac & Linux installation

```bash
./bootstrap.sh
```

#### Windows installation

```bat
bootstrap.bat
```

## Installation System

### Main Bootstrap

- **Entry point**: `./bootstrap.sh` - Orchestrates all installation scripts
- **Architecture**: Iterates through subdirectories running individual
  `install.sh` scripts
- **Logging**: All scripts source `shell/common/01_logging.sh` for consistent
  output (e_header, e_success, e_error, e_arrow)
- **OS Detection**: Scripts source `shell/common/00_os.sh` which exports
  `IS_WIN`, `IS_MAC`, `IS_LINUX` environment variables

### Module Structure

Each major component has its own `install.sh`:

- `shell/install.sh` - Shell configuration (detects OS and delegates to
  platform-specific installers)
- `neovim/install.sh` - Neovim setup (installs via brew/apt, creates symlink
  from `neovim/nvim` to `~/.config/nvim`)
- `kitty/install.sh` - Kitty terminal (macOS only, symlinks config files)

### Installation Pattern

- Scripts create symlinks to this repository rather than copying files
- Existing files are backed up with timestamp suffix before linking
- Platform-specific installers in `shell/[linux|macos|windows]/install-*.sh`

## Key Commands

```bash
# Install/update all configurations
./bootstrap.sh

# OR Install individual components
./shell/install.sh
./neovim/install.sh
./kitty/install.sh

# Sync neovim config via SSH
# Like a shared host like HostGator, GoDaddy, etc..
./neovim/sync-via-ssh.sh
```

---

## Author

| [![avatar]][site]       |
| ----------------------- |
| [Carlos A. Gomes][site] |

[avatar]:
  https://avatars2.githubusercontent.com/u/4634613?s=120&v=4
  'See more on my site.'
[site]: http://carlos-algms.github.io/
