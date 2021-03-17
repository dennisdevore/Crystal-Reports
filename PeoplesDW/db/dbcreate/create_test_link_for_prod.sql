drop database link test;
create database link test
connect to alps identified by alps
using 'test';
exit;

