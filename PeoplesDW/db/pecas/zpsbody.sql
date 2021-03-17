create or replace package body zps as
--
-- $Id$
--






----------------------------------------------------------------------
--
-- Trace - write an entry to the trace file if it is opened
--
----------------------------------------------------------------------
PROCEDURE Trace
(
    in_src      varchar2,
    in_msg      varchar2
)
IS
ds varchar2(20);
fn varchar2(200);           -- File Name
FP utl_file.file_type;
BEGIN

    zlog.add(in_src, in_msg);

    return;


EXCEPTION WHEN OTHERS THEN
    -- sa_log.add('000','MP Trace',substr(sqlerrm,1,200));
    null;
END Trace;


----------------------------------------------------------------------
--
-- next_print_set
--
----------------------------------------------------------------------
PROCEDURE next_print_set
(
    out_printno  OUT number
)
IS
printno number;
BEGIN
    out_printno := 0;
    select printsetseq.nextval
      into out_printno
      from dual;

    return;
EXCEPTION WHEN OTHERS THEN
    out_printno := -1;

END next_print_set;


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
)
IS
BEGIN
    out_errmsg := 'OKAY';

    insert into print_set_hdr(printno, descr, custid, jobno, item, carrier,
            printtype, shiptype, status, created)
    values (in_printno, in_descr, in_custid, in_jobno, in_item, in_carrier,
            in_printtype, in_shiptype, 'NEW', sysdate);


EXCEPTION WHEN OTHERS THEN
    out_errmsg := sqlerrm;

END add_print_set_hdr;


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
)
IS
BEGIN
    out_errmsg := 'OKAY';

    insert into print_set_dtl(printno, lpid)
    values (in_printno, in_lpid);

EXCEPTION WHEN OTHERS THEN
    out_errmsg := sqlerrm;

END add_print_set_dtl;

----------------------------------------------------------------------
--
-- clear_print_set_dtl
--
----------------------------------------------------------------------
PROCEDURE clear_print_set_dtl
(
    in_printno  number,
    out_errmsg  OUT varchar2
)
IS
BEGIN
    out_errmsg := 'OKAY';

    delete from print_set_dtl
    where printno = in_printno;

EXCEPTION WHEN OTHERS THEN
    out_errmsg := sqlerrm;

END clear_print_set_dtl;


----------------------------------------------------------------------
--
-- extract_small_package
--
----------------------------------------------------------------------
PROCEDURE extract_small_package
(
    IN_PSH  print_set_hdr%rowtype,
    in_userid   varchar2,
    out_errmsg OUT  varchar2   
)
IS
errorno number;

da_script varchar2(50);
BEGIN
    out_errmsg := 'OKAY';

  
    if IN_PSH.carrier = 'UPS' then
        da_script := 'Berlin UPS Batch Export';
    else
        da_script := 'Berlin FedX Batch Export';
    end if;

    ziem.impexp_request('E',null,IN_PSH.custid,
      da_script,null,'NOW',
      IN_PSH.printno,0,0,in_userid,null,null,null,null,null,
      null,null,errorno,out_errmsg);

    zut.prt('Export request:'||out_errmsg||' Errno:'||errorno);

EXCEPTION WHEN OTHERS THEN
    out_errmsg := sqlerrm;
END extract_small_package;

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
)
IS
CURSOR C_PS(in_printno number)
IS
SELECT *
  FROM print_set_hdr
 WHERE printno = in_printno;

PSH print_set_hdr%rowtype;

CURSOR C_LFL(in_type varchar2)
IS
SELECT *
  FROM alps.loadflaglabels
 WHERE code = in_type;

LFL alps.loadflaglabels%rowtype;

errmsg varchar2(255);

BEGIN

    out_errmsg := 'OKAY';

    PSH := null;
    OPEN C_PS(in_printno);
    FETCH C_PS into PSH;
    CLOSE C_PS;

    if PSH.printno is null then
        out_errmsg := 'invalid print set';
        return;
    end if;

    errmsg := null;

    if in_PrintType = 'SMALL PACKAGE' then
       -- Do extract request here
        extract_small_package(PSH, in_userid, out_errmsg);
    elsif in_PrintType = 'LOAD FLAGS' then

        LFL := null;
        OPEN C_LFL(substr(PSH.shiptype,1,1));
        FETCH C_LFL into LFL;
        CLOSE C_LFL;

        zlbprt.print_load_flags(PSH.printno,
            rtrim(substr(LFL.abbrev,1,4)),
            rtrim(substr(LFL.abbrev,5,4)),
            in_printer,
            in_facility,
            in_userid,
            errmsg);
       -- Look up business event by ShipType
    elsif in_PrintType = 'CARTON LABELS' then
       -- Break by orderid, shipid
       -- lookup labels by orderid shipid
       -- do request for each orderid, shipid for print set
        if PSH.ShipType = 'Unbatched Small Package' then
            zlbprt.print_carton_labels(PSH.printno,
                'UBCL',
                in_printer,
                in_facility,
                in_userid,
                errmsg);
        else
            zlbprt.print_carton_labels(PSH.printno,
                'PRCL',
                in_printer,
                in_facility,
                in_userid,
                errmsg);
        end if;

    end if;

    if errmsg is not null then
        out_errmsg := errmsg;
    end if;

EXCEPTION WHEN OTHERS THEN
    out_errmsg := sqlerrm;

END print_a_print_set;



----------------------------------------------------------------------
--
-- cleanup - clear old print set information
--
----------------------------------------------------------------------
PROCEDURE cleanup
(
    in_date date
)
IS
BEGIN
    delete from print_set_dtl
    where printno in
     (select distinct printno
       from print_set_hdr
      where created <= in_date);

    delete from print_set_hdr
     where created <= in_date;

EXCEPTION WHEN OTHERS THEN
    null;
END cleanup;


END zps;
/
show errors;

exit;
