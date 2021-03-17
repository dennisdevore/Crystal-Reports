--
-- $Id: add_billingmethod_pltb.sql $
--
insert into billingmethod
values
('HPTM','Header PassThru Match','PT Match','N','SYNAPSE',sysdate);


insert into billingmethod
values
('HPTN','Header PassThru Number','PT Num','N','SYNAPSE',sysdate);

commit;
exit;