/*
 * @Version $Id$
 */  
alter table customer_aux add
(
  enter_min_days_to_expire_yn  char(1) default 'N'
);

exit;
