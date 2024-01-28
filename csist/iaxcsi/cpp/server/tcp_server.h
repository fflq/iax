#pragma once
#ifndef _TCP_SERVER_H_
#define _TCP_SERVER_H_

#include <unistd.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <signal.h>

#include <iostream>
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
    std::vector<int> clientfds, clientfds_adds ;
    std::thread wait_conn_thread ;

public:
    tcp_server(int listen_port);
    void broadcast(uint8_t *buf, size_t size) ;
    void broadcast(std::vector<std::pair<int, uint8_t*>> msgs);

private:
    void wait_conn();

    static bool sig_pipe_err;
    static void sig_pipe(int signo)
    {
        tcp_server::sig_pipe_err = true;
    }
    static bool consume_sig_pipe_err() 
    {
        return sig_pipe_err ? (sig_pipe_err = false, true) : false;
    }
};

bool tcp_server::sig_pipe_err = false;

tcp_server::tcp_server(int listen_port)
{
    //signal(SIGPIPE, SIG_IGN);
    signal(SIGPIPE, tcp_server::sig_pipe);

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
            printf("Received a connection from %s, sfd %d\n", 
                (char *)inet_ntoa(remote_addr.sin_addr), cfd);
            this->clientfds_adds.push_back(cfd) ;
        }
    }) ;
    //t.join() ;
}

void tcp_server::broadcast(uint8_t *buf, size_t size) 
{
    for (auto it = clientfds.begin(); it != clientfds.end();){
        auto &sfd = *it ;
        if (sfd < 0) continue ;
        try {
            if ((send(sfd, buf, size, 0) < 0) || tcp_server::consume_sig_pipe_err()) {
                std::cerr << "* send msg err, sfd " << sfd << std::endl;
                close(sfd) ;
                sfd = -1;
                it = clientfds.erase(it) ;
                //getchar();
            }      
            else ++ it ;
        }
        catch(const std::exception& e) {
            std::cerr << e.what() << '\n';
        }
    }

    if (!clientfds_adds.empty()) {
        clientfds.insert(clientfds.end(), clientfds_adds.begin(), clientfds_adds.end());
        clientfds_adds.clear(); 
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
