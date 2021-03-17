--
-- $Id$
--
alter table customer add(
    assign_stop_by_passthru_yn  char(1),
    assign_stop_load_passthru   varchar2(16),
    assign_stop_stop_passthru   varchar2(16)
);

exit;
