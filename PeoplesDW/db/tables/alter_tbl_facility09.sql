alter table facility drop 
(
  workstart, 
  workfinish, 
  worksunday, 
  workmonday, 
  worktuesday, 
  workwednesday, 
  workthursday, 
  workfriday, 
  worksaturday, 
  inboundres, 
  outboundres
);

alter table facility add
(
  workstart_in        date,
  workfinish_in       date,
  worksunday_in       char(1) default 'N',
  workmonday_in       char(1) default 'Y',
  worktuesday_in      char(1) default 'Y',
  workwednesday_in    char(1) default 'Y',
  workthursday_in     char(1) default 'Y',
  workfriday_in       char(1) default 'Y',
  worksaturday_in     char(1) default 'N',
  workstart_out       date,
  workfinish_out      date,
  worksunday_out      char(1) default 'N',
  workmonday_out      char(1) default 'Y',
  worktuesday_out     char(1) default 'Y',
  workwednesday_out   char(1) default 'Y',
  workthursday_out    char(1) default 'Y',
  workfriday_out      char(1) default 'Y',
  worksaturday_out    char(1) default 'N',
  inrescount          number(2),
  outrescount         number(2)
);

update facility 
set
  workstart_in = to_date('08:00', 'HH24:MI'),
  workfinish_in = to_date('17:00', 'HH24:MI'), 
  worksunday_in = 'N',
  workmonday_in = 'Y',
  worktuesday_in = 'Y',
  workwednesday_in = 'Y',
  workthursday_in = 'Y',
  workfriday_in = 'Y',
  worksaturday_in = 'N',
  workstart_out = to_date('08:00', 'HH24:MI'),
  workfinish_out = to_date('17:00', 'HH24:MI'),
  worksunday_out = 'N',
  workmonday_out = 'Y',
  worktuesday_out = 'Y',
  workwednesday_out = 'Y',
  workthursday_out = 'Y',
  workfriday_out = 'Y',
  worksaturday_out = 'N',
  inrescount = 3,
  outrescount = 2;
/

commit;
/ 
