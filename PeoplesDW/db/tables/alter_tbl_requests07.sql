alter table requests add
(option07 varchar2(12)
,option08 varchar2(12)
,option09 varchar2(12)
,num11 number(12,2)
);

update requests
   set flag07 = 'N' -- sdi_sortation_yn
 where ReqType = 'WaveSelect';

exit;
