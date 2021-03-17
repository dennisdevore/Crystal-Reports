create or replace PACKAGE BODY alps.impexpmsg
IS

--
-- $Id$
--

-- **********************************************************************
-- *                                                                    *
-- *      CONSTANTS                                                     *
-- *                                                                    *
-- **********************************************************************

-- **********************************************************************
-- *                                                                    *
-- *      CURSORS                                                       *
-- *                                                                    *
-- **********************************************************************

-- **********************************************************************
-- *                                                                    *
-- *      PROCEDURES AND FUNCTIONS                                      *
-- *                                                                    *
-- **********************************************************************

FUNCTION get_field(in_str varchar2, in_pos number)
return varchar2
IS
 l_type  varchar2(20);
 l_data  varchar2(1000);
 pos integer;
 endpos integer;
 ix integer;

BEGIN

    ix := 0;
    l_data := null;
    pos := 1;
    loop
        ix := ix + 1;
        endpos := instr(substr(in_str,pos),chr(9));
        exit when endpos = 0;
        if ix >= in_pos then
            if endpos = 0 then
                l_data := substr(in_str,pos);
            else
                l_data := substr(in_str,pos,endpos-1);
            end if;
            return l_data;
        end if;
        pos := pos + endpos;

    end loop;

    return null;

END;

FUNCTION find_queue(in_facility varchar2, in_custid varchar2)
return varchar2
IS
CURSOR C_Q(in_fac varchar2, in_custid varchar2)
IS
SELECT abbrev
  FROM impexp_queues
 WHERE code = upper(in_custid)||'/'||upper(in_fac);

que C_Q%rowtype;

BEGIN

    if in_facility is not null and in_custid is not null then
        que := null;
        OPEN C_Q(in_facility, in_custid);
        FETCH C_Q into que;
        CLOSE C_Q;
        if que.abbrev is not null then
            return que.abbrev;
        end if;
    end if;
    if in_custid is not null then
        que := null;
        OPEN C_Q('*', in_custid);
        FETCH C_Q into que;
        CLOSE C_Q;
        if que.abbrev is not null then
            return que.abbrev;
        end if;
    end if;
    if in_facility is not null then
        que := null;
        OPEN C_Q(in_facility, '*');
        FETCH C_Q into que;
        CLOSE C_Q;
        if que.abbrev is not null then
            return que.abbrev;
        end if;
    end if;

    return IE_DEFAULT_QUEUE;

EXCEPTION WHEN OTHERS THEN
    return IE_DEFAULT_QUEUE;

END find_queue;

function log_request
(in_reqtype           in varchar2
,in_facility          in varchar2
,in_custid            in varchar2
,in_formatid          in varchar2
,in_filepath          in varchar2
,in_when              in varchar2
,in_loadno            in number
,in_orderid           in number
,in_shipid            in number
,in_userid            in varchar2
,in_tablename         in varchar2
,in_columnname        in varchar2
,in_filtercolumnname  in varchar2
,in_company           in varchar2
,in_warehouse         in varchar2
,in_begindatetimestr  in varchar2
,in_enddatetimestr    in varchar2)
return integer
is PRAGMA AUTONOMOUS_TRANSACTION;
retVal integer;
errMsg varchar2(255);
BEGIN
   select impexp_log_seq.nextval into retVal from dual;
   if length(in_userid) > 12 then
      insert into impexp_log
         (logseq,reqtype,facility,custid,formatid,filepath,when_to,loadno,
          orderid,shipid,userid,tablename,columnname,filtercolumnname,
          company,warehouse,begindatetimestr,enddatetimestr,requested,rerequested)
      values
         (retVal,in_reqtype,in_facility,in_custid,in_formatid,in_filepath,in_when,in_loadno,
          in_orderid,in_shipid,'IMPEXP',in_tablename,in_columnname,in_filtercolumnname,
          in_company,in_warehouse,in_begindatetimestr,in_enddatetimestr,current_timestamp,'N');
   else
      insert into impexp_log
         (logseq,reqtype,facility,custid,formatid,filepath,when_to,loadno,
          orderid,shipid,userid,tablename,columnname,filtercolumnname,
          company,warehouse,begindatetimestr,enddatetimestr,requested,rerequested)
      values
         (retVal,in_reqtype,in_facility,in_custid,in_formatid,in_filepath,in_when,in_loadno,
          in_orderid,in_shipid,in_userid,in_tablename,in_columnname,in_filtercolumnname,
          in_company,in_warehouse,in_begindatetimestr,in_enddatetimestr,current_timestamp,'N');
   end if;
   commit;
   return retVal;
