all:
	g++ -g iaxcsi.cpp -std=c++17 -o iaxcsi -lpthread \
		$(shell pkg-config --cflags --libs libnl-genl-3.0)
clean:
	rm -f *.o iaxcsi
