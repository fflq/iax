CXX?=g++ 
CXXFLAGS=-std=c++14 -g -Wall -Wextra #-Werror -Wpedantic 

.PHONY: all clean
all:
	$(CXX) iaxcsi.cpp -o iaxcsi $(CXXFLAGS) -lpthread \
		$(shell pkg-config --cflags --libs libnl-genl-3.0)
clean:
	rm -f *.o iaxcsi
