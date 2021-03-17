--
-- $Id$
--
alter table customer add
(
	defhandlingpct			number(3),
   allowpickpassing		varchar2(1),
   paperbased				varchar2(1)
);

update customer
	set allowpickpassing = 'Y'
   where allowpickpassing is null;

update customer
 	set paperbased = 'N'
 	where paperbased is null;

commit;

exit;
