#pragma once
#ifndef _IAXCSI_TCP_CLIENT_H_
#define _IAXCSI_TCP_CLIENT_H_

#include <unistd.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <signal.h>

#include <iostream>
#include <sstream>
#include <cstring>
#include <vector>
#include <thread>
#include <chrono>
#include <atomic>
#include <mutex>
#include <condition_variable>

namespace iaxcsi {

class TcpClient {
public:
    TcpClient(const char *addr) {
        char *sep = strchr(const_cast<char*>(addr), ':');
        if (!sep) {
            throw std::runtime_error("Invalid addr");
        }
        memcpy(serverIp_, addr, sep-addr);
        serverPort_ = atoi(sep+1);
        init();
    }

    TcpClient(const char *serverIp, int serverPort) : serverPort_(serverPort) {
        strcpy(serverIp_, serverIp);
        init();
    }

    void init() {
        signal(SIGPIPE, TcpClient::handleSigPipe);
        connectServer();
    }

    ~TcpClient() {
        end_ = true;
        close(sfd_);
    }

    void connectServer() {
        memset(&serverAddr_, 0, sizeof(serverAddr_));
        serverAddr_.sin_family = AF_INET;
        serverAddr_.sin_port = htons(serverPort_);

        if (inet_pton(AF_INET, serverIp_, &serverAddr_.sin_addr) <= 0) {
            throw std::runtime_error("Invalid address");
        }

        reconnThread_ = std::thread([this]() {
            int sleep_second = 1;
            while (!end_) {
                {
                    std::unique_lock<std::mutex> lock(mutex_);
                    cv_.wait(lock, [&]{ return needReconn_; });
                }

                if ((sfd_ = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
                    throw std::runtime_error("Error creating socket");
                }

                int optval = 1;
                if (setsockopt(sfd_, SOL_SOCKET, SO_REUSEADDR, &optval, sizeof(optval)) == -1) {
                    throw std::runtime_error("Error setsockopt");
                }

                if (connect(sfd_, reinterpret_cast<struct sockaddr*>(&serverAddr_), 
                        sizeof(serverAddr_)) < 0) {
                    perror("* Connection faild");
                } else {
                    sleep_second = 1;
                    needReconn_ = false;
                    std::cout << "* Connected to server" << std::endl;
                }

                sleep_second = std::min(sleep_second*2, 10);
                std::this_thread::sleep_for(std::chrono::seconds(sleep_second));
            } 
        }) ;
        reconnThread_.detach();
    }

    void send(uint8_t *buf, size_t size) {
        if (needReconn_)    return;

        if (::send(sfd_, buf, size, 0) < 0) {
            std::cerr << "* send error: buf size " << size << std::endl ;
            std::lock_guard<std::mutex> lock(mutex_);
            needReconn_ = true;
            cv_.notify_one();
        }
        std::cout << "* send: buf size " << size << std::endl ;
    }

    void send(std::vector<std::pair<int, uint8_t*>> msgs)
    {
        static uint8_t buf[4096] ;
        uint32_t total_len, n32 = 0 ;
        int pos = 4 ;
        for (auto msg : msgs) {
            total_len += 4 + msg.first ;
            n32 = htonl(msg.first) ;
            memcpy(buf+pos, &n32, 4); pos += 4 ;
            memcpy(buf+pos, msg.second, msg.first); pos += msg.first ;
        }
        n32 = htonl(total_len) ;
        memcpy(buf, &n32, 4); 

        this->send(buf, pos) ;
    }

    static void handleSigPipe(int signo) {
        std::cout << "* handleSigPipe signo " << signo << std::endl;
    }

private:
    char serverIp_[16] ;
    int serverPort_ ;
    struct sockaddr_in serverAddr_ ;
    int sfd_ ;
    std::mutex mutex_ ;
    std::condition_variable cv_ ;
    bool needReconn_ = true ;
    bool end_ = false;
    std::thread reconnThread_;
};

}

#endif