--
-- $Id$
--
alter table CARRIER modify (FAX varchar2(25));
alter table CONSIGNEE modify (FAX varchar2(25));
alter table CUSTOMER modify (FAX varchar2(25));
alter table CUSTOMER modify (RNEWFAX varchar2(25));
alter table CUSTOMER modify (RCPTFAX varchar2(25));
alter table CUSTOMER modify (MISCFAX varchar2(25));
alter table CUSTOMER modify (OUTBFAX varchar2(25));
alter table FACILITY modify (FAX varchar2(25));
alter table NEWORDERHDR modify (SHIPTOFAX varchar2(25));
alter table NEWORDERHDR modify (BILLTOFAX varchar2(25));
alter table OLDORDERHDR modify (SHIPTOFAX varchar2(25));
alter table OLDORDERHDR modify (BILLTOFAX varchar2(25));
alter table ORDERHDR modify (SHIPTOFAX varchar2(25));
alter table ORDERHDR modify (BILLTOFAX varchar2(25));
alter table SHIPPER modify (FAX varchar2(25));
alter table USERHEADER modify (FAX varchar2(25));
--exit;

