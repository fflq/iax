all:
	gcc test.c -o test $(shell pkgconf --cflags --libs libnl-genl-3.0)
clean:
	rm -f *.o test
