## Quickstart

If you haven't installed erln8 yet, please do so by visiting the [installation](installation.md) page.

Note: I'd like these quickstarts to be as quick as possible, but Erlang takes quite a bit of time to build. The erln8 experience is best enjoyed while brewing your favorite beverage.

### Erlang "Quickest" start
To build the latest tagged version of Erlang from the OTP Git repo:

```text
erln8 --build-latest
erln8 --list
# cd to a project directory
erln8 --use <some_version>
```

Replace `<some_version>` with the version that was built via `--build-latest`.


### Elixir "Quickest" start
To build the latest tagged version of Erlang from the OTP Git repo:

```text
erln8 --build-latest
extract --build-latest
# at the time of writing, v1.0.5 was the latest version of Elixir
extract --use v1.0.5
```


### Quickstart

```text
# pick a version from
erln8 --buildable
# and then build it
erln8 --build OTP_R16B03-1
# then cd to a project directory
erln8 --use OTP_R16B03-1
```




## Setting a version of Erlang, Rebar or Rebar3 in the current direcory

```text
erln8 --use OTP_R16B03-1
# or if you've already set a version of Erlang in the CWD:
erln8 --use OTP_R16B03-1 --force
```

```text
reo --use foo
# or if you've already set a version of Rebar in the CWD:
reo --use foo --force
```

```text
reo3 --use foo
# or if you've already set a version of Rebar3 in the CWD:
reo3 --use foo --force
```
---

© 2015 Dave Parfitt
