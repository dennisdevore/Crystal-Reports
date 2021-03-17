alter table custrate add (
    cxd_grace           char(1) default 'N',
    cxd_grace_days      number(2),
    cxd_anvdate_grace   char(1) default 'N');
exit;
