---
author: "Lambert Xiao"
title: "如何使用libaio读写磁盘"
date: "2023-03-25"
summary: ""
tags: ["storage"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

## 什么是libaio

libaio是Linux异步I/O文件操作库，它能够提供更高效的文件异步I/O读写方式。

## 为什么使用libaio

异步I/O操作是指将数据传输请求发送给操作系统后，操作系统会立即返回并继续执行其他任务，而不必等待数据传输完成，这种操作方式可以充分利用CPU和I/O设备的资源，提高系统的I/O性能。

相比于传统的同步I/O操作方式，异步I/O操作需要通过系统调用和事件通知机制实现，在编程实现上具有较高的难度。而libaio封装了这些细节，使得开发人员可以更方便地使用异步I/O操作，从而提高应用程序的I/O性能。因此，如果需要高效的文件I/O操作，并期望充分利用系统资源，可以考虑使用libaio。

## 如何使用

安装libaio

```
apt install libaio-dev
```

接口介绍

- io_setup：用于初始化异步IO环境并返回其句柄。
- io_destroy：用于清除异步IO环境并关闭相应的文件描述符。
- io_getevents：用于等待指定数量的IO事件（如读、写或错误）并将它们存储在指定的缓冲区中。
- io_prep_pread：用于为读取一个文件块准备异步IO操作。
- io_prep_pwrite：用于为写入一个文件块准备异步IO操作。
- io_submit：用于提交一或多个异步IO请求，并将其排入异步IO环境中，等待事件处理。

下面使用libaio封装一个DiskUtil实现对文件的基本读写

编写disk_util.h头文件

```c++
#include <functional>
#include <string>
#include <libaio.h>
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
  void complete_io_request(io_context_t ctx, io_event* events, int num_events);
private:
  int fd_ = -1;
  const std::string file_path_;
  const int block_size_;
  // 对应一个会话的上下文
  io_context_t io_ctx_ = 0;
  std::thread io_worker_;
  bool is_running_ = false;
};
```

编写disk_tool.cpp

```c++
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <libaio.h>
#include <iostream>
#include <thread>
#include "disk_util.h"

DiskUtil::DiskUtil(const std::string& file_path, int block_size)
  : file_path_(file_path), block_size_(block_size) {
  fd_ = open_file();
  if (fd_ < 0) {
      throw std::runtime_error("Failed to open file");
  }
  io_ctx_ = 0;
  int rc = io_setup(128, &io_ctx_);
  if (rc < 0) {
      close_file();
      throw std::runtime_error("Failed to setup io context");
  }
  is_running_ = true;
  io_worker_ = std::thread(std::bind(&DiskUtil::io_worker_thread, this));
}

DiskUtil::~DiskUtil() {
  stop();
  close_file();
  io_destroy(io_ctx_);
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
    if (io_ctx_) {
      io_destroy(io_ctx_);
      io_ctx_ = 0;
    }
    if (io_worker_.joinable()) {
      io_worker_.join();
    }
  }
}

void DiskUtil::io_worker_thread() {
  const int MAX_EVENTS = 128;
  struct io_event events[MAX_EVENTS];
  while (is_running_) {
    int num_events = 0;
    while (num_events <= 0) {
      num_events = io_getevents(io_ctx_, 1, MAX_EVENTS, events, NULL);
      if (num_events < 0) {
        std::cerr << "io_getevents returned error: " << num_events << std::endl;
        break;
      }
    }
    if (num_events > 0) {
      complete_io_request(io_ctx_, events, num_events);
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(10));
  }
}

int DiskUtil::open_file() {
  int flags = O_RDWR | O_DIRECT | O_SYNC | O_CREAT;
  int mode = S_IRUSR | S_IWUSR;
  return open(file_path_.c_str(), flags, mode);
}

void DiskUtil::close_file() {
  if (fd_ >= 0) {
    close(fd_);
    fd_ = -1;
  }
}

void DiskUtil::process_io_request(IORequest* req) {
  std::cout << "process op:" << req->opcode << std::endl;
  if (req->callback) {
    req->callback(0);
  }
}

int DiskUtil::submit_io_request(IORequest* req) {
  struct iocb* cb = new iocb;

  if (req->opcode == OP_WRITE) {
    io_prep_pwrite(cb, fd_, req->buffer, req->length, req->offset);
  } else {
    io_prep_pread(cb, fd_, req->buffer, req->length, req->offset);
  }

  // 将当前的请求的指针绑定到callback上
  cb->data = (void*)req;
  int num_events = 1;
  int rc = io_submit(io_ctx_, num_events, &cb);
  if (rc != num_events) {
    return -1;
  }
  return 0;
}

void DiskUtil::complete_io_request(io_context_t ctx, io_event* events, int num_events) {
  for (int i = 0; i < num_events; i++) {
    struct iocb *io_cb = reinterpret_cast<struct iocb *>(events[i].obj);
    IORequest *req = reinterpret_cast<IORequest *>(io_cb->data);
    process_io_request(req);
    delete io_cb;
  }
}
```

可以看到，使用libaio读写文件的代码逻辑其实很简单，但是需要特别注意的点，在打开文件时，必须带上
`O_DIRECT`的flag!!!

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

1. 传递给libaio的读写buffer必须是4K对齐的，为此需要用`posix_memalign`函数来malloc内存。
2. 上述例子为了实现简单，直接开启了一个线程负责libaio的读写请求，其实libaio也支持与epoll结合使用，可以将读写文件的fd交由epoll来管理，从而实现整个服务只使用单线程(单线程简单易懂，又不需要考虑锁的逻辑，实际在项目中运用时推荐使用)

完整代码参见github链接：https://github.com/lambertxiao/storage/tree/master/libaio

## 为什么libaio性能高

1. 异步I/O操作：libaio使用异步I/O操作方式，当发起一个I/O操作后，操作系统会立即返回并继续执行其他任务，而不必等待数据传输完成，这种操作方式可以充分利用CPU和I/O设备的资源，提高系统的I/O性能。
】2. 零拷贝：libaio能够在内核空间和用户空间之间实现零拷贝数据传输，即在操作系统内核中完成数据传输操作，并直接将数据传递到应用程序的用户空间，避免了数据拷贝操作，减少了CPU的负载，提高了数据传输速度和性能。

3. 4K对齐：libaio要求数据块对齐到4K的边界，这样可以避免额外的I/O操作，充分利用操作系统的缓存机制，从而提高文件读写性能。

4. 多线程I/O ：libaio支持多线程I/O操作，可以并发地进行多个I/O操作，从而更加充分地利用CPU和I/O设备的资源，提高系统I/O性能。
