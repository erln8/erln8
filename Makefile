BINNAME=erln8
all:
	rm -f ${BINNAME} erlc
	dmd -of${BINNAME} *.d
	ln -s ${BINNAME} erlc
clean:
	rm -f *.o
	rm -f ${BINNAME}
