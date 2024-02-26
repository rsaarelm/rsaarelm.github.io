:title The setup
:date 2024-02-26

How I set up the computer in the objectively correct way.

## Directory structure

Where does stuff go?

### `~/hearth/`

[We are no longer in control of our home directories.](https://web.archive.org/web/20190202163008/https://0x46.net/thoughts/2019/02/01/dotfile-madness/)
So I've set up a `~/hearth/` directory in the home directory that contains all the stuff I know I care about and have put there myself.
Backing up should be a matter of taking a snapshot of `~/hearth/`.
Most of the contents of the hearth directory are git repos for work projects and various personal logs and archives.

### Project files

Programming projects are going to generate lots of object files, a Rust project can create multiple gigabytes of them, and none of them are of any interest for backups, so the work directories are going to be over at `~/work/`.
What I do back up are the git repos, which are stored out-of-directory at `~/hearth/git/[PROJECT]` for `~/work/[PROJECT]`.

You can set up a git project like this like so:

    mkdir -p ~/work/PROJECT
    cd ~/work/PROJECT
    git init --separate-git-dir ~/hearth/git/PROJECT

### Media files

I use [git-annex](https://git-annex.branchable.com/) to manage media.
It has somewhat many moving parts and assumes you're comfortable with regular git.
I use `git-annex addurl URL --file LOCALNAME` whenever I can to store images that are currently online and downloadable without additional hoop-jumping.
The URLs may eventually bitrot, but as long as they haven't, my annex will be able to reacquire the file from the web.

Media goes on the biggest hard drive on the machine, which may be different from where the OS root partition is installed.
In this case, it should have its own mount point, something like `/vol/data0`.
Use symlinks to point here from home dir.

#### Media folder structure

* `~/media/` git-annex root, may be a symlink to external disk volume
  * `archive/` miscellaneous stuff like website dumps saved for posterity
  * `games/` installation files for old video games
  * `pics/` pictures from the internet, symlinked at `~/Pictures`
  * `music/` symlinked at `~/Music`
  * `video/` symlinked at `~/Videos`
  * `doc/` PDF and DjVu books and articles, symlinked at `~/Documents`
    * `3/` CGI and 3D modeling
    * `biz/` Business
    * `cog/` Cognitive science
    * `design/` Design and writing
    * `eng/` Engineering and architecture
    * `g/` Computing
    * `his/` History
    * `lit/` Mainstream fiction
      * `sf/` Science fiction
      * `fantasy/` Fantasy and horror
      * `fic/` Internet fics
    * `misc/` Other nonfiction, usually popular books
    * `mil/` Military
    * `phi/` Philosophy
    * `pol/` Politics and sociology
    * `sci/` Science and mathematics
    * `skill/` How-to books
    * `tg/` Role-playing games
    * `v/` Video game development
    * `x/` Conspiracy, occult and paranormal
    * `epub/` EPUB docs, whole subdir is synced to smartphone, subdir structure mirrors one in `doc/`

Research projects get their own named folders under `doc/` that contain references.
Since git-annex uses symlinks, the same document can be linked from several places from the file tree without taking up extra space.

### Transient files

I probably won't be keeping every random file I download around forever.
The nice thing would be to set up a periodic task that cleans up files older than 30 days from `~/tmp/`.
I do a lazier thing and just put temporary stuff in the system `/tmp/` directory that gets wiped every time the machine boots.
Also it gets wiped if the machine fails to wake up from suspend which happens every now and then with my desktop, or if I do something that gets the machine hanging badly enough that it needs to be rebooted, so it's not really ideal for anything that needs any degree of permanence beyond the immediate current session.

## Dotfile management

I use the [homegit idiom](https://web.archive.org/web/20231125044053/https://www.kerrickstaley.com/2023/11/24/homegit) for versioning my dotfiles.
Tried and abandoned GNU stow (minor annoyances and a feature I wanted to use has had an unfixed bug for years) and Nix Home Manager (not usable without having Nix installed, overcomplicated).
Homegit is dead simple, can be deployed anywhere where git is present and does what I need.

Hosts that require local customizations to configs have a local branch that has the host changes in the top commit, this gets rebased anew when it needs changing.
Most homegit changes I make on any host belong in the master branch, so wrote [`homegit-shunt`](https://github.com/rsaarelm/dotfiles/blob/master/bin/homegit-shunt) to move general feature commits made on top of the host branch up to the master branch with a single command.
Updates can be pulled to customized hosts with `homegit pull origin master:master; homegit rebase master` without checking out of the host branch.

## LAN host naming

Hosts are named after chemical elements, which are also used to derive static local IP addresses for them. The wireless address is the regular address + 100.
Host `cobalt` would have alias `co`, be 192.168.1.27 over Ethernet and 192.168.1.127 over WiFi.
Configuring hosts to have static IP addresses is annoying, so instead I still use DHCP and configure my router to assign the desired specific addresses based on connection MAC.

## TODO

* API key management
* Using [restic](https://restic.net/) to back up `~/hearth`, backup recovery procedures
* Synchronizing `~/hearth` dirs with [Syncthing](https://syncthing.net/)

## TODO NixOS flake-based OS

## Programs

* [NixOS Linux](https://nixos.org/) with a [flake-based system configuration](https://github.com/rsaarelm/dotfiles/tree/master/homegit)
* [Neovim](https://neovim.io/). Might switch to [Helix](https://helix-editor.com/) if it gets [folding support](https://github.com/helix-editor/helix/issues/1840)
* [i3wm](https://i3wm.org/). Might switch to Wayland and Sway if I ever upgrade my ancient GPU to one that can run Wayland with fast drivers.
* [Git](https://git-scm.com/). Out of all the weird fiddly alternative tools I really like, somehow Git ended up being used by everyone else as well.
* [fish shell](https://fishshell.com/) has good defaults out of the box.
  I tried [nushell](https://www.nushell.sh/) but it felt a bit too clunky for a daily driver.
* [st simple terminal](https://st.suckless.org/) works great on a Raspberry Pi and on the janky desktop GPU that started glitching with Alacritty.
  You need to run things inside tmux if you want scrollback though.
* [WeeChat](https://weechat.org/) I've grudgingly gotten along with the times and now go to IRC in a WeeChat in tmux instead of an irssi in screen.
* [zoxide](https://github.com/ajeetdsouza/zoxide) better cd command
* [ripgrep](https://github.com/BurntSushi/ripgrep) better grep
* [NetworkManager](https://networkmanager.dev/) (`nmcli`) for connecting to WiFi
