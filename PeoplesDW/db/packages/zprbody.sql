create or replace package body alps.zparserule as
--
-- $Id$
--
-- **********************************************************************
-- *                                                                    *
-- *      CONSTANTS                                                     *
-- *                                                                    *
-- **********************************************************************
--
--
-- NLCR char(2) := chr(10) || chr(13);
NLCR char(1) := chr(13);

----------------------------------------------------------------------


-- **********************************************************************
-- *                                                                    *
-- *      CURSORS                                                       *
-- *                                                                    *
-- **********************************************************************

----------------------------------------------------------------------



-- **********************************************************************
-- *                                                                    *
-- *      PROCEDURES AND FUNCTIONS                                      *
-- *                                                                    *
-- **********************************************************************

PROCEDURE lookup_data
(
    in_ruleid   IN  varchar2,
    in_string   IN  varchar2,
    in_mask     IN  varchar2,
    out_string  OUT varchar2,
    out_mask    OUT varchar2
)
IS
CURSOR C_PL(in_ruleid varchar2, in_lookupid varchar2)
IS
SELECT *
  FROM parselookup
 WHERE ruleid = in_ruleid
   AND lookupid = in_lookupid;

PL parselookup%rowtype;

new_string varchar2(100);
new_mask varchar2(100);

ix integer;
iy integer;

cmdstr varchar2(1000);
l_val varchar2(50);
l_keylen integer;

