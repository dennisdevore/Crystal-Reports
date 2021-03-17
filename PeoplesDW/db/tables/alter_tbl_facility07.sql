--
-- $Id$
--
alter table facility add
(
   suppress_lp_in_rf_loading char(1) default 'N'
);

commit;

exit;
