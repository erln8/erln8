all:
	dub build

on_a_plane:
	dub build --nodeps

clean:
	dub clean
	rm -f ./reo
	rm -f ./reo3
	rm -f ./erln8
