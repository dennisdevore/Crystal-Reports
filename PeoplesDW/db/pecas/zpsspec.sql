--
-- $Id$
--
create or replace package zps as
----------------------------------------------------------------------
--
-- next_print_set
--
----------------------------------------------------------------------
PROCEDURE next_print_set
(
    out_printno  OUT number
);

----------------------------------------------------------------------
--
-- add_print_set_hdr
--
----------------------------------------------------------------------
PROCEDURE add_print_set_hdr
(
    in_printno  number,
    in_descr    varchar2,
    in_custid   varchar2,
    in_jobno    varchar2,
    in_item     varchar2,
    in_carrier  varchar2,
    in_printtype  varchar2,
    in_shiptype varchar2,
    out_errmsg  OUT varchar2
);

----------------------------------------------------------------------
--
-- add_print_set_dtl
--
----------------------------------------------------------------------
PROCEDURE add_print_set_dtl
(
    in_printno  number,
    in_lpid     varchar2,
    out_errmsg  OUT varchar2
);

----------------------------------------------------------------------
--
-- clear_print_set_dtl
--
----------------------------------------------------------------------
PROCEDURE clear_print_set_dtl
(
    in_printno  number,
    out_errmsg  OUT varchar2
);

----------------------------------------------------------------------
--
-- print_a_print_set
--
----------------------------------------------------------------------
PROCEDURE print_a_print_set
(
    in_facility varchar2,
    in_printno  number,
    in_printer  varchar2,
    in_printtype varchar2,
    in_userid   varchar2,
    out_errmsg  OUT varchar2
);

----------------------------------------------------------------------
--
-- cleanup - clear old print set information
--
----------------------------------------------------------------------
PROCEDURE cleanup
(
    in_date date
);

END zps;
/
exit;
