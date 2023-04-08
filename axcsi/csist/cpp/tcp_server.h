#pragma once
#ifndef _TCP_SERVER_H_
#define _TCP_SERVER_H_

#include <unistd.h>
#include <iostream>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <cstring>
#include <vector>
#include <thread>

#define MAXSIZE 1024

class tcp_server
{
private:
    int socket_fd, accept_fd;
    sockaddr_in myserver;
    sockaddr_in remote_addr;
    std::vector<int> clientfds ;
    std::thread wait_conn_thread ;

public:
    tcp_server(int listen_port);
    void broadcast(uint8_t *buf, size_t size) ;
    void broadcast(std::vector<std::pair<int, uint8_t*>> msgs);

private:
    void wait_conn();
};


tcp_server::tcp_server(int listen_port)
{
    if ((socket_fd = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP)) < 0)
    {
        throw "socket() failed";
    }

	int optval = 1;
	if (setsockopt(socket_fd, SOL_SOCKET, SO_REUSEADDR, &optval, sizeof(optval)) == -1) {
		perror("setsockopt");
		exit(EXIT_FAILURE);
	}

    memset(&myserver, 0, sizeof(myserver));
    myserver.sin_family = AF_INET;
    myserver.sin_addr.s_addr = htonl(INADDR_ANY);
    myserver.sin_port = htons(listen_port);

    if (bind(socket_fd, (sockaddr *)&myserver, sizeof(myserver)) < 0)
    {
        throw "bind() failed";
    }

    if (listen(socket_fd, 10) < 0)
    {
        throw "listen() failed";
    }

    wait_conn() ;
}

void tcp_server::wait_conn()
{
    this->wait_conn_thread = std::thread([this]() {
        socklen_t sin_size = sizeof(struct sockaddr_in);
        sockaddr_in remote_addr;
        int cfd ;
        std::cout << "* wait conn" << std::endl ;
        while (1)
        {
            if ((cfd = accept(socket_fd, (struct sockaddr *)&remote_addr, &sin_size)) == -1)
            {
                throw "Accept error!";
                continue;
            }
            printf("Received a connection from %s\n", (char *)inet_ntoa(remote_addr.sin_addr));
            this->clientfds.push_back(cfd) ;
        }
    }) ;
    //t.join() ;
}

void tcp_server::broadcast(uint8_t *buf, size_t size) 
{
    if (this->clientfds.empty())    return ;
    for (auto &sfd : this->clientfds) {
        if (sfd < 0)    continue ;
        //printf("*send sfd%d sz%d\n", sfd, size) ;
        try {
            if (send(sfd, buf, size, 0) < 0) {
                //printf("*err send sfd%d sz%d\n", sfd, size) ;
                std::cerr << "Error sending message to server" << std::endl;
                close(sfd) ;
                sfd = -1 ;
            }      
        }
        catch(const std::exception& e) {
            std::cerr << e.what() << '\n';
        }
    }
}

void tcp_server::broadcast(std::vector<std::pair<int, uint8_t*>> msgs)
{
    uint32_t total_len, n32 = 0 ;
    static uint8_t buf[4096] ;
    int pos = 4 ;
    for (auto msg : msgs) {
        total_len += 4 + msg.first ;
        n32 = htonl(msg.first) ;
        memcpy(buf+pos, &n32, 4); pos += 4 ;
        memcpy(buf+pos, msg.second, msg.first); pos += msg.first ;
    }
    n32 = htonl(total_len) ;
    memcpy(buf, &n32, 4); 

    this->broadcast(buf, pos) ;
}

#endif
