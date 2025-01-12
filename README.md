# Bash TUI (Text User Interface)

Bash TUI is a library designed to enhance your terminal experience with a user-friendly command-line helper for Git and SVN, as well as utilities to manage parameters and output with style.

## Installation

1. Install the package.
2. Copy the `.bash-tui-colors.conf` file from the project root to your home directory:
   ```
   ~/.bash-tui-colors.conf
   ```
3. Done!

## Features

### Command Line Helper

This library provides a command-line helper for Git and SVN, displaying detailed context in a user-friendly manner:

```
[branch -> remote]
[Your PID][CWD][last $?]
[user@host time]#
```

Example:

![Alt text](/elements/images/cmdline.png?raw=true "[Dina 5pt] 3-line commandline repository-aware")


- Multi-line display for improved readability on limited-width monitors.
- To disable the helper, edit `/etc/bash-tui.conf` and comment out or remove the `true` value:
  ```
  BASHTUI_cline_repo_ENABLED=true
  ```

### Core Libraries

#### **Say**
A wrapper for `echo` that supports color-coded output and logging.

**Usage:**
```bash
. /usr/lib/bash-tui/say.sh
say "hello" blue
```

- Prints `hello` in blue and logs it to `/var/log/say_output.log`:
  ```
  [2025-01-01 06:09:38] hello
  ```

- Configure logging:
  ```bash
  _L_file_=$(date +%Y%m%d)_filename.log # Log file
  _L_dir_=/var/log/dir                 # Log Directory
  ```

- Predefined keywords:
  ```bash
  say "hello" debug       # [DEBUG] message in blue
  say "hello" error       # [ERROR] message in red
  say "hello" warning     # [WARNING] message in yellow
  say "hello" exit        # Prints message and terminates session
  say "hello" logonly     # Logs only, without printing
  ```

#### **Bashparms**
A library to simplify parameter handling in Bash scripts.

**Usage:**
```bash
. /usr/lib/bash-tui/bashparms.sh

## Help
isParm help && _BP_getHelp && exit 113
```

what this does is automatically crawl your file for all instances in which you request or check a parameter and thanks to the comment after the keycomment `##BP:` takes the string after and adds it directly to the help.


Automatically generates a `--help` message based on parameters defined in the script. Example:
```bash
loglevel=$(getParm loglevel) || loglevel=quiet  ##BP: ffmpeg loglevel
```


Generates:
```
    --loglevel
        '--(ffmpeg loglevel)
```

A full example for --help is as shown:

![Alt text](/elements/images/gethelp.png?raw=true "[Dina 5pt] Get Help")


Available methods:
- `isNoParm`: Checks if no parameters are set.
- `setParm parameter 'value'`: Sets a parameter.
- `isParm parameter`: Checks if a parameter is set.
- `isNotParm parameter`: Checks if a parameter is not set.
- `getParm parameter`: Retrieves the value of a parameter.

**Command-line usage:**
```bash
./software.sh --parameter -blah -cu 12 --test 'yes'
```
Results:
```
parameter: 1
b: 1
l: 1
a: 1
h: 1
c: 12
u: 12
test: 'yes'
```

Parameter files can also be used with `--parametrizer /path/to/parameter/file`:
```
# Parametrizer file example
date yesterday
skip-sanitize
## Social
youtube
# thumbnail
thumbType freeform
thumb_ff_title 4K TRAILER
thumb_ff_rs1 LIVE 24/7
```
Comments will have to start at the beginning of the line and longer string don't need to be quoted, the bashparms will simply get the first word as the parameter and the rest as its value

### Colors

Run `colorshow` to list available colors. Example output:

![Alt text](/elements/images/colorshow_1.png?raw=true "[Dina 5pt] Colorshow")

Customize colors with `colorset`:
```bash
colorset 148 banana
say "how are you?" banana
```

![Alt text](/elements/images/colorshow_2.png?raw=true "[Dina 5pt] Colorshow banana")


## Contributions

Contributions are welcome! Feel free to submit issues or pull requests.

## License

This project is licensed under the GNU General Public License v2.0. You can redistribute it and/or modify it under the terms of the license. See the [LICENSE](LICENSE) file for the full text of the license.

### Disclaimer

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


---

Enjoy a better terminal experience with Bash TUI!
