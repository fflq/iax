all:
	gcc axcsi.c -std=c11 -o axcsi $(shell pkgconf --cflags --libs libnl-genl-3.0)
clean:
	rm -f *.o axcsi
