--
-- $Id$
--
set serveroutput on;
declare
   cursor c_lp is
      select rowid, custid, item, lpid
         from plate
			where expirationdate is not null;
   cursor c_it(p_custid varchar2, p_item varchar2) is
      select decode(nvl(I.expdaterequired, 'C'), 'C', nvl(C.expdaterequired, 'N'),
             I.expdaterequired) expreqd, nvl(I.shelflife, 0) shelflife
         from custitem I, customer C
         where I.custid = p_custid
           and I.item = p_item
           and C.custid = p_custid;
   it c_it%rowtype;
   updflag varchar2(1);
   totcnt integer := 0;
   toterr integer := 0;
   totok integer := 0;
begin
   updflag := '&&1';
   dbms_output.enable(1000000);
   for lp in c_lp loop
      totcnt := totcnt + 1;
      open c_it(lp.custid, lp.item);
      fetch c_it into it;
      close c_it;
      if ((it.expreqd = 'N') and (it.shelflife = 0)) then
         toterr := toterr + 1;
         if (updflag = 'Y') then
            update plate
               set expirationdate = null,
                   invstatus = decode(invstatus, 'EX', 'AV', invstatus),
                   lastuser = 'EXPAUDIT',
                   lastupdate = sysdate
               where rowid = lp.rowid;
            commit;
            zut.prt('Fixed lp ' || lp.lpid);
         end if;
      else
         totok := totok + 1;
      end if;
   end loop;
   zut.prt('total: ' || totcnt);
   zut.prt('err:   ' || toterr);
   zut.prt('ok:    ' || totok);

exception when others then
   zut.prt('when others');
   zut.prt(sqlerrm);
end;
/
