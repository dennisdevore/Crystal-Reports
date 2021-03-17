--
-- $Id$
--
alter table orderdtlline add
(
   xdock             char(1),
   consignee         varchar2(10),
   carrier           varchar2(10),
   deliveryservice   varchar2(4),
   saturdaydelivery  char(1),
   shiptype          varchar2(1),
   shipterms         varchar2(3),
   shipdate          date,
   arrivaldate       date,
   stageloc          varchar2(10),
   prono             varchar2(20),
   shippingcost      number(10,2),
   shiptoname        varchar2(40),
   shiptoaddr1       varchar2(40),
   shiptoaddr2       varchar2(40),
   shiptocity        varchar2(30),
   shiptostate       varchar2(2),
   shiptopostalcode  varchar2(12),
   shiptocountrycode varchar2(3),
   cod               char(1),
   companycheckok    char(1),
   amtcod            number(10,2),
   shiptocontact     varchar2(40),
   shiptophone       varchar2(25),
   shiptofax         varchar2(25),
   shiptoemail       varchar2(255),
   specialservice1   varchar2(4),
   specialservice2   varchar2(4),
   specialservice3   varchar2(4),
   specialservice4   varchar2(4),
   billtoname        varchar2(40),
   billtoaddr1       varchar2(40),
   billtoaddr2       varchar2(40),
   billtocity        varchar2(30),
   billtostate       varchar2(2),
   billtopostalcode  varchar2(12),
   billtocountrycode varchar2(3),
   billtocontact     varchar2(40),
   billtophone       varchar2(25),
   billtofax         varchar2(25),
   billtoemail       varchar2(255)
);

update orderdtlline
   set xdock = 'Y'
   where shipto is not null;
commit;

exit;

