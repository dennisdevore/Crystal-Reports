--
-- $Id$
--
alter table ucc_standard_labels add
(
   color                varchar2(255),
   customeritem         varchar2(255),
   department           varchar2(255),
   division             varchar2(255),
   itemsize             varchar2(255),
   makrforstate         varchar2(255),
   markforaddr1         varchar2(255),
   markforaddr2         varchar2(255),
   markforcity          varchar2(255),
   markforcountrycode   varchar2(255),
   markforname          varchar2(255),
   markforstate         varchar2(255),
   markforzip           varchar2(255),
   storenum             varchar2(255),
   style                varchar2(255),
   vendoritem           varchar2(255)
);

exit;
