drop database link prod;
create database link prod
connect to alps identified by alps
using 'prod';
exit;

