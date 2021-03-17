create or replace PACKAGE BODY alps.zjob
IS
--
-- $Id$
--

----------------------------------------------------------------------
--
-- start_wave_plan
--
----------------------------------------------------------------------
PROCEDURE start_wave_plan
(
    in_facility IN varchar2,
    in_custid   IN varchar2,
    in_wave_prefix IN varchar2,
    out_msg     OUT varchar2
)
IS
cmd varchar2(1000);

CURSOR C_JOB
IS
SELECT *
  FROM user_jobs
 WHERE what = cmd;

JB user_jobs%rowtype;


jobno integer;
BEGIN
    out_msg := 'OKAY';

    cmd := 'zcm.auto_wave_plan('''
    ||in_facility||''','''
    ||in_custid||''','''
    ||in_wave_prefix||''');';


    -- TEST JOB cmd := 'dbms_lock.sleep(20);';


    JB := null;

    OPEN C_JOB;
    FETCH C_JOB into JB;
    CLOSE C_JOB;

    if JB.job is null then
        dbms_job.submit(jobno, cmd, sysdate);
    else
        Jobno := JB.job;
        out_msg := 'Job is already running as job number:'||Jobno;
    end if;



EXCEPTION WHEN OTHERS THEN
  out_msg := substr(sqlerrm,1,80);
END start_wave_plan;



----------------------------------------------------------------------
--
-- start_daily_billing
--
----------------------------------------------------------------------
PROCEDURE start_daily_billing
IS

CURSOR C_JOB
IS
SELECT *
  FROM user_jobs
 WHERE what = zbill.daily_billing;

JB user_jobs%rowtype;


jobno   integer;

CURSOR C_TIME
IS
select substr(defaultvalue,1,4)
  from systemdefaults
 where defaultid = 'DAILY_BILLING_RUNTIME';

tm varchar2(4);
hh integer;
mi integer;

dt date;
l_msg varchar2(255);

BEGIN

    JB := null;
    OPEN C_JOB;
    FETCH C_JOB into JB;
    CLOSE C_JOB;

    if JB.job is not null then
        zms.log_autonomous_msg('DAILYJOB', null, null,
            'Start Daily Billing job already exists as number: ' || JB.job,
            'I', 'DAILYJOB', l_msg);
        dbms_job.broken(JB.job,false);
        return;
    end if;

    TM := null;
    OPEN C_TIME;
    FETCH C_TIME into TM;
    CLOSE C_TIME;

    if TM is null then
        TM := '0010';
    else
      begin
        TM := to_char(to_number(TM),'FM0009');
      exception when others then
        TM := '0010';
      end;
    end if;

    hh := to_number(substr(tm,1,2));
    mi := to_number(substr(tm,3,2));

    -- Next date is tomorrow at the appointed time, and the interval is 24 hrs.
    dbms_job.submit(Jobno,'zbs.daily_billing_job;',
        trunc(sysdate+1) + hh/24 + mi/1440,
        'zbut.next_daily_billing');

commit;


END start_daily_billing;

----------------------------------------------------------------------
--
-- stop_daily_billing
--
----------------------------------------------------------------------
PROCEDURE stop_daily_billing
IS

CURSOR C_JOB
IS
SELECT *
  FROM user_jobs
 WHERE what = zbill.daily_billing;

JB user_jobs%rowtype;

BEGIN

    JB := null;
    OPEN C_JOB;
    FETCH C_JOB into JB;
    CLOSE C_JOB;

    if JB.job is not null then
        dbms_job.remove(JB.job);

    end if;

    commit;


END stop_daily_billing;


----------------------------------------------------------------------
--
-- set_daily_billing - Sets the daily billing next interval time
--
----------------------------------------------------------------------
PROCEDURE set_daily_billing
IS

CURSOR C_JOB
IS
SELECT *
  FROM user_jobs
 WHERE what = zbill.daily_billing;

JB user_jobs%rowtype;


CURSOR C_TIME
IS
select substr(defaultvalue,1,4)
  from systemdefaults
 where defaultid = 'DAILY_BILLING_RUNTIME';

tm varchar2(4);
hh integer;
mi integer;

dt date;

BEGIN

-- Determine Next runtime

    TM := null;
    OPEN C_TIME;
    FETCH C_TIME into TM;
    CLOSE C_TIME;

    if TM is null then
        TM := '0010';
    else
      begin
        TM := to_char(to_number(TM),'FM0009');
      exception when others then
        TM := '0010';
      end;
    end if;

    hh := to_number(substr(tm,1,2));
    mi := to_number(substr(tm,3,2));

    JB := null;
    OPEN C_JOB;
    FETCH C_JOB into JB;
    CLOSE C_JOB;

    if JB.job is not null then
        dbms_job.next_date(JB.job, trunc(sysdate + 1) + hh/24 + mi/1440);
        dbms_job.interval(JB.job, 'trunc(sysdate+1)');
    end if;

commit;


END set_daily_billing;

----------------------------------------------------------------------
--
-- start_alert_process
--
----------------------------------------------------------------------
PROCEDURE start_alert_process
IS

CURSOR C_JOB
IS
SELECT *
  FROM user_jobs
 WHERE what = alert_job_name;

JB user_jobs%rowtype;

iJob integer;

BEGIN
    iJob := 0;

    JB := null;

    OPEN C_JOB;
    FETCH C_JOB into JB;
    CLOSE C_JOB;

    if JB.job is null then
        dbms_job.submit(iJob,alert_job_name,trunc(sysdate+1),'sysdate+1/72000');
    else
        iJob := JB.job;
    end if;

    dbms_job.broken(iJob,false);
    dbms_job.next_date(iJob,sysdate);

    commit;



END start_alert_process;

----------------------------------------------------------------------
--
-- stop_alert_process
--
----------------------------------------------------------------------
PROCEDURE stop_alert_process
IS

CURSOR C_JOB
IS
SELECT *
  FROM user_jobs
 WHERE what = alert_job_name;

JB user_jobs%rowtype;
errno number;

BEGIN

    JB := null;
    OPEN C_JOB;
    FETCH C_JOB into JB;
    CLOSE C_JOB;

    if JB.job is not null then
        dbms_job.remove(JB.job);
--        errno := zqm.send('alerts','STOP');
    end if;

    commit;


END stop_alert_process;

----------------------------------------------------------------------
--
-- start_daily_jobs
--
----------------------------------------------------------------------
PROCEDURE start_daily_jobs
IS

CURSOR C_JOB
IS
SELECT *
  FROM user_jobs
 WHERE what = zjob.daily_jobs_name;

JB user_jobs%rowtype;


jobno   integer;

CURSOR C_TIME
IS
select substr(defaultvalue,1,4)
  from systemdefaults
 where defaultid = 'DAILY_BILLING_RUNTIME';

tm varchar2(4);
hh integer;
mi integer;

dt date;
l_msg varchar2(255);

BEGIN

    JB := null;
    OPEN C_JOB;
    FETCH C_JOB into JB;
    CLOSE C_JOB;

    if JB.job is not null then
        zms.log_autonomous_msg('DAILYJOB', null, null,
            'Start Daily Jobs already exists as number: ' || JB.job,
            'I', 'DAILYJOB', l_msg);
        dbms_job.broken(JB.job,false);
        return;
    end if;

    TM := null;
    OPEN C_TIME;
    FETCH C_TIME into TM;
    CLOSE C_TIME;

    if TM is null then
        TM := '0010';
    else
      begin
        TM := to_char(to_number(TM),'FM0009');
      exception when others then
        TM := '0010';
      end;
    end if;

    hh := to_number(substr(tm,1,2));
    mi := to_number(substr(tm,3,2) + 30);

    -- Next date is tomorrow at the appointed time, and the interval is 24 hrs.
    dbms_job.submit(Jobno,zjob.daily_jobs_name,
        trunc(sysdate+1) + hh/24 + mi/1440,
        'zbut.next_daily_billing + 30/1440');


commit;


END start_daily_jobs;

----------------------------------------------------------------------
--
-- stop_daily_jobs
--
----------------------------------------------------------------------
PROCEDURE stop_daily_jobs
IS

CURSOR C_JOB
IS
SELECT *
  FROM user_jobs
 WHERE what = zjob.daily_jobs_name;

JB user_jobs%rowtype;

BEGIN

    JB := null;
    OPEN C_JOB;
    FETCH C_JOB into JB;
    CLOSE C_JOB;

    if JB.job is not null then
        dbms_job.remove(JB.job);

    end if;

    commit;


END stop_daily_jobs;

----------------------------------------------------------------------
--
-- no_expiration_custids
--
----------------------------------------------------------------------

procedure no_expiration_custids(out_custids out varchar2)
is
aDefaultValue systemdefaults.defaultvalue%type;

str systemdefaults.defaultvalue%type;
begin
   out_custids := null;

   begin
      select defaultvalue into aDefaultValue
        from systemdefaults
       where defaultid = 'EXPIRATIONNORUNCUSTIDS';
   exception when no_data_found then
      aDefaultValue := null;
   end;
   if aDefaultValue is null then
      return;
   end if;
   out_custids := ''''||replace(aDefaultValue, ',' , ''',''')||'''';

