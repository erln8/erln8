<a href="https://github.com/erln8/erln8"><img style="position: absolute; top: 0; right: 0; border: 0;" src="https://camo.githubusercontent.com/365986a132ccd6a44c23a9169022c0b5c890c387/68747470733a2f2f73332e616d617a6f6e6177732e636f6d2f6769746875622f726962626f6e732f666f726b6d655f72696768745f7265645f6161303030302e706e67" alt="Fork me on GitHub" data-canonical-src="https://s3.amazonaws.com/github/ribbons/forkme_right_red_aa0000.png"></a>

![erln8 logo](img/erln8.png)



## What is erln8?

ernl8 v2 contains several tools that let a developer set custom versions of Erlang, Rebar, and Rebar3 per directory. This allows you to "set and forget" versions of your tools for a project once.

erln8 v2 ships with 3 binaries:

- `erln8` - Erlang version manager, completely rewritten from the ground up.
- `reo` - Rebar version manager, uses the same core code that erln8 uses.
- `reo3` - Same as reo, but for Rebar3.



## Getting started

See the [installation](installation.md) and [quickstart](quickstart.md) guide.


## Getting help

You can ask questions on the Freenode #erln8 IRC channel.

You can also ask questions on the [erln8](https://groups.google.com/forum/?hl=en#!forum/erln8) mailing list.


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
	- so are kitten elbows. I try to minimize the impact by providing [precompiled binaries](installation.md).
	
- What does reo mean?
	- Australian [slang](https://en.wikipedia.org/wiki/Rebar) for "rebar"

- Does erln8 support MS Windows?
	- I don't own Windows, but if you want to submit PR's to support it and build precompiled binaries, I'll all for it.


## Getting help

You can ask questions on the Freenode `#erln8` IRC channel.

You can also ask questions on the [erln8](https://groups.google.com/forum/?hl=en#!forum/erln8) mailing list.


---

© 2015 Dave Parfitt




