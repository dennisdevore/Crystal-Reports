--
-- $Id: orderdtlpack.sql 1 2005-05-26 12:20:03Z ed $
--

create table orderdtlpack
(ORDERID          NUMBER(7) NOT NULL
,SHIPID           NUMBER(2) NOT NULL
,item varchar2(50) NOT NULL  /* orderdtl item */
,LOTNUMBER        VARCHAR2(30)
,LINENUMBER       NUMBER(3) NOT NULL
,ITEMENTERED      VARCHAR2(20)           /* pak item */
,QTY              NUMBER(7)
,DESCRIPTION      VARCHAR2(255)
,LASTUSER         VARCHAR2(12)
,LASTUPDATE       DATE
);


create unique index orderdtlpack_idx
   on orderdtlpack (orderid, shipid, item, lotnumber, linenumber, itementered);
exit;
