# Carlos A. Gomes dotfiles

Dotfiles are used to customize and automate you daily work on the terminal using scripts and aliases.

The "dotfiles" name is derived from the configuration files in Unix-like systems that start with a dot.

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

The bootstrapper script will create symbolic links into your home folder replacing your current files, so, remember to backup.  
**Files to backup:**

- `~/.bashrc`
- `~/.bash_profile`

#### Linux installation

```bash
./bootstrap.sh
```

#### Windows installation

```bat
bootstrap.bat
```

## Author

| [![avatar]][site]       |
| ----------------------- |
| [Carlos A. Gomes][site] |

[avatar]: https://avatars2.githubusercontent.com/u/4634613?s=120&v=4 "See more on my site."
[site]: http://carlos-algms.github.io/