end no_expiration_custids;

procedure nonstandard_string_parse
(in_string in varchar2
,out_var1 out varchar2
,out_var2 out varchar2
,out_var3 out varchar2
,out_var4 out varchar2
,out_var5 out varchar2
,out_var6 out varchar2)
is
tcur pls_integer;
tpos pls_integer;
tcnt pls_integer;
str systemdefaults.defaultvalue%type;

begin
   out_var1 := null;
   out_var2 := null;
   out_var3 := null;
   out_var4 := null;
   out_var5 := null;
   out_var6 := null;
   if in_string is null then
      return;
   end if;

   tcur := 1;

   tpos := instr(in_string, ',', tcur);
   if tpos = 0 then
      out_var1 := substr(in_string, tcur);
      return;
   end if;
   tcnt := tpos - tcur;
   out_var1 := substr(in_string, tcur, tcnt);

   tcur := tpos + 1;
   tpos := instr(in_string, ',', tcur);
   if tpos = 0 then
      out_var2 := substr(in_string, tcur);
      return;
   end if;
   tcnt := tpos - tcur;
   out_var2 := substr(in_string, tcur, tcnt);

   tcur := tpos + 1;
   tpos := instr(in_string, ',', tcur);
   if tpos = 0 then
      out_var3 := substr(in_string, tcur);
      return;
   end if;
   tcnt := tpos - tcur;
   out_var3 := substr(in_string, tcur, tcnt);

   tcur := tpos + 1;
   tpos := instr(in_string, ',', tcur);
   if tpos = 0 then
      out_var4 := substr(in_string, tcur);
      return;
   end if;
   tcnt := tpos - tcur;
   out_var4 := substr(in_string, tcur, tcnt);

   tcur := tpos + 1;
   tpos := instr(in_string, ',', tcur);
   if tpos = 0 then
      out_var5 := substr(in_string, tcur);
      return;
   end if;
   tcnt := tpos - tcur;
   out_var5 := substr(in_string, tcur, tcnt);

   tcur := tpos + 1;
   tpos := instr(in_string, ',', tcur);
   if tpos = 0 then
      out_var6 := substr(in_string, tcur);
      return;
   end if;
   tcnt := tpos - tcur;
   out_var6 := substr(in_string, tcur, tcnt);

