--
-- $Id: alter_tbl_businessevents01.sql 1 2005-05-26 12:20:03Z ed $
--
delete tabledefs where tableid = 'BusinessEvents';
commit;

alter table businessevents add
(billing_yn char(1),
 labels_yn char(1)
);

update businessevents
   set billing_yn = 'Y'
   where billing_yn is null;
update businessevents
   set labels_yn = 'Y'
   where labels_yn is null;
commit;
exit;

--Insert into TABLEDEFS
--   (TABLEID, HDRUPDATE, DTLUPDATE, CODEMASK, LASTUSER, LASTUPDATE)
-- Values
--   ('BusinessEvents', 'N', 'N', '>Aaaa;0;_', 'SUP', TO_DATE('03/19/2001 13:54:46', 'MM/DD/YYYY HH24:MI:SS'));


