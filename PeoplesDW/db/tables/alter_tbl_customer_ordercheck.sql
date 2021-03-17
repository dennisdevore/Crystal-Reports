--
-- $Id$
--
alter table customer add(
  ordercheckformat       varchar2(255),
  printordercheck_yn     char(1)
);

update customer
set printordercheck_yn = 'N'
where printordercheck_yn is null;

commit;
exit;