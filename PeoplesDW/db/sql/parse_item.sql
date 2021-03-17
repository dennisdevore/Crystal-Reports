--
-- $Id$
--
set serveroutput on
set feedback off
set verify off
prompt
prompt This script will update all parse entry columns for all plates
prompt (regardless of status) for a specific customer and item.  It
prompt will not update any columns which are not affected by the rule.
prompt
accept p_custid prompt 'Enter custid: '
prompt
accept p_item prompt 'Enter item: '
prompt

declare
   cursor c_itm(p_custid varchar2, p_item varchar2) is
      select nvl(parseruleaction, 'N') as parseruleaction,
             upper(parseentryfield) as parseentryfield,
             upper(parseruleid) as parseruleid
      from custitemview
      where custid = p_custid
        and item = p_item;
   itm c_itm%rowtype := null;
   cursor c_lp(p_custid varchar2, p_item varchar2, p_field varchar2) is
      select lpid,
             rowid,
             decode(p_field,
                   'LOTNUMBER', lotnumber,
                   'SERIALNUMBER', serialnumber,
                   'USERITEM1', useritem1,
                   'USERITEM2', useritem2,
                   'USERITEM3', useritem3,
                   null) as string
         from plate
         where custid = p_custid
           and item = p_item;
	l_custid custitem.custid%type := upper('&&p_custid');
	l_item custitem.item%type := upper('&&p_item');
   l_serialnumber plate.serialnumber%type;
   l_lotnumber plate.lotnumber%type;
   l_useritem1 plate.useritem1%type;
   l_useritem2 plate.useritem2%type;
   l_useritem3 plate.useritem3%type;
   l_manufacturedate varchar2(255);
   l_expirationdate varchar2(255);
   l_countryof plate.countryof%type;
   l_msg varchar2(255);
   l_updated pls_integer := 0;
begin

   dbms_output.enable(1000000);

   open c_itm(l_custid, l_item);
   fetch c_itm into itm;
   if c_itm%notfound then
      close c_itm;
      dbms_output.put_line('Item record not found');
      return;
   end if;
   close c_itm;

   if itm.parseruleaction = 'N' then
      dbms_output.put_line('Parsing not enabled for item');
      return;
   end if;

   if itm.parseentryfield is null then
      dbms_output.put_line('No parse entry field for item');
      return;
   end if;

   if itm.parseruleid is null then
      dbms_output.put_line('No parse rule for item');
      return;
   end if;

   for lp in c_lp(l_custid, l_item, itm.parseentryfield) loop

      l_msg := null;
      zpr.parse_string
            (itm.parseruleid,
             lp.string,
             l_serialnumber,
             l_lotnumber,
             l_useritem1,
             l_useritem2,
             l_useritem3,
             l_manufacturedate,
             l_expirationdate,
             l_countryof,
             l_msg);

      if l_msg != 'OKAY' then
         dbms_output.put_line(lp.lpid||': '||l_msg);
      elsif upper(substr(nvl(l_manufacturedate, 'IAmValid'),1,7)) = 'INVALID' then
         dbms_output.put_line(lp.lpid||': Invalid manufacture date');
      elsif upper(substr(nvl(l_expirationdate, 'IAmValid'),1,7)) = 'INVALID' then
         dbms_output.put_line(lp.lpid||': Invalid expiration date');
      elsif l_serialnumber is null
        and l_lotnumber is null
        and l_useritem1 is null
        and l_useritem2 is null
        and l_useritem3 is null
        and l_manufacturedate is null
        and l_expirationdate is null
        and l_countryof is null then
         dbms_output.put_line(lp.lpid||': Skipped');
      else
         l_updated := l_updated + 1;
         update plate
            set serialnumber = nvl(l_serialnumber, serialnumber),
                lotnumber = nvl(l_lotnumber, lotnumber),
                useritem1 = nvl(l_useritem1, useritem1),
                useritem2 = nvl(l_useritem2, useritem2),
                useritem3 = nvl(l_useritem3, useritem3),
                manufacturedate = nvl(to_date(l_manufacturedate, 'MM/DD/RRRR'), manufacturedate),
                expirationdate = nvl(to_date(l_expirationdate, 'MM/DD/RRRR'), expirationdate),
                countryof = nvl(l_countryof, countryof),
                lastuser = 'PARSEITEM',
                lastupdate = sysdate
            where rowid = lp.rowid;
      end if;
   end loop;

   dbms_output.put_line(l_updated||': Converted');

end;
/
set feedback on
