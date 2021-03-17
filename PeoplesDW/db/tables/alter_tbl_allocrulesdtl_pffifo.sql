--
-- $:$
--
alter table allocrulesdtl add
(
   pickfrontfifo   varchar2(1)
);

update allocrulesdtl
set pickfrontfifo = 'N'
where pickfrontfifo is null;

exit;