end nonstandard_string_parse;
----------------------------------------------------------------------
--
-- nonstandard_expiration_params
--
----------------------------------------------------------------------

procedure nonstandard_expiration_params
(out_job1 out varchar2
,out_job2 out varchar2
,out_job3 out varchar2
,out_job4 out varchar2
,out_job5 out varchar2
,out_job6 out varchar2
,out_custid1 out varchar2
,out_custid2 out varchar2
,out_custid3 out varchar2
,out_custid4 out varchar2
,out_custid5 out varchar2
,out_custid6 out varchar2)
is
aDefaultValue systemdefaults.defaultvalue%type;

str systemdefaults.defaultvalue%type;
begin
   out_job1 := null;
   out_job2 := null;
   out_job3 := null;
   out_job4 := null;
   out_job5 := null;
   out_job6 := null;
   out_custid1 := null;
   out_custid2 := null;
   out_custid3 := null;
   out_custid4 := null;
   out_custid5 := null;
   out_custid6 := null;
   begin
      select defaultvalue into aDefaultValue
        from systemdefaults
       where defaultid = 'EXPIRATIONNORUNPROCS';
   exception when no_data_found then
      return;
   end;
   nonstandard_string_parse(aDefaultValue, out_job1, out_job2, out_job3,
                           out_job4, out_job5, out_job6);

   begin
      select defaultvalue into aDefaultValue
        from systemdefaults
       where defaultid = 'EXPIRATIONNORUNCUSTIDS';
   exception when no_data_found then
      return;
   end;
   nonstandard_string_parse(aDefaultValue, out_custid1, out_custid2, out_custid3,
                           out_custid4, out_custid5, out_custid6);


end nonstandard_expiration_params;


----------------------------------------------------------------------
--
-- daily_recent_order
--
----------------------------------------------------------------------
PROCEDURE daily_recent_order
IS

cursor curOrderHdr is
  select rowid,custid,orderstatus,statusupdate
    from orderhdr
   where recent_order_id like 'Y%';

cursor curCustomer(in_custid varchar2) is
  select nvl(recent_order_days,30) as recent_order_days
    from customer
   where custid = in_custid;
cu curCustomer%rowtype;

cntTot integer;
cntOky integer;
strCustId customer.custid%type;
strMsg varchar2(255);

BEGIN

    cntTot := 0;
    cntOky := 0;
    strCustid := 'x';

    zms.log_autonomous_msg('DAILYJOB', null, null,
            'Begin Recent Order Update',
            'I', 'DAILYJOB', strMsg);

    for oh in curOrderHdr
    loop

      cntTot := cntTot + 1;

      if oh.orderstatus in ('9','X','R') then

        if strCustid != oh.custid then
          cu.recent_order_days := 30;
          open curCustomer(oh.custid);
          fetch curCustomer into cu;
          close curCustomer;
          strCustId := oh.custid;
        end if;

        if oh.statusupdate < sysdate - cu.recent_order_days then

          update orderhdr
             set recent_order_id = null
           where rowid = oh.rowid;

          cntOky := cntOky + 1;

          if mod(cntTot,1000) = 0 then
            commit;
          end if;

        end if;

      end if;

    end loop;

    commit;

    zms.log_autonomous_msg('DAILYJOB', null, null,
            'End Recent Order Update (Processed: ' || cntTot || ' Updated: ' || cntOky || ')',
            'I', 'DAILYJOB', strMsg);


EXCEPTION WHEN OTHERS THEN
  begin
    zms.log_autonomous_msg('DAILYJOB', null, null,
            'Recent Order Update Error:'||sqlerrm,
            'E', 'DAILYJOB', strMsg);
  exception when others then
    null;
  end;
END daily_recent_order;

----------------------------------------------------------------------
--
-- daily_recent_load
--
----------------------------------------------------------------------
PROCEDURE daily_recent_load
IS

cursor curLoads is
  select rowid,loadno, loadstatus,statusupdate
    from loads
   where recent_loadno >= 0;

cursor curCustomer(in_loadno number) is
  select max(nvl(recent_order_days,30)) as recent_order_days
    from customer
   where custid in
 (select custid
    from orderhdr
   where loadno = in_loadno) ;
cu curCustomer%rowtype;

cntTot integer;
cntOky integer;
strMsg varchar2(255);

BEGIN

    cntTot := 0;
    cntOky := 0;

    zms.log_autonomous_msg('DAILYJOB', null, null,
            'Begin Recent LoadNo Update',
            'I', 'DAILYJOB', strMsg);

    for ld in curLoads
    loop

      cntTot := cntTot + 1;

      if ld.loadstatus in ('9','X','R') then

        cu.recent_order_days := 30;
        open curCustomer(ld.loadno);
        fetch curCustomer into cu;
        close curCustomer;

        if ld.statusupdate < sysdate - cu.recent_order_days then

          update loads
             set recent_loadno = null
           where rowid = ld.rowid;

          cntOky := cntOky + 1;

          if mod(cntTot,1000) = 0 then
            commit;
          end if;

        end if;

      end if;

    end loop;

    commit;

    zms.log_autonomous_msg('DAILYJOB', null, null,
            'End Recent Load Update (Processed: ' || cntTot
                    || ' Updated: ' || cntOky || ')',
            'I', 'DAILYJOB', strMsg);



