--
-- $Id$
--
alter table allocrulesdtl add
(strictfifo char(1)
);

update allocrulesdtl
   set strictfifo = 'N'
 where strictfifo is null;
 
commit;
--exit;
