erln8, reo, and reo3 all share the same command line parameters.

## Environment

### Showing the current version in a given directory

```text
erln8 --show
```

This command searches up the directory tree from the current working directory to find an `erln8.config` file containing a version of Erlang/Rebar/Rebar3 to use. If the root directory is reached without finding an `erln8.config` file, the erln8/reo/reo3 `system_default` is used. If a `system_default` isn't specified, the command will fail.

### Listing installed versions

```text
erln8 --list
```

### Setting and getting the system default

If erln8 can't find an `erln8.config` file in the current and all parent directories (stopping at `/`), the system default will be used.

```text
erln8 --set-default OTP-18.0
```

```text
erln8 --get-default
```

## Building

### Listing buildable versions

This will list buildable tags across all configured repos. Note that you don't need to build from a tag, you can use a git SHA etc.

```text
erln8 --buildable
```

### Building the latest version

If you're confident that the local OTP/rebar/rebar3 repos are up-to-date, simply issue:

```text
erln8 --build-latest
```

It's always a good idea to run a fetch first though:

```text
erln8 --fetch default # fetches the default OTP repo
erln8 --build-latest
```

### Building multiple versions at once

You can build multiple versions with one command:

```text
erln8 --build OTP_R16B03-1 --build OTP-17.0 --build OTP-18.0
```

## Advanced Builds

Building from an alternate repo:

```text
erln8 --build origin/basho-otp-18 --repo basho --id basho18
```

Note: the `origin/` prefix may be required when working with repos other than `default`.


## Repos + Multiple Repositories

The default erln8 repo is the canonical OTP repository `https://github.com/erlang/otp.git`. You can, however, build from multiple repos.

### Display a list of configured repos

```text
erln8 --repos
default -> https://github.com/erlang/otp.git
basho -> https://github.com/basho/otp.git
```

### Adding and removing remotes

You can add additional repos to build Erlang from via `--remote add`:

```text
erln8 --remote add basho https://github.com/basho/otp.git
erln8 --clone basho
```

You must clone each repo after it's added.

### Cloning remotes

### Fetching from remotes

To pull down new git objects from the default OTP repository:

```text
erln8 --fetch default
# pull down objects from a repo named "basho"
erln8 --fetch basho
```

## Configs

You can specify an Erlang build config via the `--config` parameter, or via the `[Erln8]`/`default_config` value in `~/.erln8.d/config`.

### Environment variables

To provide environment variables to a build, create a custom config and an config environment. A config environment is the name of the config followed by `_env` in the `[Config]` section of `~/.erln8.d/config`.

For example, the config `osx_gcc` has a `osx_gcc_env` config environment that will be passed to the build when using `erln8 --build foo --config osx_gcc`:

```
osx_gcc=--disable-hipe --enable-smp-support --enable-threads --enable-kernel-poll --enable-darwin-64bit
osx_gcc_env=CC=gcc-4.2 CPPFLAGS='-DNDEBUG' MAKEFLAGS='-j 3'k
```

## erln8 config parameters

The erln8 configuration file `~/.erln8.d/config` contains several parameters that you can tweak.

### Erln8

The `[Erln8]` section allows you to specify the following parameters:

| Parameter | Description |
|-----------|-------------|
|`default_config` | The default configuration to use for all builds, unless overriden by `--config`. |
|`system_default` | The version to use as a system-wide default. See `--get-default` and `--set-default`. |
|`log_level` | valid values are `error` or `info`|
|`color` | **unimplemented in erln8 v2** |

### Repos

The `[Repos]` section allows you to manually configure OTP repos to build from.

| Parameter | Description |
|-----------|-------------|
| `default` | The canonical Erlang OTP repo: `https://github.com/erlang/otp.git`. This repo must exist for erln8 to work. |
| <repo_name\> | A custom repo with the name repo_name at url repo_url. \<repo_name\>=\<repo_url\> |


### Erlangs

The `[Erlangs]` section maintains a list of Erlang versions that have been built by erln8.


| Parameter | Description |
|-----------|-------------|
| `none` | No Erlang configured at this location. Probably not useful to you! |

### Configs

The `[Configs]` section maintains a list build configurations for Erlang.

| Parameter | Description |
|-----------|-------------|
| `default` | Empty build configuration. |
| <config_name\> | Custom build flags to pass to the Erlang build |
| <config_name\>\_env | Custom build environment variables to pass to the Erlang build |

## Regenerating erln8 links

If the links in `~/.erln8.d/bin` become invalid, or the binary moves, you can recreate them with:

```text
erln8 --setup-bins
```

---

© 2015 Dave Parfitt