EXCEPTION WHEN OTHERS THEN
  begin
    zms.log_autonomous_msg('DAILYJOB', null, null,
            'Recent Load Update Error:'||sqlerrm,
            'E', 'DAILYJOB', strMsg);
  exception when others then
    null;
  end;
END daily_recent_load;


----------------------------------------------------------------------
--
-- daily_expiration
--
----------------------------------------------------------------------
PROCEDURE daily_expiration
IS


cursor curExpiredPlates(in_invstatus varchar2) is
  select lpid,
         custid,
         item,
         nvl(inventoryclass,'RG') as inventoryclass,
         invstatus,
         lotnumber,
         serialnumber,
         useritem1,
         useritem2,
         useritem3,
         location,
         expirationdate,
         manufacturedate,
         unitofmeasure,
         quantity as qty,
         facility,
         nvl(loadno,0) as loadno,
         nvl(stopno,0) as stopno,
         nvl(shipno,0) as shipno,
         orderid,
         shipid,
         type,
         parentlpid,
         weight,
         controlnumber,
         adjreason,
         anvdate
    from plate
   where trunc(expirationdate) < trunc(sysdate)
     and type = 'PA'
     and invstatus != in_invstatus;

CURSOR C_SD
IS
select upper(substr(defaultvalue,1,2)) invstatus
  from systemdefaults
 where defaultid = 'EXPIRATIONDAILYJOB';

SD C_SD%rowtype;

out_msg varchar2(255);
out_errorno integer;
out_adjrowid1 varchar2(255);
out_adjrowid2 varchar2(255);
cntRows integer;
cntErr integer;
qtyTot integer;
qtyErr integer;
qtyOky integer;

cntTot integer;
cntOky integer;
strMsg varchar2(255);



BEGIN

-- First check if we are to do this
    SD := null;
    OPEN C_SD;
    FETCH C_SD into SD;
    CLOSE C_SD;

    if SD.invstatus is null then
        return;
    end if;

    zms.log_autonomous_msg('DAILYJOB', null, null,
            'Begin Expiration Process',
            'I', 'DAILYJOB', strMsg);


    cntTot := 0;
    cntErr := 0;
    cntOky := 0;
    qtyTot := 0;
    qtyErr := 0;
    qtyOky := 0;

    for pl in curExpiredPlates(SD.invstatus)
    loop

      cntTot := cntTot + 1;
      qtyTot := qtyTot + pl.qty;

      zia.inventory_adjustment
      (pl.lpid
      ,pl.custid
      ,pl.item
      ,pl.inventoryclass
      ,SD.invstatus     --'EX'
      ,pl.lotnumber
      ,pl.serialnumber
      ,pl.useritem1
      ,pl.useritem2
      ,pl.useritem3
      ,pl.location
      ,pl.expirationdate
      ,pl.qty
      ,pl.custid
      ,pl.item
      ,pl.inventoryclass
      ,pl.invstatus
      ,pl.lotnumber
      ,pl.serialnumber
      ,pl.useritem1
      ,pl.useritem2
      ,pl.useritem3
      ,pl.location
      ,pl.expirationdate
      ,pl.qty
      ,pl.facility
      ,'EX'
      ,'EXPRUN'
      ,'EP'
      ,pl.weight
      ,pl.weight
      ,pl.manufacturedate
      ,pl.manufacturedate
      ,pl.anvdate
      ,pl.anvdate
      ,out_adjrowid1
      ,out_adjrowid2
      ,out_errorno
      ,out_msg);

      if out_errorno != 0 then
        rollback;
        cntErr := cntErr + 1;
        qtyErr := qtyErr + pl.qty;
        zms.log_autonomous_msg('EXPRUN', null, null,
            pl.lpid || ' ' || out_msg,
            'E', 'DAILYJOB', strMsg);
      else
        commit;
        cntOky := cntOky + 1;
        qtyOky := qtyOky + pl.qty;
        if out_adjrowid1 is not null then
           zim6.check_for_adj_interface(out_adjrowid1,out_errorno,out_msg);
        end if;
        if out_adjrowid2 is not null then
           zim6.check_for_adj_interface(out_adjrowid2,out_errorno,out_msg);
        end if;
      end if;

    end loop;

--zut.prt('total count: ' || cntTot || ' total quantity: ' || qtyTot);
--zut.prt('error count: ' || cntErr || ' error quantity: ' || qtyErr);
--zut.prt('okay  count: ' || cntOky || ' okay  quantity: ' || qtyOky);


    zms.log_autonomous_msg('DAILYJOB', null, null,
            'End Expiration Process (Processed: ' || cntTot
                    || ' Updated: ' || cntOky || ')',
            'I', 'DAILYJOB', strMsg);



EXCEPTION WHEN OTHERS THEN
  begin
    zms.log_autonomous_msg('DAILYJOB', null, null,
            'Expiration Process Error:'||sqlerrm,
            'E', 'DAILYJOB', strMsg);
  exception when others then
    null;
  end;
END daily_expiration;

PROCEDURE daily_ranking
IS
   strMsg varchar2(255);
BEGIN
   for fac in (select facility from facility) loop
      zloc.rank_locations(fac.facility);
   end loop;
