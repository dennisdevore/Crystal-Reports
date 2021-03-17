--
-- $Id$
--
alter table CARRIER modify (PHONE varchar2(25));
alter table CONSIGNEE modify (PHONE varchar2(25));
alter table CUSTOMER modify (PHONE varchar2(25));
alter table CUSTOMER modify (RNEWPHONE varchar2(25));
alter table CUSTOMER modify (RCPTPHONE varchar2(25));
alter table CUSTOMER modify (MISCPHONE varchar2(25));
alter table CUSTOMER modify (OUTBPHONE varchar2(25));
alter table FACILITY modify (PHONE varchar2(25));
alter table MULTISHIPHDR modify (SHIPTOPHONE varchar2(25));
alter table NEWORDERHDR modify (SHIPTOPHONE varchar2(25));
alter table NEWORDERHDR modify (BILLTOPHONE varchar2(25));
alter table OLDORDERHDR modify (SHIPTOPHONE varchar2(25));
alter table OLDORDERHDR modify (BILLTOPHONE varchar2(25));
alter table ORDERHDR modify (SHIPTOPHONE varchar2(25));
alter table ORDERHDR modify (BILLTOPHONE varchar2(25));
alter table SHIPPER modify (PHONE varchar2(25));
alter table USERHEADER modify (PHONE varchar2(25));
--exit;
