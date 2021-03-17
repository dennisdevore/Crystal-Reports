--
-- $Id$
--
alter table customer add
(recv_line_check_yn char(1)
,recv_line_variance_pct number(3)
);

update customer
   set recv_line_check_yn = 'N'
 where recv_line_check_yn is null;
commit;

exit;
