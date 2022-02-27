# Cute Dot

*Cute Dot* is a super tiny dotfile manager based on **zsh** and **rsync**. It's mostly for me, but it's so adorable that I want to share it with everyone.

## Features

- Less than 100 lines! (exclude config)

- Configuration based (like [dotter](https://github.com/SuperCuber/dotter))

- Intuitive and easy-to-use eDSL, powered by zsh

- [GNU Stow](https://www.gnu.org/software/stow/)-like file structure

## Getting Started

1. Copy [cute-dot.zsh](/cute-dot.zsh) to the directory that you want to store your dotfiles.

2. Run `chmod +x cute-dot.zsh` to make it executable. If you use git to manage your dotfiles, you don't have to run `chmod` in other clones. Git will record the `x` bit.

## Configuration

Open `cute-dot.zsh`, you can see a config area enclosed by comments at the end of the file. There are only two configurations:

- **rsync_opt**: Options passed to rsync. For example, you can add `-n` for dry-run, or change `-r` to `-a` to keep metadata (but git will not keep them).

- **profile list**: List of profiles. A profile is a set of dotfiles. It is the basic operation unit. Syntax:

  ```zsh
  <profile-name>.pf {<profile-location> <profile-pattern>}...
  ```

  For example,

  ```zsh
  zsh.pf \
      ~ '.zshenv' \
      ~/.config/zsh '.zshrc *.zsh (^.*)/(^*.zwc)'
  ```

  The `<profile-pattern>` argument is a string of globs. Here is a quick test to see if the last pattern is correct:

  ```console
  $ setopt null_glob extended_glob no_bare_glob_qual
  $ cd ~/.config/zsh
  $ printf '%s\n' .zshrc *.zsh (^.*)/(^*.zwc)
  ```

  The `<profile-pattern>` arguments in a profile should not conflict with each other.

An example is [my dotfiles](https://github.com/QuarticCat/dotfiles).

Remember that you are directly writing a zsh script, you can do many things in it. For example, you can write an OS-dependent config by

```zsh
if [[ $OSTYPE == linux-gnu* ]] {
    # ...
} elif [[ $OSTYPE == darwin* ]] {
    # ...
} else {
    # ...
}
```

## Usage

You can call this script from any path. It does not depend on the working directory.

### List Profiles

```console
$ ./cute-dot.zsh list
```

### Sync Profiles

Copy files from your system to the repo.

```console
$ ./cute-dot.zsh sync [--all | <profile-name>...]
```

### Apply Profiles

Copy files from the repo to your system.

```console
$ ./cute-dot.zsh apply [--all | <profile-name>...]
```

## Extend It As You Like

It might be too simple to meet your needs. However, considering that it is so tiny, everyone learned zsh can easily extend it. This is what I expect it to be -- a start of your own dotfile manager. Here are some examples.

### Configure options from outside

Change the script as

```diff
- rsync_opt='-ri'
+ rsync_opt=${RSYNC_OPT:-'-ri'}
```

Then you can change `rsync_opt` from command line like

```console
RSYNC_OPT='-nri' ./cute-dot.zsh sync --all
```

### Separate config to another file

Change the script as

```diff
- # ----- Config Begin -----
- # ...
- # ------ Config End ------
+ source $DOT_DIR/cute-dot-config.zsh
```

Then you can write your config in `cute-dot-config.zsh`.

### Use GNU Parallel to process profiles in parallel

Change the script as

```diff
+ source $(which env_parallel.zsh)

+ _init() {
+     setopt null_glob extended_glob no_bare_glob_qual
+ }

  _for-each-pf() {  # <func> [--all | <pf-name>...]
      local func=$1; shift
      if [[ $1 == --all ]] {
-         for i in ${(k)pf_map}; $func $i
+         env_parallel "_init; $func" ::: ${(k)pf_map}
      } else {
-         for i in ${(u)@}; $func $i
+         env_parallel "_init; $func" ::: ${(u)@}
      }
  }
```

Then you will find the execution time becomes much faster.

### Use GPG to encrypt files

This is just an example showing how to extend *Cute Dot*. For this purpose, I recommend you to use [git-crypt](https://github.com/AGWA/git-crypt), which works orthogonally with *Cute Dot*.

Change the script as

```diff
+ declare -A enc_map  # <pf-name> : <pat>

+ _add-enc() {  # <pf-name> <pat>
+     local name=${1%.enc}
+     enc_map[$name]=$2
+ }
+ alias -s enc='_add-enc'

+ _gpg-pat() {  # <gpg-opt> <dir> <pat>
+     cd $2 &>/dev/null &&
+     for f in $~=3; {
+         [[ -f $f ]] &&
+         gpg $=1 -o $f.temp $f &&
+         mv -f $f.temp $f
+     }
+ }
+
+ _encrypt() {  # <pf-name>
+     _gpg-pat "-e -r $gpg_rcpt" $DOT_DIR/$1 $enc_map[$1]
+ }
+
+ _decrypt() {  # <pf-name>
+     _gpg-pat "-d -q" $DOT_DIR/$1 $enc_map[$1]
+ }

+ _complete_sync() {  # <pf-name>
+     _decrypt $1 && _sync $1 && _encrypt $1
+ }
+
+ _complete_apply() {  # <pf-name>
+     _decrypt $1 && _apply $1 && _encrypt $1
+ }

- cute-dot-sync()  { _for-each-pf _sync $@ }
- cute-dot-apply() { _for-each-pf _apply $@ }
+ cute-dot-sync()  { _for-each-pf _complete_sync $@ }
+ cute-dot-apply() { _for-each-pf _complete_apply $@ }

+ gpg_rcpt='QuarticCat'  # gpg recipient
```

Then you can configure the files needed to be encrypted like

```zsh
zsh.pf ~/.config/zsh '.zshrc *.zsh (^.*)/(^*.zwc)'
zsh.enc 'snippets-private/*'
```

Similarly, you can implement `<pf-name>.symlink`, `<pf-name>.template` or whatever.

## License

MIT
