--
-- $Id$
--
alter table orderhdr
add
(billtoname varchar2(40)
,billtocontact varchar2(40)
,billtoaddr1 varchar2(40)
,billtoaddr2 varchar2(40)
,billtocity varchar2(30)
,billtostate varchar2(2)
,billtopostalcode varchar2(12)
,billtocountrycode varchar2(3)
,billtophone varchar2(15)
,billtofax varchar2(15)
,billtoemail varchar2(255)
);
exit;
