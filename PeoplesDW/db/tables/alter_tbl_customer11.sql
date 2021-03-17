--
-- $Id$
--
alter table customer add
(shipnote_include_cancelled_yn char(1)
,rcptnote_include_cancelled_yn char(1)
,pallet_tracking_export_map varchar2(255)
);

update customer
   set shipnote_include_cancelled_yn = 'N',
       rcptnote_include_cancelled_yn = 'N'
 where shipnote_include_cancelled_yn is null;

drop table whentoconfirmoutbound;

drop table whentoackoutbound;

delete from tabledefs
 where upper(tableid) = 'WHENTOCONFIRMOUTBOUND';

delete from tabledefs
 where upper(tableid) = 'WHENTOACKOUTBOUND';

commit;

--exit;
