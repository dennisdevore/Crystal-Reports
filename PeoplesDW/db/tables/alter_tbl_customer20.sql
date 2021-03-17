--
-- $Id$
--
alter table customer add
(
  defconsolidated char(1),
 	defshiptype varchar2(1),
  defcarrier varchar2(4),
  defservicelevel varchar2(4),
  defshipcost number(10,2)
);
update customer
set defconsolidated = 'N'
where defconsolidated is null;
commit;
--exit;