EXCEPTION WHEN OTHERS THEN
  begin
    zms.log_autonomous_msg('DAILYJOB', null, null,
            'daily_ranking: ' ||sqlerrm,
            'E', 'DAILYJOB', strMsg);
  exception when others then
    null;
  end;
END daily_ranking;

PROCEDURE daily_appmsgs_purge
IS

cursor curPurgable is
  select rowid
    from appmsgs
   where created < sysdate - 90;

type appmsgs_tbl_type is table of rowid;
appmsgs_tbl appmsgs_tbl_type;

l_appmsg varchar2(255);
l_msg varchar2(255);
l_max_deletions pls_integer := 100000;
l_max_run_time number := 1/24;  -- limit run time to 1 hour
l_elapsed_time number;
l_begin_time date;
l_tot_deletions pls_integer := 0;
l_rowcount pls_integer := 0;
l_run_time_exceeded boolean := false;

BEGIN

l_begin_time := sysdate;

zms.log_autonomous_msg('DAILYJOB', null, null,
        'Begin appmsgs purge',
        'I', 'DAILYJOB', l_appmsg);

open curPurgable;
loop

  fetch curPurgable bulk collect into appmsgs_tbl limit 10000;

  if appmsgs_tbl.count = 0 then
    exit;
  end if;

  forall i in appmsgs_tbl.first .. appmsgs_tbl.last
    delete appmsgs
     where rowid = appmsgs_tbl(i);

  l_rowcount := sql%rowcount;
  l_tot_deletions := l_tot_deletions + l_rowcount;

  commit;

  l_elapsed_time := sysdate - l_begin_time;
  if l_elapsed_time >= l_max_run_time then
    l_run_time_exceeded := true;
    goto end_of_purge;
  end if;

  if l_tot_deletions >= l_max_deletions then
    goto end_of_purge;
  end if;

  exit when curPurgable%notfound;

end loop;

<< end_of_purge >>

if curPurgable%isopen then
  close curPurgable;
end if;

l_msg := 'End appmsgs purge. Deletions: ' || l_tot_deletions;

if l_run_time_exceeded then
  l_msg := l_msg || ' (run time was exceeded)';
end if;

zms.log_autonomous_msg('DAILYJOB', null, null,
        l_msg,
        'I', 'DAILYJOB', l_appmsg);

EXCEPTION WHEN OTHERS THEN
  begin
    zms.log_autonomous_msg('DAILYJOB', null, null,
            'appmsgs purge: '||sqlerrm,
            'E', 'DAILYJOB', l_appmsg);
  exception when others then
    null;
  end;
END daily_appmsgs_purge;

PROCEDURE daily_jobs
IS
strMsg varchar2(200);
job1 systemdefaults.defaultvalue%type;
job2 systemdefaults.defaultvalue%type;
job3 systemdefaults.defaultvalue%type;
job4 systemdefaults.defaultvalue%type;
job5 systemdefaults.defaultvalue%type;
job6 systemdefaults.defaultvalue%type;
custid1 systemdefaults.defaultvalue%type;
custid2 systemdefaults.defaultvalue%type;
custid3 systemdefaults.defaultvalue%type;
custid4 systemdefaults.defaultvalue%type;
custid5 systemdefaults.defaultvalue%type;
custid6 systemdefaults.defaultvalue%type;

procedure do_job
(in_job varchar2
,in_custid varchar2)
is
cmdSql varchar2(2000);
begin
   cmdSql := 'BEGIN ' || job1 || '(:a); END;';
   --zut.prt('cmdSql ' || cmdSql);
   begin
      execute immediate cmdSql using in_custid;
   exception when others then
         zms.log_autonomous_msg('DAILYJOB', null, null,
       'Begin PEOPLESKHEXPIRATION Expiration Process run error ' || in_job || ': '||sqlerrm || ' ' || cmdSql,
       'I', 'DAILYJOB', strMsg);
   end;

end do_job;
BEGIN
    daily_recent_order;
    daily_recent_load;
    daily_expiration;
    daily_ranking;
    daily_appmsgs_purge;
    import204_purge;
    custitem_import_changes_purge;
    zut.check_data_file_usage;
/* keep nonstandard last as it returns when there is nothing to do */
    nonstandard_expiration_params(job1,job2,job3,job4,job5,job6,
                                  custid1,custid2,custid3,custid4,custid5,custid6);

    if job1 is not null and
       custid1 is not null then
       do_job(job1, custid1);
    else
       return;
    end if;

    if job2 is not null and
       custid2 is not null then
       do_job(job2, custid2);
    else
       return;
    end if;

    if job3 is not null and
       custid3 is not null then
       do_job(job3, custid3);
    else
       return;
    end if;

    if job4 is not null and
       custid4 is not null then
       do_job(job4, custid4);
    else
       return;
    end if;

    if job5 is not null and
       custid5 is not null then
       do_job(job5, custid5);
    else
       return;
    end if;

    if job6 is not null and
       custid6 is not null then
       do_job(job6, custid6);
    end if;


EXCEPTION WHEN OTHERS THEN
  begin
    zms.log_autonomous_msg('DAILYJOB', null, null,
            'Recent Load Update Error:'||sqlerrm,
            'E', 'DAILYJOB', strMsg);
  exception when others then
    null;
  end;
END;

PROCEDURE start_pi_updates
(
    in_id       IN number,
    in_type     IN varchar2,
    in_user     IN varchar2,
    out_msg     OUT varchar2
)
IS
cmd varchar2(1000);

