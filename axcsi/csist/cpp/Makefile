#gcc axcsi.c -std=c11 -o axcsi $(shell pkgconf --cflags --libs libnl-genl-3.0)
all:
	g++ axcsi.cpp -std=c++17 -o axcsi -lpthread \
		$(shell pkg-config --cflags --libs libnl-genl-3.0)
clean:
	rm -f *.o axcsi
