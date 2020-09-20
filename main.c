#include <sys/socket.h> // struct sockaddr, socket, bind, listen, accept, AF_INET, INADDR_ANY, SOCK_STREAM
#include <netinet/in.h> // struct sockaddr_in
#include <unistd.h> // read, write, close
#include <stdio.h> // printf, sprintf
#include <arpa/inet.h> // htons, htonl
#include <string.h> // memset, strlen, memcpy
#include <errno.h> // errno
#include <stdlib.h> // getenv, atoi

#include <signal.h> // signal

static volatile int not_interrupted = 1;

void int_handler (int foo) {
    not_interrupted = 0;
}

#define PORT 80
#define BACKLOG 256
#define BUFF_LEN 8192


int main(int argc, char** argv) {


    const char* port_s = getenv("PORT");
    unsigned short port = (unsigned short) (port_s?atoi(port_s):0);
    if (!port) port = PORT;

    struct sockaddr_in srv_addr;
    memset((char *)&srv_addr, 0, sizeof(srv_addr)); 
    srv_addr.sin_family = AF_INET; 
    srv_addr.sin_addr.s_addr = htonl(INADDR_ANY); 
    srv_addr.sin_port = htons(port); 
    memset(srv_addr.sin_zero, '\0', sizeof srv_addr.sin_zero);


    struct sockaddr_in srv_addr6;
    memcpy(&srv_addr6, &srv_addr, sizeof(struct sockaddr_in));
    srv_addr6.sin_family = AF_INET6;

    // TODO error handling
    int socket_4 = socket(AF_INET, SOCK_STREAM, 0);
    if (socket_4 == -1) {
        printf("err on socket() 4\n");
    }
    
    // TODO multi thread for multi listen
    int socket_6 = socket(AF_INET6, SOCK_STREAM, 0);
    if (socket_6 == -1) {
        printf("err on socket() 6\n");
    }

    // TODO error handling for everything
    if(bind(socket_4, (struct sockaddr*) &srv_addr, sizeof(srv_addr)) < 0)
        printf("error on bind(): %d\n", errno);
    if(listen(socket_4, BACKLOG)<0)
        printf("error on listen()\n");

    printf("Listening on port %d\n", port);
    socklen_t addrlen;
    while (not_interrupted) {
        int new_sock = accept(socket_4, (struct sockaddr*) &srv_addr, (socklen_t*) &addrlen);
        printf("accept\n");

        char buffer[BUFF_LEN];

        long int num_read = read(new_sock, buffer, BUFF_LEN);

        printf("Read bytes: %ld\n\n%s\n", num_read, buffer);

        const char* body = "Feedback Recieved and discarded";

        char response[1024];
        sprintf(response, "HTTP/1.1 200 OK\nContent-Type: text/plain\nContent-Length: %ld\n\n%s", strlen(body), body);
        write(new_sock, response, strlen(response));
        close(new_sock);
    }

    close(socket_4);
    close(socket_6);
    printf("cleaned up\n");
}
