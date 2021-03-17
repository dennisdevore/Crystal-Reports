--
-- $Id$
--
create index orderdtlrcpt_useritem1_idx
   on orderdtlrcpt(useritem1);

create index orderdtlrcpt_useritem2_idx
   on orderdtlrcpt(useritem2);

create index orderdtlrcpt_useritem3_idx
   on orderdtlrcpt(useritem3);

create index orderdtlrcpt_idx
   on orderdtlrcpt(serialnumber, useritem1, useritem2, useritem3);

exit;
