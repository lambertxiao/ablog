---
author: "Lambert Xiao"
title: "如何使用liburing读写磁盘"
date: "2023-03-26"
summary: ""
tags: ["storage"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

## 什么是liburing

liburing是一个用于异步IO库，它提供了简洁易用的API来处理文件I/O、网络I/O以及事件驱动I/O等各种I/O操作。liburing库基于Linux内核中的io_uring特性实现，将I/O请求从应用层转移到内核层以提高应用程序的I/O性能。

> 由于liburing在内核版本5.1才引入，所以需要运行环境的linux内核版本大于等于5.1

## 为什么使用liburing

liburing库对于一些高并发、高吞吐量的程序，特别是网络服务器、云存储等高性能系统的设计和实现有很大的帮助作用。

## 如何使用

建议参考源码里的步骤自行编译安装，源码：https://github.com/axboe/liburing

常用函数介绍：

- io_uring_queue_init：用于初始化io_uring并且返回其句柄。
- io_uring_queue_exit：用于关闭并释放io_uring的句柄。
- io_uring_get_sqe：用于获取一个可用的sqe，即I/O请求对应的队列元素数据结构。
- io_uring_prep_readv：用于准备一个异步读请求。
- io_uring_prep_writev：用于准备一个异步写请求。
- io_uring_sqe_set_data：用于将用户私有数据关联到一个sqe（请求）中。
- io_uring_submit：用于提交一个或一批异步IO请求到io_uring。
- io_uring_peek_cqe：用于查看完成队列（cq）中的未处理项数量。
- io_uring_wait_cqe：阻塞等待一个处理完成的io。
- io_uring_cqe_get_data：用于获取特定的完成队列项（cqe），其中包含先前提交的IO请求的结果以及相关的私有数据。
- io_uring_cqe_seen：用于标记一个完成队列项（cqe）已被处理过。

下面使用liburing封装一个DiskUtil实现对文件的基本读写

编写disk_util.h头文件

```c++
#include <functional>
#include <string>
#include <liburing.h>
#include <thread>

enum IO_OP { OP_READ = 0, OP_WRITE = 1 };

struct IORequest {
  IO_OP opcode; // 0: read, 1: write
  char* buffer;
  off_t offset;
  size_t length;
  std::function<void(int)> callback;
};

class DiskUtil {
public:
  DiskUtil(const std::string& file_path, int block_size);
  ~DiskUtil();
  void submit_request(IORequest* req);
  void start();
  void stop();
private:
  void io_worker_thread();
  int open_file();
  void close_file();
  void process_io_request(IORequest* req);
  int submit_io_request(IORequest* req);
  void complete_io_request();
private:
  int fd_ = -1;
  io_uring io_ring_;
  const std::string file_path_;
  const int block_size_;
  std::thread io_worker_;
  bool is_running_ = false;
};
```

编写disk_tool.cpp

```c++
#include <vector>
#include <string>
#include <fcntl.h>
#include <unistd.h>
#include <cstring>
#include <stdexcept>
#include <iostream>
#include <liburing.h>
#include "disk_util.h"

DiskUtil::DiskUtil(const std::string& file_path, int block_size)
 : file_path_(file_path), block_size_(block_size) {
  fd_ = open_file();
  if (fd_ < 0) {
    throw std::runtime_error("Failed to open file");
  }

  int ret = io_uring_queue_init(128, &io_ring_, 0);
  if (ret < 0) {
    close(fd_);
    throw std::runtime_error("Failed to setup io ring, ret:" + std::to_string(ret));
  }

  is_running_ = true;
  io_worker_ = std::thread(std::bind(&DiskUtil::io_worker_thread, this));
}

DiskUtil::~DiskUtil() {
  stop();
  io_uring_queue_exit(&io_ring_);
  close_file();
}

void DiskUtil::submit_request(IORequest* req) {
  submit_io_request(req);
}

void DiskUtil::start() {
  is_running_ = true;
}

void DiskUtil::stop() {
  if (is_running_) {
    is_running_ = false;
    if (io_worker_.joinable()) {
        io_worker_.join();
    }
  }
}

int DiskUtil::open_file() {
  int flags = O_RDWR | O_DIRECT | O_CREAT;
  int mode = S_IRUSR | S_IWUSR;
  return open(file_path_.c_str(), flags);
}

void DiskUtil::close_file() {
  if (fd_ >= 0) {
    close(fd_);
  }
}

int DiskUtil::submit_io_request(IORequest* req) {
  struct io_uring_sqe* sqe = io_uring_get_sqe(&io_ring_);
  if (!sqe) {
      return -1;
  }

  struct iovec iov;
  iov.iov_base = req->buffer;
  iov.iov_len = req->length;

  if (req->opcode == OP_READ) {
    io_uring_prep_readv(sqe, fd_, &iov, 1, req->offset);
  } else if (req->opcode == OP_WRITE) {
    io_uring_prep_writev(sqe, fd_, &iov, 1, req->offset);
  }
  io_uring_sqe_set_data(sqe, (void*)req);
  io_uring_submit(&io_ring_);
  return 0;
}

void DiskUtil::io_worker_thread() {
  while (is_running_) {
    struct io_uring_cqe* cqe = nullptr;
    int ret = io_uring_wait_cqe(&io_ring_, &cqe);
    if (ret < 0) {
      std::cout << "io_uring_wait_cqe error:" << ret << std::endl;
      return;
    }
    std::cout << "ret:" << ret << std::endl;
    if (cqe->res < 0) {
      std::cerr << "IO error: " << std::strerror(-cqe->res) << " ret_code:" << cqe->res << std::endl;
      std::this_thread::sleep_for(std::chrono::milliseconds(500));
      cqe = nullptr;
      continue;
    } else {
      IORequest* req = (IORequest*)io_uring_cqe_get_data(cqe);
      if (req->callback) {
        req->callback(0);
      }
    }
    io_uring_cqe_seen(&io_ring_, cqe);
  }
 }
```

下面是调用的例子

```c++
#include <cstring>
#include <cstdlib>
#include <iostream>
#include "disk_util.h"

#define BLOCK_SIZE 4096

void test_read(DiskUtil& disk, off_t offset, size_t length) {
  char* buffer = nullptr;
  int ret = posix_memalign((void**)&buffer, 4096, length);
  if (ret < 0) {
    std::cout << "malloc buffer error";
    return;
  }

  IORequest* req = new IORequest;
  req->opcode = OP_READ;
  req->buffer = buffer;
  req->offset = offset;
  req->length = length;
  req->callback = [req](int ret) {
    if (ret == 0) {
      std::cout << "Read complete, data:" << req->buffer << std::endl;
    } else {
      std::cout << "Read failed: " << ret << std::endl;
    }

    free(req->buffer);
    delete req;
  };
  disk.submit_request(req);
}

void test_write(DiskUtil& disk, off_t offset, size_t length, const char* data) {
  char* buffer = nullptr;
  int ret = posix_memalign((void**)&buffer, 4096, length);
  if (ret < 0) {
    std::cout << "malloc buffer error";
    return;
  }

  std::memcpy(buffer, data, length);
  IORequest* req = new IORequest();
  req->opcode = OP_WRITE;
  req->buffer = buffer;
  req->offset = offset;
  req->length = length;
  req->callback = [req](int ret) {
    if (ret == 0) {
      std::cout << "Write complete" << std::endl;
    } else {
      std::cout << "Write failed: " << ret << std::endl;
    }
    free(req->buffer);
    delete req;
  };
  disk.submit_request(req);
}

int main() {
  DiskUtil disk("test.disk", BLOCK_SIZE);
  disk.start();
  size_t length = 4096;
  const char* data = "Hello world";
  test_write(disk, 0, length, data);
  std::this_thread::sleep_for(std::chrono::seconds(1));
  test_read(disk, 0, length);
  // std::system("rm test.disk");
  disk.stop();
  return 0;
}
```

注意点：

1. 与libaio不同的是，liburing并不强制上层传递的buffer是4K对齐的，但是为了获取最佳性能，建议还是使用4K对齐的buffer。
2. 实测在内核5.4版本上使用io_uring_prep_read和io_uring_prep_write方法会在调用io_uring_wait_cqe判断cqe->res的大小时报invalid argument，原因未知

完整代码参见github链接：https://github.com/lambertxiao/storage/tree/master/liburing

## 为什么liburing性能高

1. 零拷贝：在传统的系统调用中，数据需要在用户空间和内核空间进行多次内存拷贝，而io_uring可以通过内存映射来实现零拷贝，将数据从内核的缓存区直接传输到用户空间，从而减少了内存拷贝带来的性能开销。
2. 批处理I/O操作：io_uring使用批处理机制来减少系统调用的次数，可以将多个I/O操作打包成一个请求提交给内核进行处理，从而提高了系统吞吐量。
3. 高效内存管理：io_uring在内核中使用了自身的内存池机制，能够更有效地管理内部的内存，避免了频繁的分配和释放内存所带来的性能损失。
4. 锁控制：io_uring使用了内核层面的锁机制，避免了多线程I/O操作时的竞争情况，提高了系统的并发能力。
5. io_uring的底层实现使用了ring buffer方式，可以根据需要进行高效的扩展，能够更好地应对高负载工作环境