BEGIN

    new_string := '';
    new_mask := '';
    ix := 1;
    iy := 1;
    loop
        exit when ix > length(in_mask);
        if substr(in_mask, ix, 1) = '\'
        then
            ix := ix + 1;
            PL := null;
            OPEN C_PL(in_ruleid, substr(in_mask, ix, 1));
            FETCH C_PL into PL;
            CLOSE C_PL;
            if PL.ruleid is not null then
                new_mask := new_mask || PL.mask;
                cmdstr := 'select abbrev from '||PL.tableid
                    ||' where code = '''||substr(in_string,iy,PL.in_len)||'''';

                l_val := '';
                execute immediate cmdstr into l_val;


                new_string := new_string ||
                    rpad(substr(l_val,1,PL.out_len),PL.out_len,'?');
                iy := iy + PL.in_len;
                ix := ix + 1;
            else
                ix := ix + 1;
            end if;
        elsif substr(in_mask, ix, 1) = '[' then
            l_keylen := instr(in_mask, ']', ix) - ix - 1;
            PL := null;
            OPEN C_PL(in_ruleid, substr(in_mask, ix+1, l_keylen));
            FETCH C_PL into PL;
            CLOSE C_PL;
            if PL.ruleid is not null then
                new_mask := new_mask || PL.mask;
                cmdstr := 'select abbrev from '||PL.tableid
                    ||' where code = '''||substr(in_string,iy,PL.in_len)||'''';
                l_val := '';
                execute immediate cmdstr into l_val;
                new_string := new_string ||
                    rpad(substr(l_val,1,PL.out_len),PL.out_len,'?');
                iy := iy + PL.in_len;
            end if;
            ix := ix + l_keylen + 2;
        else
            new_mask := new_mask || substr(in_mask,ix,1);
            new_string := new_string || substr(in_string,iy,1);
            ix := ix + 1;
            iy := iy + 1;
        end if;

    end loop;

 -- Get the rest of the string

    if iy < length(in_string) then
        new_string := new_string || substr(in_string,iy);
    end if;

    out_mask := substr(new_mask,1,50);
    out_string := substr(new_string,1,30);

EXCEPTION WHEN OTHERS THEN
    out_mask := 'Failed!!!';
    out_string := substr('LU Fail:'||sqlerrm,1,30);
END lookup_data;



PROCEDURE get_string
(
    in_ruleid   IN  varchar2,
    in_string   IN  varchar2,
    in_mask     IN  varchar2,
    out_value   OUT varchar2
)
IS

  ix integer;

  l_string varchar2(30);
  l_mask varchar2(50);


BEGIN
    out_value := '';
    lookup_data(in_ruleid, in_string, in_mask, l_string, l_mask);

    if l_mask = 'Failed!!!' then
        l_mask := in_mask;
        l_string := in_string;
    end if;

    for ix in 1..length(l_string) loop
        if substr(l_mask,ix,1) = 'X' then
              out_value := out_value || substr(l_string,ix,1);
        end if;
    end loop;
END get_string;



PROCEDURE get_date
(
    in_ruleid   IN  varchar2,
    in_string   IN  varchar2,
    in_mask     IN  varchar2,
    out_value   OUT varchar2
)
IS

  ix integer;
  i  integer;
  tstr varchar2(30);
  tstr_leap_year varchar2(30);
  tmask varchar2(50);

  l_string varchar2(30);
  l_mask varchar2(50);

  l_www_pos integer;
  l_year_len integer := 0;
  l_days varchar2(30);
  l_year varchar2(4);
  tdays integer;
  is_leapyear boolean;
  function iso_ywwd_to_date
     (in_year   in varchar2,
      in_week   in varchar2,
      in_day    in varchar2)
  return date
  is
  begin
     return trunc(to_date('01/01/'||in_year,'MM/DD/'||lpad('Y',length(in_year),'Y')),'D')
           + 7*(in_week-1)
           + in_day;
  end iso_ywwd_to_date;

BEGIN
   lookup_data(in_ruleid, in_string, in_mask, l_string, l_mask);
   if l_mask = 'Failed!!!' then
       l_mask := in_mask;
       l_string := in_string;
   end if;
   tstr := '';
   for ix in 1..length(l_string) loop
       if substr(l_mask,ix,1) <> '?' then
             tstr := tstr || substr(l_string,ix,1);
       end if;
   end loop;

   tmask := '';
   for ix in 1..length(l_mask) loop
       if substr(l_mask,ix,1) <> '?' then
             tmask := tmask || substr(l_mask,ix,1);
             if substr(l_mask,ix,1) = 'Y' then
                 l_year_len := l_year_len + 1;
             end if;
       end if;
   end loop;

   l_www_pos := instr(tmask,'WWW');
   if l_www_pos > 0 then
      out_value := to_char(
         iso_ywwd_to_date(substr(tstr, instr(tmask,'Y'),l_year_len),
            substr(tstr,l_www_pos,2),
            substr(tstr,l_www_pos+2,1)),'MM/DD/YYYY');
   else
      i := instr(upper(tmask), 'ZZZ', 1, 1);
      if i > 0 then
         select replace(tmask, 'Z', 'D') into tmask from dual;
         if substr(tstr, i, 3) = '366' then -- the test will throw an error if not a leap year
            tstr_leap_year := tstr;         -- and day is 366, make it 365 and find the year
            tstr_leap_year := substr(tstr, 1, i-1) ||'365' || substr(tstr, i+4);
            l_year := substr(to_char(to_date(tstr_leap_year, tmask),'MM/DD/YYYY'), 7);
         else
            l_year := substr(to_char(to_date(tstr, tmask),'MM/DD/YYYY'), 7);
         end if;
         is_leapyear := false;
         if ((mod(to_number(l_year), 4) = 0 and mod(to_number(l_year), 100) <> 0)) or
             mod(to_number(l_year), 400) = 0 then
            is_leapyear := true;
         end if;
         l_days := substr(tstr, i, 3);
         select to_number(l_days, '999') into tdays from dual;
         if not is_leapyear and
            tdays > 60 then
            tdays := tdays - 1;
         end if;
         tstr := tdays || '/' || l_year;
         out_value := to_char(to_date(tstr, 'DDD/YYYY'),'MM/DD/YYYY');

      else
         out_value := to_char(to_date(tstr, tmask),'MM/DD/YYYY');
      end if;

   end if;

Exception when others then
   out_value := 'Invalid Date Value';

END get_date;

PROCEDURE parse_string_real
(
    in_ruleid    IN         varchar2,
    in_string    IN         varchar2,
    out_serialno OUT        varchar2,
    out_lot      OUT        varchar2,
    out_user1    OUT        varchar2,
    out_user2    OUT        varchar2,
    out_user3    OUT        varchar2,
    out_mfgdate  OUT        varchar2,
    out_expdate  OUT        varchar2,
    out_country  OUT        varchar2,
    out_errmsg   IN OUT     varchar2
)
IS

  CURSOR C_PR(in_ruleid varchar2)
  RETURN parserule%rowtype
  IS
    select *
      from parserule
     where ruleid = in_ruleid;

 pr parserule%rowtype;

BEGIN
    out_errmsg := 'OKAY';
    out_serialno := null;
    out_lot := null;
    out_user1 := null;
    out_user2 := null;
    out_user3 := null;
    out_mfgdate := null;
    out_expdate := null;
    out_country := null;


    OPEN C_PR(in_ruleid);
    FETCH C_PR into pr;
    CLOSE C_PR;

    if pr.ruleid is null then
       out_errmsg := 'Invalid ruleid';
       return;
    end if;


    if pr.serialnomask is not null then
       get_string(in_ruleid, in_string, pr.serialnomask, out_serialno);
    end if;

    if pr.lotmask is not null then
       get_string(in_ruleid, in_string, pr.lotmask, out_lot);
    end if;

    if pr.user1mask is not null then
       get_string(in_ruleid, in_string, pr.user1mask, out_user1);
    end if;

    if pr.user2mask is not null then
       get_string(in_ruleid, in_string, pr.user2mask, out_user2);
    end if;

    if pr.user3mask is not null then
       get_string(in_ruleid, in_string, pr.user3mask, out_user3);
    end if;

    if pr.mfgdatemask is not null then
       get_date(in_ruleid, in_string, pr.mfgdatemask, out_mfgdate);
    end if;

    if pr.expdatemask is not null then
       get_date(in_ruleid, in_string, pr.expdatemask, out_expdate);
    end if;

    if pr.countrymask is not null then
       get_string(in_ruleid, in_string, pr.countrymask, out_country);
    end if;

exception when others then
  out_errmsg := 'zpr:'||sqlerrm;
END parse_string_real;

PROCEDURE parse_string
(
    in_ruleid    IN         varchar2,
    in_string    IN         varchar2,
    out_serialno OUT        varchar2,
    out_lot      OUT        varchar2,
    out_user1    OUT        varchar2,
    out_user2    OUT        varchar2,
    out_user3    OUT        varchar2,
    out_mfgdate  OUT        varchar2,
    out_expdate  OUT        varchar2,
    out_country  OUT        varchar2,
    out_errmsg   IN OUT     varchar2
)
IS

  CURSOR C_PRV(in_ruleid varchar2)
  RETURN parseruleview%rowtype
  IS
    select *
      from parseruleview
     where ruleid = in_ruleid;

  prv C_PRV%rowtype;
  l_length pls_integer;
begin

   OPEN C_PRV(in_ruleid);
   FETCH C_PRV into prv;
   CLOSE C_PRV;

   if prv.ruleid is null then
      out_errmsg := 'Invalid ruleid';
      return;
   end if;

   if prv.ruletype = 'R' then
      parse_string_real(in_ruleid, in_string, out_serialno, out_lot, out_user1,
                        out_user2, out_user3, out_mfgdate, out_expdate,
                        out_country, out_errmsg);
   else
      for pr in (select p.*
                   from parserule p, parserulegroupdtl prg
                  where prg.groupid = in_ruleid
                    and p.ruleid = prg.ruleid) loop
         if pr.mfgdatemask is not null then
            l_length := length(pr.mfgdatemask) - regexp_count(pr.mfgdatemask, '\\\');
         elsif pr.expdatemask is not null then
            l_length := length(pr.expdatemask) - regexp_count(pr.expdatemask, '\\\');
         else
            l_length := -1;
         end if;
         if length(in_string) = l_length then
            parse_string_real(pr.ruleid, in_string, out_serialno, out_lot, out_user1,
                              out_user2, out_user3, out_mfgdate, out_expdate,
                              out_country, out_errmsg);
            if nvl(out_expdate, 'n') != 'Invalid Date Value' and
               nvl(out_mfgdate, 'n') != 'Invalid Date Value' then
               return;
            end if;
         end if;
      end loop;
      out_errmsg := 'Invalid Date Value';
   end if;




exception when others then
  out_errmsg := 'zpr:'||sqlerrm;
END parse_string;

end zparserule;
/

show errors package body zparserule;
exit;
