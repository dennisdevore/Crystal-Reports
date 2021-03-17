--
-- $Id$
--
grant select, insert,update on pecas.load_flag_ctn to alps;
grant insert,update,delete on pecas.load_flag_dtl to alps;
grant select on pecas.load_flag_dtl to alps with grant option;
grant insert,update on pecas.load_flag_hdr to alps;
grant select on pecas.load_flag_hdr to alps with grant option;
grant select,insert,update on pecas.print_set_dtl to alps with grant option;
grant select,insert,update on pecas.print_set_hdr to alps;
exit;
