---
title: MPI+多线程混合编程
date: 2021-01-12 13:15:28
tags:
---
&nbsp;&nbsp;&nbsp;&nbsp;在阅读Horovod源码的时候，遇到了MPI+多线程的问题，所以写篇文章来大概描述下MPI+多线程的混合编程。 
<!--more-->  
&nbsp;&nbsp;&nbsp;&nbsp;MPI描述的是节点间并行描述，通常MPI中大多数操作的基本实体是进.。多线程提供了在节点内共享内存的并行， 在最新的MPI实现中都支持了在MPI进程中执行多个线程，也就是MPI+多线程的混合编程。
![](/images/MPI混合编程.png)     
&nbsp;&nbsp;&nbsp;&nbsp;在MPI中,支持四种级别的线程安全规范:    
&nbsp;&nbsp;&nbsp;&nbsp;1. **MPI_THREAD_SINGLE** :每个进程有单个的线程执行    
&nbsp;&nbsp;&nbsp;&nbsp;2. **MPI_THREAD_FUNNELED** :每个进程有多线程,但是只有初始化MPI的线程可以调用MPI函数.    
&nbsp;&nbsp;&nbsp;&nbsp;3. **MPI_THREAD_SERIALIZED** :每个进程有多线程,但是每次只有一个线程可以调用MPI函数.    
&nbsp;&nbsp;&nbsp;&nbsp;4. **MPI_THREAD_MULTIPLE** :每个进程有多线程,每个线程都可以调用MPI函数(但是也有一些限制).    
&nbsp;&nbsp;&nbsp;&nbsp;多对于MPI_THREAD_MULTIPLE的多线程情况，用户需要注意调用MPI函数时的冲突。线程并发调用MPI函数，将以某种顺序执行。在每个线程维护顺序。如果阻塞MPI函数，也只会阻塞调用线程，并不影响其他线程的执行。   

&nbsp;&nbsp;&nbsp;&nbsp;在MPI初始化过程中，用户需要指定使用的级别，同时MPI函数也会返回对应支持的级别。
```C++
int mpi_support;
MPI_Init_thread(&argc,&argv, MPI_THREAD_MULTIPLE, &mpisupport);
if (mpi_support != MPI_THREAD_MULTIPLE)
    printf(”MPI_THREAD_MULTIPLE thread support required\n”);
```    
 &nbsp;&nbsp;&nbsp;&nbsp; 需要注意的是，如果只是调用MPI_Init函数来初始化，则是假定MPI_THREAD_SINGLE级别。对于MPI多线程函数，需要使用MPI_Init_thread来初始化，这是很多人一开始没注意的问题。