EXCEPTION WHEN OTHERS THEN
   rollback;
   zms.log_autonomous_msg('IEERR', in_facility, in_custid,'I/E Logerr: '|| sqlcode || ' ' || sqlerrm,'E',
                          'IEERR', errMsg);
   return retVal;

END log_request;


procedure impexp_request
(in_reqtype           in varchar2
,in_facility          in varchar2
,in_custid            in varchar2
,in_formatid          in varchar2
,in_filepath          in varchar2
,in_when              in varchar2
,in_loadno            in number
,in_orderid           in number
,in_shipid            in number
,in_userid            in varchar2
,in_tablename         in varchar2
,in_columnname        in varchar2
,in_filtercolumnname  in varchar2
,in_company           in varchar2
,in_warehouse         in varchar2
,in_begindatetimestr  in varchar2
,in_enddatetimestr    in varchar2
,out_errorno          in out number
,out_msg              in out varchar2)
is PRAGMA AUTONOMOUS_TRANSACTION;
errno number;
errmsg varchar2(255);
l_msg varchar2(1000);
que varchar2(12);
cnt integer;
impexp_traditional char(1);
impexp_table char(1);
l_userid varchar2(12);
begin
    begin
       select defaultvalue into impexp_traditional
          from systemdefaults
          where defaultid = 'IMPEXP_TRADITIONAL';
    exception when others then
       impexp_traditional := 'Y';
    end;

    begin
       select defaultvalue into impexp_table
          from systemdefaults
          where defaultid = 'IMPEXP_TABLE';
    exception when others then
       impexp_table := 'N';
    end;

    if impexp_table = 'Y' then
       begin
         insert into impexp_request(reqtype,facility,custid,formatid,filepath,
               when_to,loadno,orderid,shipid,userid,tablename,
               columnname,filtercolumnname,company,warehouse,
               begindatetimestr,enddatetimestr,requested)
         values (in_reqtype,in_facility,in_custid,in_formatid,in_filepath,
               in_when,in_loadno,in_orderid,in_shipid,in_userid,in_tablename,
               in_columnname,in_filtercolumnname,in_company,in_warehouse,
               in_begindatetimestr,in_enddatetimestr,sysdate);

       exception when others then
         zms.log_msg('IMPEXP', in_facility, in_custid,'IMPR: '||sqlerrm,'E',
                     'IMPEXP', errMsg);
       end;
    end if;
    if length(in_userid) > 12 then
       l_userid := 'IMPEXP';
    else
       l_userid := in_userid;
    end if;
    if impexp_traditional = 'Y' then
      que := find_queue(in_facility, in_custid);
      cnt := 0;
      select count(1) into cnt
         from user_queues
         where name = upper(que);

      if nvl(cnt,0) = 0 then
         zms.log_msg('IMPEXP', in_facility, in_custid,'Queue '||que||' does not exist ',
                     'E', 'IMPEXP', errMsg);
         que := IE_DEFAULT_QUEUE;
      end if;
      l_msg := in_reqtype ||chr(9)||
               in_facility ||chr(9)||
               in_custid ||chr(9)||
               in_formatid ||chr(9)||
               in_filepath ||chr(9)||
               in_when ||chr(9)||
               in_loadno ||chr(9)||
               in_orderid ||chr(9)||
               in_shipid ||chr(9)||
               in_userid ||chr(9)||
               in_tablename ||chr(9)||
               in_columnname ||chr(9)||
               in_filtercolumnname ||chr(9)||
               in_company ||chr(9)||
               in_warehouse ||chr(9)||
               in_begindatetimestr ||chr(9)||
               in_enddatetimestr ||chr(9)||
               log_request(in_reqtype,in_facility,in_custid,in_formatid,in_filepath,
                           in_when,in_loadno,in_orderid,in_shipid,l_userid,in_tablename,
                           in_columnname,in_filtercolumnname,in_company,in_warehouse,
                           in_begindatetimestr,in_enddatetimestr) ||chr(9);
      errno := zqm.send(que,l_msg);
    end if;
    if nvl(out_msg,'x') != 'NOCOMMIT' then
      commit;
    end if;

