all: print_packets get_first_bfee parse_log incsi nl_bf_to_eff test

KERNEL = $(strip $(shell uname -r))
KERNEL_SOURCE = /lib/modules/$(KERNEL)/build

ifneq ($(wildcard $(KERNEL_SOURCE)/include/uapi),)
        KERNEL_HEADERS = $(KERNEL_SOURCE)/include/uapi
else ifneq ($(wildcard $(KERNEL_SOURCE)/include),)
        KERNEL_HEADERS = $(KERNEL_SOURCE)/include
else
        $(error Kernel headers not found)
endif

CFLAGS = -Wall -Werror
LDLIBS = -lm -lpthread
CC = gcc
CXX = g++ -std=c++14
CXXFLAGS = -Wall -Werror

nl_bf_to_eff: nl_bf_to_eff.c bf_to_eff.o iwl_nl.o util.o q_approx.o

incsi.cpp: iwl_connector.h tcp_client.h

iwl_nl.c: iwl_connector.h

iwl_connector.h: connector_users.h

connector_users.h: $(KERNEL_HEADERS)/linux/connector.h
	echo "#undef CN_NETLINK_USERS" > connector_users.h
	grep "#define CN_NETLINK_USERS" $(KERNEL_HEADERS)/linux/connector.h >> connector_users.h

clean:
	rm -f *.o get_first_bfee incsi print_packets parse_log nl_bf_to_eff connector_users.h
