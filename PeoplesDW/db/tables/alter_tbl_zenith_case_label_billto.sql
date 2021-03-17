--
-- $Id$
--
alter table zenith_case_labels add (
   billtoname				varchar2(40),
   billtocontact			varchar2(40),
   billtoaddr1				varchar2(40),
   billtoaddr2				varchar2(40),
   billtocity				varchar2(30),
   billtostate				varchar2(2),
   billtopostalcode		varchar2(12),
   billtocountrycode    varchar2(3),
   billtophone				varchar2(25),
   billtofax				varchar2(25),
   billtoemail				varchar2(255)
);

exit;