end impexp_request;

procedure impexp_request_queue
(in_queuename         in varchar2
,in_reqtype           in varchar2
,in_facility          in varchar2
,in_custid            in varchar2
,in_formatid          in varchar2
,in_filepath          in varchar2
,in_when              in varchar2
,in_loadno            in number
,in_orderid           in number
,in_shipid            in number
,in_userid            in varchar2
,in_tablename         in varchar2
,in_columnname        in varchar2
,in_filtercolumnname  in varchar2
,in_company           in varchar2
,in_warehouse         in varchar2
,in_begindatetimestr  in varchar2
,in_enddatetimestr    in varchar2
,out_errorno          in out number
,out_msg              in out varchar2)
is PRAGMA AUTONOMOUS_TRANSACTION;
errno number;
errmsg varchar2(255);
l_msg varchar2(1000);
que varchar2(12);
cnt integer;
impexp_traditional char(1);
impexp_table char(1);
l_userid varchar2(12);

begin
   begin
      select defaultvalue into impexp_traditional
         from systemdefaults
         where defaultid = 'IMPEXP_TRADITIONAL';
   exception when others then
      impexp_traditional := 'Y';
   end;

   begin
      select defaultvalue into impexp_table
         from systemdefaults
         where defaultid = 'IMPEXP_TABLE';
   exception when others then
      impexp_table := 'N';
   end;

   if impexp_table = 'Y' then
      begin
        insert into impexp_request(reqtype,facility,custid,formatid,filepath,
              when_to,loadno,orderid,shipid,userid,tablename,
              columnname,filtercolumnname,company,warehouse,
              begindatetimestr,enddatetimestr,requested)
        values (in_reqtype,in_facility,in_custid,in_formatid,in_filepath,
              in_when,in_loadno,in_orderid,in_shipid,in_userid,in_tablename,
              in_columnname,in_filtercolumnname,in_company,in_warehouse,
              in_begindatetimestr,in_enddatetimestr,sysdate);

      exception when others then
        zms.log_msg('IMPEXP', in_facility, in_custid,'IMPR: '||sqlerrm,'E',
                    'IMPEXP', errMsg);
      end;
   end if;
   if length(in_userid) > 12 then
      l_userid := 'IMPEXP';
   else
      l_userid := in_userid;
   end if;

   if impexp_traditional = 'Y' then
      que := nvl(in_queuename, IE_DEFAULT_QUEUE);
      cnt := 0;
      select count(1) into cnt
         from user_queues
         where name = upper(que);
      if nvl(cnt,0) = 0 then
         zms.log_msg('IMPEXP', in_facility, in_custid,'Queue '||que||' does not exist ',
                     'E', 'IMPEXP', errMsg);
         que := IE_DEFAULT_QUEUE;
      end if;
      l_msg := in_reqtype ||chr(9)||
               in_facility ||chr(9)||
               in_custid ||chr(9)||
               in_formatid ||chr(9)||
               in_filepath ||chr(9)||
               in_when ||chr(9)||
               in_loadno ||chr(9)||
               in_orderid ||chr(9)||
               in_shipid ||chr(9)||
               in_userid ||chr(9)||
               in_tablename ||chr(9)||
               in_columnname ||chr(9)||
               in_filtercolumnname ||chr(9)||
               in_company ||chr(9)||
               in_warehouse ||chr(9)||
               in_begindatetimestr ||chr(9)||
               in_enddatetimestr ||chr(9)||
               log_request(in_reqtype,in_facility,in_custid,in_formatid,in_filepath,
                           in_when,in_loadno,in_orderid,in_shipid,l_userid,in_tablename,
                           in_columnname,in_filtercolumnname,in_company,in_warehouse,
                           in_begindatetimestr,in_enddatetimestr) ||chr(9);
      errno := zqm.send(que,l_msg);
   end if;
    commit;

end impexp_request_queue;

