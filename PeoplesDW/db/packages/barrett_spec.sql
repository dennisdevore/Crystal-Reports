create or replace PACKAGE alps.barrett
IS

PROCEDURE process_load_order
(
    in_data    IN OUT cdata,
    in_custlist IN varchar2
);

END barrett;
/
--exit;