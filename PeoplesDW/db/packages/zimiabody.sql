create or replace PACKAGE BODY alps.zimportprocinvadj
IS
--
-- $Id$
--

IMP_USERID constant varchar2(9) := 'IMPINVADJ';



PROCEDURE import_inventory_status
(in_facility    IN varchar2
,in_custid      IN varchar2
,in_item        IN varchar2
,in_lotnumber   IN varchar2
,in_status      IN varchar2
,in_reason      IN varchar2
,out_errorno IN OUT number
,out_msg     IN OUT varchar2
)
IS

CURSOR C_PLATES
IS
SELECT *
  FROM plate
 WHERE facility = in_facility
   AND custid = in_custid
   AND item = in_item
   AND nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
   AND invstatus = decode(in_status,'AV','OH','OH','AV','xx')
   AND status in ('A','I');

CURSOR C_MPS
IS
SELECT distinct parentlpid
  FROM plate
 WHERE facility = in_facility
   AND custid = in_custid
   AND item = in_item
   AND nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
   AND status in ('A','I')
   AND parentlpid is not null;

l_invstatus plate.invstatus%type;

l_adj1 varchar2(20);
l_adj2 varchar2(20);
l_controlnumber varchar2(10);

errno number;
errmsg varchar2(255);


PROCEDURE log_msg(in_msgtype varchar2, in_msg varchar2)
IS
strMsg appmsgs.msgtext%type;
BEGIN
  out_msg := 'Cust. ' || rtrim(in_custid) || ' Item ' || rtrim(in_item)||
    '/'||rtrim(in_lotnumber) || ': ' || in_msg;
  zms.log_msg(IMP_USERID, in_facility, rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
END;

BEGIN
    out_errorno := 0;
    out_msg := 'OKAY';

    if rtrim(in_status) not in ('AV','OH') then
        log_msg('E','Status:'||rtrim(in_status)||' must be AV or OH');
        return;
    end if;

-- First update the plates
    for crec in C_PLATES loop

        zia.change_invstatus
            (crec.lpid,in_status, nvl(in_reason,'PC'),'IA',IMP_USERID,
             l_adj1, l_adj2, l_controlnumber, errno, errmsg);

        if nvl(errno,0) != 0 then
            log_msg('E','Status change failed. LPID:'||crec.lpid
                ||' - '||errmsg);
        end if;
    end loop;

-- Then for all plates that are on a master check if the master status needs
--  to change
    for crec in C_MPS loop

        l_invstatus := null;
        begin
            select distinct invstatus
              into l_invstatus
              from plate
             where parentlpid = crec.parentlpid;
        exception
            when others then
                l_invstatus := null;
        end;

        update plate
           set invstatus = l_invstatus
         where lpid = crec.parentlpid
           and nvl(invstatus,'xx') = nvl(l_invstatus, 'xx');


    end loop;



EXCEPTION WHEN OTHERS THEN
  out_errorno := sqlcode;
  out_msg := substr(sqlerrm,1,80);
END import_inventory_status;



end zimportprocinvadj;
/

exit;
