--
-- $Id$
--
alter table customer add
(linenumbersyn varchar2(1)
);
update customer
   set linenumbersyn = nvl(resubmitorder,'N')
 where linenumbersyn is null;
select custid,resubmitorder,linenumbersyn
  from customer
 order by custid;
exit;
