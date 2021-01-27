---
title: MySQL问题点点滴滴
date: 2021-01-13 15:19:49
tags:
---
&nbsp;&nbsp;&nbsp;&nbsp;工作上遇到一些数据库的问题，现在把使用MySQL的问题都记录下来。~~(遥想上一次写SQL语句，还是2007-2008年间，用着SQL server 2005)~~    
<!--more-->     
### 创建的用户没办法创建数据库    
```SQL
CREATE USER 'pig'@'%' IDENTIFIED BY '123456';
```
&nbsp;&nbsp;&nbsp;&nbsp;创建pig用户后
```SQL
mysql -upig -p123456

mysql: [Warning] Using a password on the command line interface can be insecure.
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 9
Server version: 8.0.22 MySQL Community Server - GPL

Copyright (c) 2000, 2020, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
+--------------------+
1 row in set (0.00 sec)

mysql> create database pig_db
    -> ;
ERROR 1044 (42000): Access denied for user 'pig'@'%' to database 'pig_db'
```
&nbsp;&nbsp;&nbsp;&nbsp;根据[这个链接](https://blog.csdn.net/Carolinedy/article/details/81167772), 查看了下权限
```SQL
mysql> show grants;
+---------------------------------------+
| Grants for distcoder@%                |
+---------------------------------------+
| GRANT USAGE ON *.* TO `distcoder`@`%` |
+---------------------------------------+
1 row in set (0.01 sec)
```
&nbsp;&nbsp;&nbsp;&nbsp;没有权限。搜了下怎么添加权限，根据[这个链接](https://www.jianshu.com/p/d7b9c468f20d)，登录root用户，给pig用户添加权限:
```SQL
mysql -uroot -p           
mysql: [Warning] Using a password on the command line interface can be insecure.
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 12
Server version: 8.0.22 MySQL Community Server - GPL

Copyright (c) 2000, 2020, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> GRANT ALL ON *.* TO 'distcoder'@'%';
Query OK, 0 rows affected (0.00 sec)
```
&nbsp;&nbsp;&nbsp;&nbsp;再用pig用户登录，查看下权限：
```SQL
mysql> show grants;
+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Grants for pig@%                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, RELOAD, SHUTDOWN, PROCESS, FILE, REFERENCES, INDEX, ALTER, SHOW DATABASES, SUPER, CREATE TEMPORARY TABLES, LOCK TABLES, EXECUTE, REPLICATION SLAVE, REPLICATION CLIENT, CREATE VIEW, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, CREATE USER, EVENT, TRIGGER, CREATE TABLESPACE, CREATE ROLE, DROP ROLE ON *.* TO `pig`@`%`                                                                                                                                               |
| GRANT APPLICATION_PASSWORD_ADMIN,AUDIT_ADMIN,BACKUP_ADMIN,BINLOG_ADMIN,BINLOG_ENCRYPTION_ADMIN,CLONE_ADMIN,CONNECTION_ADMIN,ENCRYPTION_KEY_ADMIN,GROUP_REPLICATION_ADMIN,INNODB_REDO_LOG_ARCHIVE,INNODB_REDO_LOG_ENABLE,PERSIST_RO_VARIABLES_ADMIN,REPLICATION_APPLIER,REPLICATION_SLAVE_ADMIN,RESOURCE_GROUP_ADMIN,RESOURCE_GROUP_USER,ROLE_ADMIN,SERVICE_CONNECTION_ADMIN,SESSION_VARIABLES_ADMIN,SET_USER_ID,SHOW_ROUTINE,SYSTEM_USER,SYSTEM_VARIABLES_ADMIN,TABLE_ENCRYPTION_ADMIN,XA_RECOVER_ADMIN ON *.* TO `pig`@`%` |
+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
2 rows in set (0.00 sec)

mysql> create database pig_db;
Query OK, 1 row affected (0.00 sec)
```

### 开启日志记录查询  
 #### 查询日志功能是否开启 
 ```SQL
 mysql> show variables like 'general%';
+------------------+------------------------------------+
| Variable_name    | Value                              |
+------------------+------------------------------------+
| general_log      | OFF                                |
| general_log_file | /usr/local/mysql/data/macdeMBP.log |
+------------------+------------------------------------+
2 rows in set (0.01 sec)
 ```
 &nbsp;&nbsp;&nbsp;&nbsp;可以看到general_logmore默认是是OFF，也就是关闭日志功能的。日志文件保存的路径在general_log_file中

#### 开启日志
 ```SQL
 mysql> set global general_log='ON';
Query OK, 0 rows affected (0.01 sec)

mysql> show variables like 'general%';
+------------------+------------------------------------+
| Variable_name    | Value                              |
+------------------+------------------------------------+
| general_log      | ON                                 |
| general_log_file | /usr/local/mysql/data/macdeMBP.log |
+------------------+------------------------------------+
2 rows in set (0.01 sec)
 ```

 ### mysqldump导出数据
 #### 导出数据操作
 数据导出：
 ```SQL
 mysqldump -u'test' -p'test' -P3306 db1 table1 > dump.txt
 ```
 数据导入:    
 &nbsp;&nbsp;&nbsp;&nbsp;连接数据库，然后执行：
 ```SQL
 mysql> source dump.txt
 ```
 #### 导出遇到的问题
##### 问题一
 ```SQL
mysqldump -u'test' -p'test'   -P3306   --all-databases > all_database_sql
mysqldump: [Warning] Using a password on the command line interface can be insecure.
mysqldump: Error: 'Access denied; you need (at least one of) the PROCESS privilege(s) for this operation' when trying to dump tablespaces
 ```
 解决办法：
 ```SQL
 mysqldump -u'test' -p'test'   -P3306  --no-tablespaces  --all-databases > all_database_sql
 ```