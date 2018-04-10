# Carlos A. Gomes dotfiles

Dotfiles are used to customize and automate you daily work on the terminal using scripts and aliases.

The “dotfiles” name is derived from the configuration files in Unix-like systems that start with a dot.

#### e.g.:
* .bash_aliases
* .gitconfig

Those files are hidden by default because they are not important to common users.


## Installation

**Warning:** If you want to give my dotfiles a try, you should first fork this repository, review the code, and remove things you don’t want or need. Don’t blindly use my settings unless you know what that entails.

**Use at your own risk!**

### Using Git and the bootstrap script

You can clone the repository wherever you want.

```bash
git clone https://github.com/carlos-algms/dotfiles.git
cd dotfiles
```

The bootstrapper script will create symbolic links into your home folder replacing your current files, so, remember to backup.

#### Linux installation

```bash
./bootstrap.sh
```

#### Windows installation

```bat
bootstrap.bat
```

## Author

| [![avatar]][site] |
|---|
| [Carlos A. Gomes][site]|

[avatar]: https://avatars2.githubusercontent.com/u/4634613?s=120&v=4 "See more on my site."
[site]: http://carlos-algms.github.io/