procedure impexp_receive_msg
(in_queuename         in varchar2
,in_instance          in varchar2
,out_reqtype          in out varchar2
,out_facility         in out varchar2
,out_custid           in out varchar2
,out_formatid         in out varchar2
,out_filepath         in out varchar2
,out_when             in out varchar2
,out_loadno           in out  number
,out_orderid          in out  number
,out_shipid           in out  number
,out_userid           in out varchar2
,out_tablename        in out varchar2
,out_columnname       in out varchar2
,out_filtercolumnname in out varchar2
,out_company          in out varchar2
,out_warehouse          in out varchar2
,out_begindatetimestr in out varchar2
,out_enddatetimestr   in out varchar2
,out_logseq           in out number
,out_errorno          in out number
,out_msg              in out varchar2)
is PRAGMA AUTONOMOUS_TRANSACTION;
errno number;

status integer;
trans varchar2(20);
msg varchar2(2000);
errMsg varchar2(256);
que varchar2(12);
cntRows pls_integer;
begin

   if in_instance is not null then
      select count(1) into cntRows
        from impexp_instances
       where code = in_instance
         and abbrev = 'Y';
      if cntRows > 0 then
         trans := null;
         out_reqtype := 'T';
         out_msg := 'OKAY';
         commit;
         return;
      end if;
   end if;

    que := nvl(in_queuename, IE_DEFAULT_QUEUE);

    out_msg := '';
    out_errorno := 0;

   status := zqm.receive(in_queuename,null,10,zqm.DQ_REMOVE, trans, msg);

    if status < 0 then
      -- zut.prt('MS_Q WAIT timed out status:'||status);
        trans := null;
        out_reqtype := 'TIME';
        out_msg := 'OKAY';
        commit;
        return;
    else
        out_reqtype := nvl(get_field(msg,1),'(none)');
        out_facility := nvl(get_field(msg,2),'(none)');
        out_custid := nvl(get_field(msg,3),'(none)');
        out_formatid := nvl(get_field(msg,4),'(none)');
        out_filepath := nvl(get_field(msg,5),'(none)');
        out_when := nvl(get_field(msg,6),'(none)');
        out_loadno := nvl(get_field(msg,7),0);
        out_orderid := nvl(get_field(msg,8),0);
        out_shipid := nvl(get_field(msg,9),0);
        out_userid := nvl(get_field(msg,10),'(none)');
        out_tablename := nvl(get_field(msg,11),'(none)');
        out_columnname := nvl(get_field(msg,12),'(none)');
        out_filtercolumnname := nvl(get_field(msg,13),'(none)');
        out_company := nvl(get_field(msg,14),'(none)');
        out_warehouse := nvl(get_field(msg,15),'(none)');
        out_begindatetimestr := nvl(get_field(msg,16),'(none)');
        out_enddatetimestr := nvl(get_field(msg,17),'(none)');
        out_logseq:= nvl(get_field(msg,18),0);
    end if;

    commit;

    return;

end impexp_receive_msg;

procedure update_impexp_log_start
(in_logseq            in number
,in_instance          in varchar2
,out_errorno          in out number
,out_msg              in out varchar2)
is PRAGMA AUTONOMOUS_TRANSACTION;
begin
   update impexp_log
      set ie_instance = in_instance,
          ie_start = current_timestamp
     where logseq = in_logseq;
   commit;
exception when others then
   rollback;
end update_impexp_log_start;

procedure impexp_log_manual_import
(in_logseq            in number
,in_instance          in varchar2
,in_formatid          in varchar2
,in_filepath          in varchar2
,in_userid            in varchar2
,out_errorno          in out number
,out_msg              in out varchar2)
is PRAGMA AUTONOMOUS_TRANSACTION;
begin
   if length(in_userid) > 12 then
      insert into impexp_log
         (logseq,reqtype,formatid,filepath,when_to,loadno,
          orderid,shipid,userid,
          requested,rerequested, ie_instance, ie_start)
      values
         (in_logseq,'I',in_formatid,in_filepath,'NOW',0,
          0,0,'IMPEXP',
          current_timestamp,'N',
          in_instance, current_timestamp);
   else
      insert into impexp_log
         (logseq,reqtype,formatid,filepath,when_to,loadno,
          orderid,shipid,userid,
          requested,rerequested, ie_instance, ie_start)
      values
         (in_logseq,'I',in_formatid,in_filepath,'NOW',0,
          0,0,in_userid,
          current_timestamp,'N',
          in_instance, current_timestamp);
   end if;
   commit;
EXCEPTION WHEN OTHERS THEN
   rollback;