CURSOR C_JOB(in_job_string varchar2)
IS
SELECT *
  FROM user_jobs
 WHERE what like in_job_string || '%';

JB user_jobs%rowtype;
l_job_string varchar(255);

jobno integer;
BEGIN

-- call pi routine with validate-only option on
   zpi.complete_phinv_request(in_id, in_type, in_user, 'Y', out_msg);

   if substr(out_msg,1,4) != 'OKAY' then
     return;
   end if;

-- if validation passes then submit the actual update request
    cmd := 'declare out_msg varchar2(255); begin zpi.complete_phinv_request('
    ||in_id||','''
    ||in_type||''','''
    ||in_user||''','''
    ||'N'||''','
    ||'out_msg); end;';

    l_job_string := substr(cmd,1,instr(cmd,','));

    OPEN C_JOB(l_job_string);
    FETCH C_JOB into JB;
    CLOSE C_JOB;

    if JB.job is null then
        dbms_job.submit(jobno, cmd, sysdate);
        if in_type = 'COMPLETE' then
          out_msg := 'OKAY-Physical Inventory Update has been submitted';
        else
          out_msg := 'OKAY-Physical Inventory Cancel has been submitted';
        end if;
    else
        Jobno := JB.job;
        out_msg := 'Physical Inventory Process is already running as job number:'||Jobno;
    end if;

EXCEPTION WHEN OTHERS THEN
  out_msg := substr(sqlerrm,1,255);
END start_pi_updates;

PROCEDURE start_late_trailer_check
IS

CURSOR C_JOB
IS
SELECT *
  FROM user_jobs
 WHERE what = 'zyd.late_trailer_check;';

JB user_jobs%rowtype;


jobno   integer;
l_msg varchar2(255);

begin

JB := null;
OPEN C_JOB;
FETCH C_JOB into JB;
CLOSE C_JOB;

if JB.job is not null then
  zms.log_autonomous_msg('DAILYJOB', null, null,
      'Start Late Trailer Check job already exists as number: ' || JB.job,
      'I', 'DAILYJOB', l_msg);
  dbms_job.broken(JB.job,false);
  commit;
  return;
end if;

dbms_job.submit(Jobno,'zyd.late_trailer_check;',
                trunc(sysdate+1) + 5/1440, 'sysdate + 1');

commit;

end start_late_trailer_check;

PROCEDURE stop_late_trailer_check
IS

CURSOR C_JOB
IS
SELECT *
  FROM user_jobs
 WHERE what = 'zyd.late_trailer_check;';

JB user_jobs%rowtype;
l_msg varchar2(255);

BEGIN

JB := null;
OPEN C_JOB;
FETCH C_JOB into JB;
CLOSE C_JOB;

if JB.job is not null then
  dbms_job.remove(JB.job);
else
  zms.log_autonomous_msg('DAILYJOB', null, null,
      'The late_trailer_check job is already stopped.',
      'I', 'DAILYJOB', l_msg);
end if;

commit;

END stop_late_trailer_check;

----------------------------------------------------------------------
--
-- custitem import changes purge
--
----------------------------------------------------------------------

PROCEDURE custitem_import_changes_purge
IS

cursor curcustitem_import_changes is
  select rowid
    from custitem_import_changes
   where lastupdate < systimestamp - 31;


type rowid_tbl_type is table of rowid;
rowid_tbl rowid_tbl_type;

l_appmsg varchar2(255);
l_msg varchar2(255);
l_max_deletions pls_integer := 1000000;
l_max_run_time number := 1/24;  -- limit run time to 1 hour per table
l_elapsed_time number;
l_begin_time date;
l_tot_deletions pls_integer := 0;
l_rowcount pls_integer := 0;
l_run_time_exceeded boolean := false;

BEGIN

l_begin_time := sysdate;

zms.log_autonomous_msg('DAILYJOB', null, null,
        'Begin custitem_import_changes purge',
        'I', 'DAILYJOB', l_appmsg);

open curcustitem_import_changes;
loop

  fetch curcustitem_import_changes bulk collect into rowid_tbl limit 10000;

  if rowid_tbl.count = 0 then
    exit;
  end if;

  forall i in rowid_tbl.first .. rowid_tbl.last
    delete custitem_import_changes
     where rowid = rowid_tbl(i);

  l_rowcount := sql%rowcount;
  l_tot_deletions := l_tot_deletions + l_rowcount;

  commit;

  l_elapsed_time := sysdate - l_begin_time;
  if l_elapsed_time >= l_max_run_time then
    l_run_time_exceeded := true;
    goto end_of_custitem_import_changes;
  end if;

  if l_tot_deletions >= l_max_deletions then
    goto end_of_custitem_import_changes;
  end if;

  exit when curcustitem_import_changes%notfound;

end loop;

<< end_of_custitem_import_changes >>

if curcustitem_import_changes%isopen then
  close curcustitem_import_changes;
end if;

l_msg := 'End custitem_import_changes purge. Deletions: ' || l_tot_deletions;

if l_run_time_exceeded then
  l_msg := l_msg || ' (run time was exceeded)';
end if;

zms.log_autonomous_msg('DAILYJOB', null, null, l_msg,
                       'I', 'CICPURGE', l_appmsg);


EXCEPTION WHEN OTHERS THEN
  begin
    zms.log_autonomous_msg('DAILYJOB', null, null,
            'custitem_import_changes daily purge: '||sqlerrm,
            'E', 'SDIPURGE', l_appmsg);
  exception when others then
    null;
  end;
END custitem_import_changes_purge;

----------------------------------------------------------------------
--
-- import204 purge
--
----------------------------------------------------------------------

PROCEDURE import204_purge
IS

cursor curimport_204_load is
  select rowid
    from import_204_load
   where created < systimestamp - 31;

cursor curimport_204_stop is
  select rowid
    from import_204_stop
   where created < systimestamp - 31;

cursor curimport_204_order is
  select rowid
    from import_204_order
   where created < systimestamp - 31;


type rowid_tbl_type is table of rowid;
rowid_tbl rowid_tbl_type;

l_appmsg varchar2(255);
l_msg varchar2(255);
l_max_deletions pls_integer := 1000000;
l_max_run_time number := 1/24;  -- limit run time to 1 hour per table
l_elapsed_time number;
l_begin_time date;
l_tot_deletions pls_integer := 0;
l_rowcount pls_integer := 0;
l_run_time_exceeded boolean := false;

BEGIN

l_begin_time := sysdate;

zms.log_autonomous_msg('DAILYJOB', null, null,
        'Begin custitem_import_changes purge',
        'I', 'DAILYJOB', l_appmsg);


open curimport_204_order;
loop

  fetch curimport_204_order bulk collect into rowid_tbl limit 10000;

  if rowid_tbl.count = 0 then
    exit;
  end if;

  forall i in rowid_tbl.first .. rowid_tbl.last
    delete import_204_order
     where rowid = rowid_tbl(i);

  l_rowcount := sql%rowcount;
  l_tot_deletions := l_tot_deletions + l_rowcount;

  commit;

  l_elapsed_time := sysdate - l_begin_time;
  if l_elapsed_time >= l_max_run_time then
    l_run_time_exceeded := true;
    goto end_of_import_204_changes;
  end if;

  if l_tot_deletions >= l_max_deletions then
    goto end_of_import_204_changes;
  end if;

  exit when curimport_204_order%notfound;

end loop;

open curimport_204_stop;
loop

  fetch curimport_204_stop bulk collect into rowid_tbl limit 10000;

  if rowid_tbl.count = 0 then
    exit;
  end if;

  forall i in rowid_tbl.first .. rowid_tbl.last
    delete import_204_stop
     where rowid = rowid_tbl(i);

  l_rowcount := sql%rowcount;
  l_tot_deletions := l_tot_deletions + l_rowcount;

  commit;

  l_elapsed_time := sysdate - l_begin_time;
  if l_elapsed_time >= l_max_run_time then
    l_run_time_exceeded := true;
    goto end_of_import_204_changes;
  end if;

  if l_tot_deletions >= l_max_deletions then
    goto end_of_import_204_changes;
  end if;

  exit when curimport_204_stop%notfound;

end loop;

open curimport_204_load;
loop

  fetch curimport_204_load bulk collect into rowid_tbl limit 10000;

  if rowid_tbl.count = 0 then
    exit;
  end if;

  forall i in rowid_tbl.first .. rowid_tbl.last
    delete import_204_load
     where rowid = rowid_tbl(i);

  l_rowcount := sql%rowcount;
  l_tot_deletions := l_tot_deletions + l_rowcount;

  commit;

  l_elapsed_time := sysdate - l_begin_time;
  if l_elapsed_time >= l_max_run_time then
    l_run_time_exceeded := true;
    goto end_of_import_204_changes;
  end if;

  if l_tot_deletions >= l_max_deletions then
    goto end_of_import_204_changes;
  end if;

  exit when curimport_204_load%notfound;

end loop;


<< end_of_import_204_changes >>

if curimport_204_order%isopen then
  close curimport_204_order;
end if;

if curimport_204_stop%isopen then
  close curimport_204_stop;
end if;

if curimport_204_load%isopen then
  close curimport_204_load;
end if;


l_msg := 'End imprort_204 purge. Deletions: ' || l_tot_deletions;

if l_run_time_exceeded then
  l_msg := l_msg || ' (run time was exceeded)';
end if;

zms.log_autonomous_msg('DAILYJOB', null, null, l_msg,
                       'I', 'I204PURGE', l_appmsg);


EXCEPTION WHEN OTHERS THEN
  begin
    zms.log_autonomous_msg('DAILYJOB', null, null,
            'import204 daily purge: '||sqlerrm,
            'E', 'I204PURGE', l_appmsg);
  exception when others then
    null;
  end;
END import204_purge;

procedure peopleskhexpiration(in_custid in varchar2)
is
cursor curPlates(in_custid varchar2) is
  select p.lpid,
         p.custid,
         p.item,
         nvl(p.inventoryclass,'RG') as inventoryclass,
         p.invstatus,
         p.lotnumber,
         p.serialnumber,
         p.useritem1,
         p.useritem2,
         p.useritem3,
         p.location,
         p.expirationdate,
         p.manufacturedate,
         p.unitofmeasure,
         p.quantity as qty,
         p.facility,
         nvl(p.loadno,0) as loadno,
         nvl(p.stopno,0) as stopno,
         nvl(p.shipno,0) as shipno,
         p.orderid,
         p.shipid,
         p.type,
         p.parentlpid,
         p.weight,
         p.controlnumber,
         p.adjreason,
         p.anvdate,
         ci.itmpassthruchar06,
         ci.itmpassthruchar07,
         ci.itmpassthruchar08,
         ci.itmpassthrunum01,
         ci.itmpassthrunum03
    from plate p, custitem ci
   where p.custid = in_custid
     and p.expirationdate is not null
     and p.manufacturedate is not null
     and type = 'PA'
     and ci.custid = p.custid
     and ci.item = p.item
   order by p.item;


pl curPlates%rowtype;

out_msg varchar2(255);
out_errorno integer;
out_adjrowid1 varchar2(255);
out_adjrowid2 varchar2(255);
cntRows integer;
cntErr integer;
qtyTot integer;
qtyErr integer;
qtyOky integer;

cntTot integer;
cntOky integer;
strMsg varchar2(255);

last_item custitem.item%type;
system_date date;
old_date date;
test_date date;
mfg_date date;
exp_date date;
new_invstatus plate.invstatus%type;
d1 varchar2(32);
d2 varchar2(32);
d3 varchar2(32);
begin

   zms.log_autonomous_msg('DAILYJOB', null, null,
           'Begin PEOPLESKHEXPIRATION Expiration Process',
           'I', 'DAILYJOB', strMsg);


   cntTot := 0;
   cntErr := 0;
   cntOky := 0;
   qtyTot := 0;
   qtyErr := 0;
   qtyOky := 0;
   last_item := '(none)';
   select trunc(sysdate) into system_date from dual;

   for pl in curPlates(in_custid)
   loop
      --zut.prt('lpid ' || pl.lpid);
      if pl.itmpassthruchar06 is null or
         pl.itmpassthruchar07 is null  or
         pl.itmpassthruchar08 is null  or
         pl.itmpassthrunum01 is null  or
         pl.itmpassthrunum03 is null  then
         if pl.item != last_item then
          zms.log_autonomous_msg('DAILYJOB', null, null,
            'PEOPLESKHEXPIRATION item missing expiration information ' || pl.item,
            'E', 'DAILYJOB', strMsg);
         end if;
         last_item := pl.item;
         continue;
      end if;
      --zut.prt('invstatus ' || pl.invstatus ||' ' || pl.itmpassthruchar06 || ' ' || pl.itmpassthruchar07);
      if pl.invstatus not in (pl.itmpassthruchar06, pl.itmpassthruchar07) then
         continue;
      end if;

      if pl.invstatus = pl.itmpassthruchar06 then
         select trunc(sysdate) - pl.itmpassthrunum01 into test_date from dual;
         select trunc(pl.manufacturedate) into mfg_date from dual;
         if mfg_date <= test_date then
             new_invstatus := pl.itmpassthruchar07;
         else
            continue;
         end if;
      else
         select trunc(pl.expirationdate - pl.itmpassthrunum03) into exp_date from dual;
         select trunc(system_date) into old_date from dual;
         if exp_date <= old_date then
            new_invstatus := pl.itmpassthruchar08;
         else
            continue;
         end if;
      end if;

      cntTot := cntTot + 1;
      qtyTot := qtyTot + pl.qty;

      zia.inventory_adjustment
      (pl.lpid
      ,pl.custid
      ,pl.item
      ,pl.inventoryclass
      ,new_invstatus
      ,pl.lotnumber
      ,pl.serialnumber
      ,pl.useritem1
      ,pl.useritem2
      ,pl.useritem3
      ,pl.location
      ,pl.expirationdate
      ,pl.qty
      ,pl.custid
      ,pl.item
      ,pl.inventoryclass
      ,pl.invstatus
      ,pl.lotnumber
      ,pl.serialnumber
      ,pl.useritem1
      ,pl.useritem2
      ,pl.useritem3
      ,pl.location
      ,pl.expirationdate
      ,pl.qty
      ,pl.facility
      ,'AC'
      ,'KHEXPRUN'
      ,'EP'
      ,pl.weight
      ,pl.weight
      ,pl.manufacturedate
      ,pl.manufacturedate
      ,pl.anvdate
      ,pl.anvdate
      ,out_adjrowid1
      ,out_adjrowid2
      ,out_errorno
      ,out_msg);

      if out_errorno != 0 then
        rollback;
        cntErr := cntErr + 1;
        qtyErr := qtyErr + pl.qty;
        zms.log_autonomous_msg('KHEXPRUN', null, null,
            pl.lpid || ' ' || out_msg,
            'E', 'DAILYJOB', strMsg);
      else
        commit;
        cntOky := cntOky + 1;
        qtyOky := qtyOky + pl.qty;
        if out_adjrowid1 is not null then
           zim6.check_for_adj_interface(out_adjrowid1,out_errorno,out_msg);
        end if;
        if out_adjrowid2 is not null then
           zim6.check_for_adj_interface(out_adjrowid2,out_errorno,out_msg);
        end if;
      end if;

   end loop;

--zut.prt('total count: ' || cntTot || ' total quantity: ' || qtyTot);
--zut.prt('error count: ' || cntErr || ' error quantity: ' || qtyErr);
--zut.prt('okay  count: ' || cntOky || ' okay  quantity: ' || qtyOky);


    zms.log_autonomous_msg('DAILYJOB', null, null,
            'End Expiration Process (Processed: ' || cntTot
                    || ' Updated: ' || cntOky || ')',
            'I', 'DAILYJOB', strMsg);



EXCEPTION WHEN OTHERS THEN
  begin
    zms.log_autonomous_msg('PEOPLESKHEXP', null, null,
            'PEOPLESKHEX PExpiration Process Error:'||sqlerrm,
            'E', 'DAILYJOB', strMsg);
  exception when others then
    null;
  end;
end peopleskhexpiration;

end zjob;
/
show error package body zjob;
exit;
