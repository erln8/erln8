# THIS IS A WORK IN PROGRESS

---


# erln8 v2

ernl8 v2 contains a suite of tools that let a developer set custom versions of Erlang, Rebar, and Rebar3 per directory. This allows you to "set and forget" versions of your tools for a project once.

erln8 v2 ships with 3 binaries:

- erln8 - Erlang version manager, completely rewritten from the ground up.
- reo - Rebar version manager, uses the same core code that erln8 uses.
- reo3 - Same as reo, but for Rebar3.


## Quickstart

### OSX
Build and install:

```
brew upgrade
brew install dmd dub
  # You MUST use DMD 2.076.1 or above
git clone https://github.com/erln8/reo.git
cd reo
make
make install

# erln8, reo, and reo3 are all installed in the local user home
# at ~/.erln8.d/bin
# YOU MUST ADD ~/.erln8.d/bin TO YOUR PATH!
```

Build the latest tagged version of Erlang from the OTP Git repo:

```
erln8 --build-latest
```

or pick a different version:

```
# pick a version from
erln8 --buildable
# and then build it
erln8 --build OTP_R16B03-1
```

## Setting a version of Erlang, Rebar or Rebar3 in the current direcory

```
erln8 --use OTP_R16B03-1
# or if you've already set a version of Erlang in the CWD:
erln8 --use OTP_R16B03-1 --force
```

```
reo --use foo
# or if you've already set a version of Rebar in the CWD:
reo --use foo --force
```

```
reo3 --use foo
# or if you've already set a version of Rebar3 in the CWD:
reo3 --use foo --force
```

## How it works

When an Erlang, Rebar, or Rebar3 command is issued in the shell, erln8/reo/reo3 fulfill the request by searching the current working directory for an `erln8.config` file. If the CWD doesn't contain this file, then continue up the directory tree searching for one, and then stop at `/`. If an `erln8.config` file can't be found, erln8/reo/reo3 will use a `system_default`. 

## Configuration

| Path  | Description  |
|---|---|
| `~/.erln8.d`  | Erln8/Reo/Reo3 config home  |
| `~/.erln8.d/bin`  |  Binary directory, contains erln8, reo, reo3 and symlinks to all Erlang, Rebar, Rebar3 executables |
| `~/.erln8.d/otps`  | erln8 managed versions of Erlang |
| `~/.erln8.d/repos`  | erln8 Git repos to build Erlang from source  |




## Building from source

## Using a precompiled binary

## FAQ

- What language is it written in?
	- D, it's super fast, easy, and it's not C++ or C.

- Why isn't it written in Erlang?	
	- chicken and egg, I never assumed you'd have Erlang built to be used by a tool that builds Erlang.

- No really, why not \<language X\>?
	- Erlang is slow for command line tools, I wanted a tool that could be used in a command line prompt.
	- I played around with implementing erln8 in the following, all of which weren't a great fit:
		- C++
		- Racket
		- Haskell
		- OCaml
		- Rust
		- Go

- But D is weird!
	- so are kitten elbows
	
- What does reo mean?
	- Australian slang for "rebar"

- Do you sing at parties?
	-  No, not really.

## Getting help

You can ask questions on the Freenode #erln8 IRC channel.

You can also ask questions on the [erln8](https://groups.google.com/forum/?hl=en#!forum/erln8) mailing list.


#Contributing

Fork this repo, create a feature branch using something like this:
    
```
git checkout -b branch_name
```

and submit a pull request. 

Please send me an email (dparfitt at getchef dot com) and let me know if you want to work on any features.

Only friendly pull requests accepted.

#License

http://www.apache.org/licenses/LICENSE-2.0.html

---

© 2015 Dave Parfitt