alter table requests add
(flag20 varchar2(1)
);

update requests
   set flag20 = 'N' -- sdi_manual_picks
 where ReqType = 'WaveSelect';

exit;
