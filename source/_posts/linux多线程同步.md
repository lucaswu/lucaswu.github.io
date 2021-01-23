---
title: linux多线程同步
date: 2021-01-23 09:03:24
tags:
---
&nbsp;&nbsp;&nbsp;&nbsp;在工作中，遇到这样一个应用场景：子线程每隔5分钟需要与服务器端通信，其他时候都在睡眠；程序退出的时候，子线程也需要跟着退出。
<!--more-->     
&nbsp;&nbsp;&nbsp;&nbsp;刚看到这个功能需求的时候，想着不是so easy的事情，赶紧把代码写了，代码大致如下demo所示。
```C++
#include <stdio.h>
#include <pthread.h>
#include <unistd.h>

bool flag = true;
void *thr_fn(void*arg)
{
    while(flag){
        printf(".\n");
        sleep(300);
    }
    printf("thread exit\n");
}

int main()
{
    pthread_t thread;
    pthread_create(&thread,NULL,thr_fn,NULL);
    char c;
    while( (c = getchar()) != 'q');
    
    printf("Now terminate the thread!\n");
    flag = false;
    printf("Wait for thread to exit!\n");
    pthread_join(thread,NULL);
    printf("Byt!\n");
    return 0;
}
```
&nbsp;&nbsp;&nbsp;&nbsp;测试的时候发现，极端情况下，主线程需要等5分钟，才能退出。这完全就不是我想要的。    

&nbsp;&nbsp;&nbsp;&nbsp;在网上"搜索linux 线程 唤醒",知道了pthread_cond_timedwait和pthread_cond_wait函数。    
&nbsp;&nbsp;&nbsp;&nbsp;对于linux下线程等待和唤醒函数比较：




 函数 | 说明 
 :-----:| :----: 
 sleep | 线程等待，等待期间线程无法唤醒 
 pthread_cond_wait | 线程等待信号触发，如果没有信号触发，无限期等待下去 
 pthread_cond_timedwait | 线程等待一定的时间，如果超时或有信号触发，线程唤醒     

&nbsp;&nbsp;&nbsp;&nbsp;通过上述表格说明，pthread_cond_timedwait符合需求。函数具体的用法，请自行搜索下。所以，最后我的程序大致如下：
```C++
#include <stdio.h>
#include <pthread.h>
#include <unistd.h>
#include <sys/time.h>

bool flag = true;
pthread_cond_t cond = PTHREAD_COND_INITIALIZER;
pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

void *thr_fn(void*arg)
{
    struct  timeval now;
    struct timespec outtime;

    pthread_mutex_lock(&mutex);

    while(flag){
        printf(".\n");
        gettimeofday(&now,NULL);
        outtime.tv_sec = now.tv_sec + 10;
        outtime.tv_nsec = now.tv_usec* 1000;
        pthread_cond_timedwait(&cond,&mutex,&outtime);
    }
    pthread_mutex_unlock(&mutex);
    printf("thread exit\n"); 
}


int main()
{
    pthread_t thread;
    pthread_create(&thread,NULL,thr_fn,NULL);

    char c;
    while( (c = getchar()) != 'q');
    printf("Now terminate the thread!\n");
    flag = false;
    pthread_mutex_lock(&mutex);
    pthread_cond_signal(&cond);
    pthread_mutex_unlock(&mutex);
    printf("Wait for thread to exit!\n");
    pthread_join(thread,NULL);
    printf("Byt!\n");
    return 0;
}
```