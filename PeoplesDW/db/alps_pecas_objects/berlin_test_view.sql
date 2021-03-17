create or replace function ber_test_lf_dtl_rownum
(
	in_lpid   varchar2,
  	in_pieces number
)
return number
is
--
-- $Id: berlin_test_view.sql 1 2005-05-26 12:20:03Z ed $
--
	cnt number := 0;
begin
  for crec in (select pieces from load_flag_dtl
                where lpid = in_lpid
                order by pieces desc)
   loop
      cnt := cnt + 1;
      exit when crec.pieces <= in_pieces;
   end loop;

   return cnt;
end ber_test_lf_dtl_rownum;
/


create or replace view ber_test_lf_dtl
(
   lpid,
   p1,
   q1,
   p2,
   q2,
   tqbox
)
as
select
   lpid,
   sum(decode(rownm,1,pieces,0)),
   sum(decode(rownm,1,quantity,0)),
   sum(decode(rownm,2,pieces,0)),
   sum(decode(rownm,2,quantity,0)),
   sum(decode(rownm,1,quantity,0)) + sum(decode(rownm,2,quantity,0))
from
	(select ber_test_lf_dtl_rownum(lpid, pieces) rownm,
            lpid,
            pieces,
            quantity
	 from load_flag_dtl)
group by lpid;

comment on table ber_test_lf_dtl is '$Id: berlin_test_view.sql 1 2005-05-26 12:20:03Z ed $';

exit;
