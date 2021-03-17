--
-- $Id: $
--

create table zenith_case_labels(
   lpid                 varchar2(15),
   sscc18               varchar2(20),
   shiptoname           varchar2(40),
   shiptoaddr1          varchar2(40),
   shiptoaddr2          varchar2(40),
   shiptocity           varchar2(30),
   shiptostate          varchar2(2),
   shiptopstlcd         varchar2(12),
   barpstlcd            varchar2(12),
   label_dat            varchar2(12),
   orderid              number(9),
   shipid               number(7),
   item varchar2(50),
   descr                varchar2(40),
   wmit                 varchar2(20),
   po                   varchar2(20),
   reference            varchar2(20),
   loadno		number(7),
   custname             varchar2(40),
   whsename             varchar2(40),
   whseaddr1            varchar2(40),
   whseaddr2            varchar2(40),
   whsecity             varchar2(30),
   whsestate            varchar2(2),
   whsepstlcd           varchar2(12),
   seq                  number,
   seqof                number,
   comment1		varchar2(40),
   wave			number(9),
   stageloc		varchar2(20),
   changed		varchar2(1)
);

drop index zenith_case_labels_ordidx;
create index zenith_case_labels_ordidx
   on zenith_case_labels(orderid, shipid);

drop index zenith_case_labels_lodidx;
create index zenith_case_labels_lodidx
   on zenith_case_labels(loadno);

drop index zenith_case_labels_wavidx;
create index zenith_case_labels_wavidx
   on zenith_case_labels(wave);

exit;
