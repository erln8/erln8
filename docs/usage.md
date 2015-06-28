erln8, reo, and reo3 all share the same command line parameters.

## Showing the current version in a given directory

```text
erln8 --show
```

This command searches up the directory tree from the current working directory to find an `erln8.config` file containing a version of Erlang/Rebar/Rebar3 to use. If the root directory is reached without finding an `erln8.config` file, the erln8/reo/reo3 `system_default` is used. If a `system_default` isn't specified, the command will fail.

## Listing installed versions

```text
erln8 --list
```

## Listing buildable versions

This will list buildable tags across all configured repos. Note that you don't need to build from a tag, you can use a git SHA etc.

```text
erln8 --buildable
```

## Building
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

## Setting and getting the system default

```text
erln8 --set-default OTP-18.0
```

```text
erln8 --get-default
```


## Working with Git remotes

### Cloning remotes

### Fetching from remotes

## Configs

## Repos

---

© 2015 Dave Parfitt
