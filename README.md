# Carlos A. Gomes dotfiles

Dotfiles are used to customize and automate you daily work on the terminal using scripts and aliases.

The "dotfiles" name is derived from the configuration files in Unix-like systems that start with a dot.

#### e.g.:
* `.bash_aliases`
* `.gitconfig`

Those files are hidden by default because they are not important to common users.


## Installation

**Warning:** If you want to give my dotfiles a try, you should first fork this repository,  
review the code, and remove things you don't want or need.  
Don't blindly use my settings unless you know what that entails.

**Use at your own risk!**

### Using Git and the bootstrap script

You can clone the repository wherever you want.

```bash
git clone https://github.com/carlos-algms/dotfiles.git
cd dotfiles
```

The bootstrapper script will create symbolic links into your home folder replacing your current files, so, remember to backup.  
**Files to backup:**

* `~/.bashrc`
* `~/.bash_profile`

#### Linux installation

```bash
./bootstrap.sh
```

#### Windows installation

```bat
bootstrap.bat
```

You can also [download the zip][zip-link], unpack and install following the instructions above.

### Customizations

It is not necessary to change files inside this project to make customizations.
Edit the files located into your own home folder and they will be loaded:

| Place | Description |
| --- | --- |
| `~/.bash_aliases` | A file to include command aliases. e.g: `alias v="vim"` |
| `~/.bash_functions` | In this file you can put more complex functions: e.g.: `sendLogsByEmail() { .... }` |
| `~/.bash_extras/*.sh` | Every file with extension `.sh` in this folder will be loaded |

Bin folders located into your user home will be exposed to `$PATH`.
Any executable file inside those folders will be available as commands.

* `~/bin`
* `~/.bin`
* `~/.local/bin`

## Author

| [![avatar]][site] |
|---|
| [Carlos A. Gomes][site]|

[avatar]: https://avatars2.githubusercontent.com/u/4634613?s=120&v=4 "See more on my site."
[site]: http://carlos-algms.github.io/
[zip-link]: https://github.com/carlos-algms/dotfiles/archive/master.zip