end impexp_log_manual_import;


procedure update_impexp_log_finish
(in_logseq            in number
,out_errorno          in out number
,out_msg              in out varchar2)
is PRAGMA AUTONOMOUS_TRANSACTION;
begin
   update impexp_log
      set ie_finish = current_timestamp
     where logseq = in_logseq;
   commit;
exception when others then
   rollback;
end update_impexp_log_finish;

procedure insert_impexp_log_detail
(in_logseq            in number
,in_logtext           in varchar2
,out_errorno          in out number
,out_msg              in out varchar2)
is PRAGMA AUTONOMOUS_TRANSACTION;
begin
   insert into impexp_log_detail
      (logseq, created, logtext)
   values
      (in_logseq, current_timestamp, in_logtext);
   commit;
exception when others then
   rollback;
end insert_impexp_log_detail;

procedure rerequest_impexp_log
(in_instance          in varchar2
,out_errorno          in out number
,out_msg              in out varchar2)
is
   intErrorno integer;
   lMsg varchar2(255);
   procedure update_impexp_log
   (in_logseq            in number)
   is PRAGMA AUTONOMOUS_TRANSACTION;
   begin
      update impexp_log
         set rerequested = 'Y'
       where logseq = in_logseq;
      commit;
   exception when others then
      rollback;
   end update_impexp_log;

begin
   for il in (select * from impexp_log
               where ie_instance = in_instance
                 and requested < current_timestamp - 1/24
                 and ie_finish is null
                 and rerequested = 'N'
                 and reqtype = 'E') loop
      ziem.impexp_request(
        il.reqtype,
        il.facility,
        il.custid,
        il.formatid,
        il.filepath,
        il.when_to,
        il.loadno,
        il.orderid,
        il.shipid,
        il.userid,
        il.tablename,
        il.columnname,
        il.filtercolumnname,
        il.company,
        il.warehouse,
        il.begindatetimestr,
        il.enddatetimestr,
        intErrorno,out_msg);
      if nvl(intErrorno,0) = 0 then
         insert_impexp_log_detail(il.logseq, 'I/E request resubmitted', intErrorno, lMsg );
         update_impexp_log(il.logseq);
      end if;
   end loop;
exception when others then
   null;
end rerequest_impexp_log;

procedure resequence_impexp_chunkinc
(in_definc            in number
,in_lineinc           in number
,out_errorno          out number
,out_msg              out varchar2)
is
new_chunkinc integer;
begin
out_errorno := 0;
out_msg := 'OKAY';
new_chunkinc := 0;
for IC in (select chunkinc from impexp_chunks where definc = in_definc and lineinc = in_lineinc) loop
   new_chunkinc := new_chunkinc + 1;
   if IC.chunkinc != new_chunkinc then
      update impexp_chunks
         set chunkinc = new_chunkinc
       where definc = in_definc
         and lineinc = in_lineinc
         and chunkinc = IC.chunkinc;
   end if;
end loop;

exception when others then
  out_msg := 'ric '|| sqlerrm;
  out_errorno := sqlcode;

end resequence_impexp_chunkinc;

procedure add_instance
(in_instance          in varchar2
,out_errorno          in out number
,out_msg              in out varchar2)
is
begin
  out_msg := 'OKAY';
  out_errorno := 0;
  begin
     insert into impexp_instances
        (code, descr, abbrev, dtlupdate, lastuser, lastupdate)
      values
        (in_instance, 'instance ' ||in_instance, 'N', 'Y', in_instance, sysdate);
  exception when DUP_VAL_ON_INDEX then
     update impexp_instances
        set abbrev = 'N',
            lastupdate = sysdate
      where code = in_instance;
  end;

exception when others then
  out_msg := 'ziemai '|| sqlerrm;
  out_errorno := sqlcode;
end add_instance;
procedure delete_instance
(in_instance          in varchar2
,out_errorno          in out number
,out_msg              in out varchar2)
is
begin
  out_msg := 'OKAY';
  out_errorno := 0;
  begin
     delete impexp_instances
      where code = in_instance;
  exception when no_data_found then
    null;
  end;
exception when others then
  out_msg := 'ziemai '|| sqlerrm;
  out_errorno := sqlcode;
end delete_instance;
END impexpmsg;
/
show error package body impexpmsg;
exit;