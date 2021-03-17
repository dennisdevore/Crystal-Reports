--
-- $Id$
--
update custitembolcomments
   set consignee = 'default'
 where consignee is null;
update custitemoutcomments
   set consignee = 'default'
 where consignee is null;
update custitembolcomments
   set item = 'default'
 where item is null;
update custitemoutcomments
   set item = 'default'
 where item is null;
update custitembolcomments
   set custid = 'default'
 where custid is null;
update custitemoutcomments
   set custid = 'default'
 where custid is null;
commit;
exit;