--
-- invoicedtlseq.sql
--
-- drop sequence invoicedtlseq;

create sequence invoicedtlseq
 increment by 1
 start with 1
 maxvalue   999999999999999
 minvalue   1
 nocache
 cycle;
 exit;
