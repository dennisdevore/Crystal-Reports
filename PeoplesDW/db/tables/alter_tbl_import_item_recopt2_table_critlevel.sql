--
-- $Id: alter_tbl_import_item_recopt2_table_critlevel.sql 2149 2013-08-14 19:11:27Z ay $
--
alter table import_item_recopt2_table add
(
   critlevel1                   number(4),
   critlevel2                   number(4),
   critlevel3                   number(4),
   parseruleaction              varchar2(1),
   parseruleid                  varchar2(10),
   parseentryfield              varchar2(12),
   putaway_highest_wholeuom_yn  char(1),
   returnsdisposition           varchar2(10),
   warnshortlp                  char(1),
   warnshortlpqty               number(7),
   disallowoverbuiltlp          char(1),
   maxqtyof1                    varchar2(1),
   nomixeditemlp                char(1) 
);

exit;
