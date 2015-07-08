.PHONY: docs

all:
	dub build

install:
	mkdir -p ~/.erln8.d/bin
	cp erln8 ~/.erln8.d/bin/erln8
	cp erln8 ~/.erln8.d/bin/reo
	cp erln8 ~/.erln8.d/bin/reo3
	~/.erln8.d/bin/erln8 --clone default
	~/.erln8.d/bin/reo --clone default
	~/.erln8.d/bin/reo3 --clone default

on_a_plane:
	dub build --nodeps

clean:
	dub clean
	rm -f ./reo
	rm -f ./reo3
	rm -f ./erln8

docs:
	mkdocs gh-deploy --clean
