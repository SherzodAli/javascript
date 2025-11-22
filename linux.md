# Linux

## Structure

- Linux
- CLI
- Editors (nano, vim)
- Files, Pipes
- Users, Permissions
- Environments & Processes
- Networking & Internet (ssh, sftp, wget, curl)
- Package management (apt, snaps)
- Shell scripts

## Linux

### Unix/Linux

- Linux is Unix-like OS (it's inspired from Unix, but not Unix)
- Unix has its philosophy
    - one program does 1 thing well (others built on top of others)
    - if new version, better create new program and keep old (backward compatibility)
    - output of one program to be an input of another program (streams & pipes)
    - design and build software fast (for the testing & feedback), ideally within weeks

UNIX
├── BSD (Berkeley Software Distribution)
│   ├── NetBSD
│   │   └── OpenBSD
│   ├── FreeBSD
│   └── NextStep → macOS
└── GNU → Linux → Deian → Ubuntu → Mint

- Distributions (distros) share the same micro-kernel which handles memory, I/O, scheduling, processes, etc.
- Debian, Red Hat, Ubuntu, Mint, etc. are sharing this kernel and build stuff around it
- one Linux kernel and million of distos
    - software on top of the kernel: different GUI, programs, package managers, network capabilities, etc.

### Running Linux

```dockerfile
FROM ubuntu:jammy
RUN apt-get update
RUN apt-get install -y sudo vim curl wget net-tools iputils-ping man-db less procps
RUN apt-get install -y build-essential git python3 python3-pip
RUN apt-get clean && rm -rf /var/lib/apt/lists/*
```

```bash
docker build -t ubuntu-rich-full .
docker run -it --rm ubuntu-rich-full
```

## CLI

- **REPL** - [R]ead [E]valuate [P]rint [L]oop. Interactive shell (uses bash) is REPL (you're running bash commands)
- Shell vs Emulator
    - Emulator is what running bash inside of it (Terminal app, Ghostty, Iterm). It can run any number of shells
    - Shell - bash, zsh, sh
        Bash - Bourne again shell, making fun of Bourne shell, it's open-source GNU license
        all impromenets must be published, therefore macOS uses zsh

`pwd` - print working directory
`cd` - change directory
`ls` - list
`command --help` - shows help, how to use
`man command` - show full manual (greater help)

### Arguments/Flags

- One dash for flags means that there're many flags inside (`-help` is `-h -e -l -p`)

**Argument**
`ls /home` - /home is **argument**
`echo hi there` - console.log in bash (need to put in quotes in other shells to be 1 string)
`which ls` - shows full path to a specified program
`type -a echo` - show type of a program (shell builtin, alias, path, etc.)

**Flag**
`pwd --help` - --help is **flag**
`ls -l` - ls with 'long format' flag
`ls -l -a` or `ls -la` - **combining flags** - ls with 'long format' and '--all' flag

**Passing values to flags**
`ls --ignore=home` - `=` sometimes optional (depends on a program) and sometimes can pass same flag multiple times

### CLI Search

**Autocomplete**
- If you enter `cd /ho` and press `tab`, it will autocomplete `cd /home`
- Also it works with binaries `pyth` will be `python3` (it stops at the most unambigious place)
- Some programms also provide autocompletions `git desc` will be `git describe` (not all programms support it)

**History/search**
- All your command history lives in `~/.bash_history`. It saves all commands after logout
- You can hit `CTRL-R` which starts search of your bash history (start typing and press `CTRL-R` to show other options)
    - Use left/right arrow keys and it'll keep shown command

`tail ~/.bash_history` - skow last 10 lines of file
`!!` - run previous command *(bang-bang, instead of exclamation point, because of Comic books in 50's)*
`sudo !!` - rerun last command with sudo

- On Windows to copy/paste in terminal use `Ctrl-Shift-C` & `Ctrl-Shift-V`, because just `Ctrl-C` is Kill signal
- Don't paste everything into terminal. Websites can change its content when copying, adding Return character as well

### CLI Shortcuts

- `Ctrl-A` - takes you to the beginning of the line
- `Ctrl-E` - takes you to the end of the line
- `Ctrl-K` - yank everything after the cursor
- `Ctrl-U` - yank everything before the cursor
- `Ctrl-Y` - paste from yank buffer
- `Ctrl-L` - clear the screen
- `Ctrl-R` - reverse search through history

there're more... feels almost like vim...

### Signal

Most programs implement signals, some don't (up to a program to support it)

- `Ctrl-C` - SIGINT (interrupt signal)
- `Ctrl-D` - SIGQUIT
- SIGTERM (terminate) - when PC shuts down, it sends SIGTERM to all programs (gives timeout)
- SIGKILL (kill -9) - if you want program to stop RIGHT NOW

`kill -l` - shows all signals
`yes` - will spam `y`
`yes n` - will spam `n` (or put whatever after `yes`, it'll spam it)
`tail -f ~/.bash_history` - print last 10 lines and print new updates to the file

`kill -9 $PID` or `kill -SIGKILL $PID`

## Text editors

On any distro there's at least one - Nano or Vim, usually both

qed -> ed (ee-dee) -> ex (extended) -> vi -> vim (vi improved) -> neovim

## Files

### Reading Files

`less` - allows to read file, like vim (good for long files)
`more` - older program than `less` (someone got sick of the things that `more` couldn't do)
`most` - even newer, but not included by defaults. Learn what's included by default

`man less` - read manual for less (man uses less)

`cat file.txt` - reads file, con[cat]enates file to a stdout
`tail file.txt` - reads 10 last lines (or specify flag `-n 20`)
`head file.txt` - read 10 first lines

`mkdir -p /path/to/create` - makes directories (`-p` silently creates all nested folders)

### Creating & Moving Files

`touch file.txt` - creates file (if not exists) and updates created/updated timestamp
`rm file.txt` - remove file (`-r` for folders, `-f` for force - no interaction)
    if rm'ed smth, it's gone, no trash bin

`cp file.txt copied-file.txt` - copy file
`cp -r /home /new-home` - copies all content recursively (directories)

`mv file.tx new-name-file.txt` - move/transfer file (or rename the same path)

**Tar** - like zip, but not necessarily compressed

```bash
touch textfile.txt
mkdir folder1 && cd folder1 && touch file{1..4}.txt

tar -cf archive.tar textfile.txt folder1 # creates tar
tar -zcf archive.tar.gz textfile.txt folder1 # also zippes it

mkdir some-folder
tar -xzf archive.tar.gz -C some-folder # unzipps
```

### Wildcards & Replacements

**Replacements**
`touch file{1,2,3,4}.txt` - create file1.txt, file2.txt, etc. (bash does it itself, touch receives spreaded input)
`touch file{1..4}.txt` - the same thing
`echo {4..1}` - reverse
`touch file{a..z}.txt` - with letters
`echo {1..10..2}` - every second (1, 3, 5, 7, 9)
`touch file{1..4}.{html,css,js}` - create all combinations

**Wildcards**
`ls file*` - finds all which starts with `file`
`ls file?.txt` - `?` matches exactly one character

**Backslash** - creating files with unambigious character
`touch file\?.txt` - `\` escape character, tells that next character is literally character I want
`touch file\ .txt` - space
`touch file\\.txt`

## Streams & Pipes

### Streams

**Streams** refer to the standard I/O streams used for communication between processes and the system. These are:

- **Standard Input (stdin)** - file descriptor **0**
    - `cat < input.txt` - redirects stdin from input.txt
    - `echo Hello | cat` - pipes the output of echo to cat's stdin
- **Standard Output (stdout)** - file descriptor **1**
    - `ls > output.txt` - redirects stdout to output.txt
    - `ls | grep "file"` - pipes the output of ls to grep's stdin
- **Standard Error (stderr)** - file descriptor **2**
    - `ls no_such_file 2> error.log` - redirects stderr to error.log

### Output

`echo text` - outputs to stdout stream (no any other program specifies, terminal screen by default)
`echo text 1> file.txt` - redirecting output (stdout) to the file
`ls -lash 1>> ls.txt` - program detects redirection and can change output format for computers (no color, new line)
`ls -lash 1> ls.txt 2> ls_error.txt` - both
`ls -lash 2> /dev/null` - when you don't care about errors

`1>` - redirects stdout (replaces file)
`2>` - redirects stderr (replaces file)
`>` - redirects both (replaces file)

`1>>` - redirects stdout (appends to the file)
`2>>` - redirects stderr (appends to the file)
`>>` - redirects both (appends to the file)

### Input

`cat < input.txt` - input.txt is sent as input (stdin) to cat
`grep root < ls.txt`
`grep root > ls.txt 1> grep.txt 2> /dev/null` - pass ls.txt as input (stdin) to grep, put result in grep.txt and ignore errors

### Pipes

`cat ls.txt | grep "root"` - pipes output of cat to grep stdin
`yes n | rm -i file*` - answers `n` to all 'do you want to remove file_x ?'

## Users, Groups, Permissions

### Users

`whoami` - shows current user
`cat /etc/passwd` - shows all users in system
    username:password_placeholder:UID:GID:comment/home_info:home_directory:login_shell

- Each user should have least amount of power enough to do required job
- Only root user can create files in / (root) directory (`ls -lash` see owner is root/root)
- Don't be a root user, you can shoot yourself

`sudo` - superuser do - executes command as root user (switches to root and then back)
`sudo whoami` - root (whoami - ubuntu)
`sudo su` - su (switch user) to root (superuser)

`sudo useradd sherzod` - create new user (default shel is `sh`)
`sudo passwd sherzod` - set password for user
`su sherzod` - switch user

### Groups

- You have 50 users, 25 admins and 25 users, and need to add folder access to admins. Better adding to a group

`sudo usermod -aG sudo sherzod` - modify user --apend --groups 'sudo' to 'sherzod' user

### Permissions

`drwxr-xr-x`
    - first letter shows type (`d` - directory, `-` - file, `l` - symlink, etc), then 3x `rwx`
    - 3 times `rwx` (for user, group, the rest) - user/group whown in ls -lash
    - `r` - read, `w` - write, `x` - execute
    - if `.` directory doesn't have `w`, you can't write files

`sudo chown ubuntu:ubuntu /hello` - change ownership of given directory to a user:group
`sudo chmod u=rwx,g=rwx,o=rwx file.txt` - change mode (user, group, other)

**Shorcuts**

4 - read
2 - write
1 - execute

`sudo chmod 777 file.txt` - shortcut for rwx to all
each number represents each (user-group-other)

`667` - u=rw,g=rw,o=rwx
`700` - u=rwx,g=,o= (only user can read-write-execute, others don't)

`chmod +x file.txt` - adds `x` permission to all
`chmod -x file.txt` - removes `x` permission from all
`chmod u+x file.txt` - add `x` permision to user

## Environments, Processes

### Environments

`printenv` - prints all env variables
`echo hello $USER` - bash replaces $USER with the actual value, not echo
`VAR=1` or `export VAR=1` - export if you want to share var between child processes

`sudo vim /etc/environment` - if you want to add env variables (for all users)
`vim ~/.bashrc` - or add here for current user only
`source ~/.bashrc` - reruns it (runs at the beginning of the session)

### Processes

`sleep 1000 &` - `&` tells to run process in background (but not output)
`sleep 1000 > output.txt &` - now it fully runs in bg and doesn't polute the shell
`ps` - process status

**Job in background**

It's useful if you run some machine_learning script or run npm install
Just hit Ctrl-Z and `bg $NUMBER` or add `&` after script

`sleep 1000` - run it, it'll block the shell
`Ctrl+Z` - stop the process (puts back to shell)
`jobs` - shows all running/stopped jobs
`bg 1` - resumes process in the background (with number 1 - "[1]+ Stopped")
`fg 1` - resumes process in the foreground (block shell)

### Exit codes

`date` - shows current date
`echo $?` - prints last command's exit code (succes/failure/etc)

`0` - means it was successful. Anything other than 0 means it failed
`1` - a good general catch-all “there was an error”
`2` - a bash internal error, meaning you or the program tried to use bash in an incorrect way
`126` - Either you don’t have permission or the file isn’t executable
`127` - Command not found
`128` - The exit command itself had a problem, usually that you provided a non-integer exit code to it
`130` - You ended the program with CTRL+C
`137` - You ended the program with SIGKILL
`255` - Out-of-bounds, you tried to exit with a code larger than 255

**Operators**

`uptime` - how long computer is up
`false` - always return 1 (error)
`true` - always return 0 (success)

`touch status.txt && date >> status.txt && uptime >> status.txt` - AND - run next command only if previous was successful
`false || echo hi` - OR - runs next command (e.g. clean up) only if previous was not successful
`true ; false ; echo hi` - run not matter what

**Subcommands**

`echo I think $(whoami) is good` - separate command is run and whatever return value is passed
`echo $(date +%x) - $(uptime) >> log.txt` - if you want hourly get logs, can put it in cron

```bash
echo Hi `whoami` # older version
```

use `$()` because it's newer, more functions and you can nest them

## Networking (ssh, sftp)

### ssh

- SSH (secure shell) - allows to connect from on PC to another
- Git under the hood uses SSH
- Public key is like a lock, and private key is key. Everyone can see lock

```bash
multipass launch --name bar # launch another VM
multipass shell bar

# create sherzod:ubuntu user with home folder and custom shell
sudo useradd -s /bin/bash -m -g ubuntu sherzod
sudo passwd sherzod # change pass

# then connect to primary PC
ssh-keygen -t rsa # better put passphrase, don't reveal private id_rsa
mkdir ~/.ssh # on 2nd VM under Sherzod
echo "ssh-rsa id_rsa public key goes here" >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

ifconfig # view ip address to then connect via ssh
ssh sherzod@ip_here # from 1st PC
```

- netmask 255.255.255.0 means that only last value can change
- lo - 127.0.0.1 - local loopback
- for ssh to work, there needs to be a ssh agent to accept connection.
    Ubuntu runs it by default. Somewhere needs to setup ssh agent

### sftp

- SFTP - safe ftp (file transfer protocol)
- If ssh is set up, you can use sftp (can disable such behaviour)
- `sftp user@ip` - connect to sftp (same as ssh, just sftp word)
    - when connected, it's like bash, but with limitted commands (like ls, cp, mv, pwd)
    - `pwd` - remote pwd, `lpwd` - local pwd
    - `lls` - local list
- `put status.txt` - copies local file in current remote desktop folder
- `!echo "hi there" > file-to-put.txt` - `!` executes file in local PC
- `cat file-to-put.txt`
- `put file-to.put.txt new-file.txt` - rename file
- `get status.txt received-file.txt` - download file from remote
- `help` - shows all commands
- `bye|quit|exit` - bye:)

## Internet (wget, curl)

### wget

- Wget is designed to download files & mirroring websites
- It's like network version of `cp`
- Strengths:
    - recursive downloads
    - resuming interrupted downloads
    - simple usage
    - background operation (can download in background, great for cron jobs)

`wget https://raw.githubusercontent.com/btholt/bash2048/master/bash2048.sh` - install file
`bash bash2048.sh` or `chmod +x|u+x|700 bash2048.sh`

### curl

- Curl can pipe output, create files, customize headers, cookies, etc., different protocols
    HTTP, HTTPS, FTP, FTPS, SCP, SFTP, IMAP, POP3, SMTP and more

`curl https://raw.githubusercontent.com/btholt/bash2048/master/bash2048.sh > file.sh`
    if just curl, it'll do get request and print to stdout the content

`python3 -m http.server 8000` - start python module server for testing

`curl http://192.168.64.3:8000` - GET request
`curl http://192.168.64.3:8000 > res.txt` - pipe result into file
`curl -o res2.txt http://192.168.64.3:8000` - same as pipinp
`curl -O http://192.168.64.3:8000/output.txt` - will download file output.txt and keep this name

`curl -X POST http://127.0.0.1` - changes http verb
`curl -d "post body" http://127.0.0.1` - specify post body (sets http verb to POST if not set)
`curl -b "name=sherzod" -X PATCH http://127.0.0.1` - specify cookie `b`

**HINT**: One use case is that you can copy all your browser cookies and save to file.
Then do curl and specify cookie-jar (cookie-file) with `-c` flag

`curl https://bit.ly/linux-cli` - websites has redirects but it doesn't work here
`curl -L https://bit.ly/linux-cli` - follows redirects
`curl -H "Accept-Language: en-US" http://127.0.0.1` - specify headers (can set multiple)

**HINT**: Open Network tab, select any request, right click and **Copy as CURL**

`curl -o- github.com/nvm/install.sh | bash` - be cautious, you need to trust, because
    when piping into bash, it can dump all your env variables. First create file with >
    to create file, verify the content is the same, then run. Program can even detect
    that it's piped into bash, and change the content

## Package management (apt, snaps)

Unix philosophy - one package should do one thing well

### Apt

[Apt packages](https://apt-browse.org) - no official page for that, but it let's you search for packages

- apt - advanced package tool (on ubuntu), easier and simpler than apt-get (use it)
- apt-get - older apt, stays historically
- dpkg - apt from debian, stays in ubuntu because it derived from it
- apt is several tools combined together, user-friendly (it uses apt-get under the hood)
- apt is very conservative at updating the package, so download popular tools from their source

`apt help` - see all available commands

`sudo apt install aptitude -y && aptitude` - nice UI to see all installed packaged
    and which need an update (created by Canonical)

`sudo apt install lolcat -y`
`apt search nodejs` - searches the registry
`apt show nodejs` - shows all info about nodejs
`apt autoremove` - clean up stuff you don't need (nothing refers to it)

`apt update` - fetches latest info about packages stored in sources.list
`apt upgrade` - upgrades all installed packages to the latest version got from update
    (can specify which app to upgrade)
`apt list` - list all installed packages
`apt list --upgradable` - list all packages which can be upgraded
`apt full-upgrade` - upgrades packages with ability to install/delete new deps in packages
`apt remove nodejs` - remove package

`homebrew` for Mac, `winget` for Windows or `chocolatey`

### Snaps

- Snap is solution to install untrusted code (sort of isolation/sandbox)
- Apt less secure, and therefore they publish only trusted devs (snaps has recent versions)
- Snap can install on different distros, because of "sandboxing" (apt just installs ubuntu code)
- Snap installs everything it needs to run (isolated and can't still your data)
- Apt installs and deletes entire package (even if 1GB). Snap can ship delta updates (changes)
- Snap autoupdates the package (you don't know when and can't disable it) - good for browsers, etc.
- Snap supported by Canonical

`snap install lolcat|chrome|vscode`
`snap info node` - shows all versions
`snap install --channel=14/stable --classic node`
    `--channel` - define channel, don't update to 16 (within 14 version)
    `--classic` - breaking out of snaps (not really a sanbox), need to trust it

- Uses snapd (snap daemon) - which runs on background and checks and installs updates
- Everything ending on `d` means **daemon** (containerd, initd, systemd)

## Shell scripts

### Writing scripts

```bash
mkdir -p ~/temp # -p tells if already exists, don‘t error
cd ~/temp
touch file{1..10}.txt
echo done
```

```bash
vim gen_files.sh

source gen_files.sh # redirects to ~/temp, because runs in the same process
. gen_file.sh # same as source, but works in more distros, source more like ubuntu
bash gen_file.sh # doesn't redirect, because runs in subprocess
chmod +x gen_files.sh && ./gen_files.sh # also doesn't redirect
```

**Hashbang**/**Shebang**

`#!` - hash and bang
`#!/bin/bash` - shebang and then path to executable which runs this file (can be with space)
    - bash reads it and understands with which program to run this file
    - can save file without extension
    - can do `which node` and then put it after shebang

### Path & Variables

- `echo $PATH` - PATH where all your programs are (finds from left to right)
- how to add smth into path
    - `mkdir ~/my_bin && mv gen_files ~/my_bin`
    - `vim .bashrc`
    - `export PATH=~/my_bin:$PATH` - or put PATH before, depends on what you want

**Variables**

```bash
DESTINATION=~/temp # can put quotes, it's optional
FILE_PREFIX=file # screaming case isn't mandatory, can use file_prefix or any other

mkdir -p $DESTINATION
cd $DESTINATION # can write ${DESTINATION}

touch ${FILE_PREFIX}{1..10}.txt # need to put var within {}, otherwise it can mean array accessing
```

**Arguments**

- `$0` - it's file itself (like running `./gen_files`, $0 will be gen_files)
- `$1` - first argument

`DESTINATION=$1`
`./gen_files new-folder`

`read -p "Enter a file prexif: " FILE_PREFIX` - ask user iput

### Conditionals

```bash
# -z means that if flag is empty string
# brackets rearrange statement into `test` statement (man test)
# test -z "hello" && echo $? OR test -z "" || echo false
if [ -z $DESTINATION ]; then
    echo "no path provided, defaulting to ~/temp"
    DESTINAION=~/temp
fi

test 15 -eq 15 && echo is true
test sherzod = sherzod && echo is true
test 15 -gt 10 && echo is true
test -e file_exists # -w - exists and has write permission; -r - exsists & read permission
```

```bash
if [ $1 -gt 10 ]; then
    echo "Greater than 10"
elif [ $1 -lt 10 ]; then
    echo "Less than 10"
else
    echo "Equals 10"
fi
```

```bash
case $1 in
    "smile")
        echo ":)"
        ;;
    "sad")
        echo ":("
        ;;
    *)
        echo ":?"
        ;;
esac
```

### Loops and Arrays

- In bash there's `for`, `while`, `until`, `select` loops

```bash
friends=(Kyle Marc Jem "Brian Hault") # creates an array

echo My friend is ${friends[1]}

for friend in ${friends[*]}
do
    echo friend: $friend
done

echo I have ${#friends[*]} friends # length of array
```

```bash
# double (()) converts it to `let`, which allows to do basic arithmatic
NUM_TO_GUESS=$(($RANDOM % 10 + 1)) # random num between 1 and 10
GUESSED_NUM=0

echo "Guess a number between 1 and 10"

while [ $GUESSED_NUM -ne $NUM_TO_GUESS ]
do
    read -p "Your guess: " GUESSED_NUM
done
```

## Shell last

### cron

- if you put any file inside, it'll run on schedule
    - etc/cron.daily, etc/cron.hourly, etc/cron.weekly, etc/cron.monthly

`crontab -e` - edit your crontab, add task
    be default runs as current user, but can specify user `crontab -u ubuntu -e`

`* * * * *` - minute hour day_of_month month day_of_week
`5 * * * *` - at minute 5
`*/5 * * * *` - at every 5th minute
`5-10 * * * *` - at every minute from 5 through 10
`1-10/5 * * * *` - at every 5th minute from 1 through 10
`@daily` - at 00:00
`@reboot` - after rebooting

[Crontab guru](https://crontab.guru)

### customize your shell

`echo $PS1` - shows shell line prefix (can edit it)
`PS1="hello there "`

`curl https://raw.githubusercontent.com/riobard/bash-powerline/master/bash-powerline.sh > ~/.bash-powerline.sh`
`source ~/.bash-powerline.sh` - put it in .bashrc

spaceship for zsh (too much info)

**Colors**
`echo -e "this is \e[32mgreen"` - \e[32m make text green

npm has package `chalk` for easier working with colors

[Awesome bash](https://github.com/awesome-lists/awesome-bash)
Awesome things you can do with bash
