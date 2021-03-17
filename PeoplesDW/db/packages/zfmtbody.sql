create or replace package body alps.formatvalidation as
--
-- $Id$
--


function is_value_for_mask
   (in_value in varchar2,
    in_mask  in varchar2)
return boolean
is
   i integer := 1;
   maskchar char(1);
   valchar char(1);
begin
   if (length(in_value) != length(in_mask)) then
      return FALSE;
   end if;

   for i in 1..nvl(length(in_mask), 0)
   loop
      valchar := substr(in_value, i, 1);
      maskchar := substr(in_mask, i, 1);
      if (maskchar = 'A') then               -- letters only
         if (valchar not between 'A' and 'Z') then
            return FALSE;
         end if;
      elsif (maskchar = '9') then            -- numbers only
         if (valchar not between '0' and '9') then
            return FALSE;
         end if;
      elsif (maskchar = 'X') then            -- letters or numbers
         if ((valchar not between 'A' and 'Z') and (valchar not between '0' and '9')) then
            return FALSE;
         end if;
      elsif (maskchar = '~') then            -- match any character
         null;
      else                                   -- match mask character
         if (valchar != maskchar) then
            return FALSE;
         end if;
      end if;
   end loop;
   return TRUE;

exception
   when OTHERS then
      return FALSE;
end is_value_for_mask;

FUNCTION is_value_for_exclude_mask
   (in_value in varchar2,
    in_mask  in varchar2)
RETURN boolean
IS

len integer;

iv  integer;            -- position in data value
im  integer;            -- position in mask

maskchar char(1);
valchar char(1);
esc BOOLEAN;



BEGIN

    len := nvl(length(in_mask),0);

    if len = 0 then
        return FALSE;
    end if;

    iv := 1;
    im := 1;

    while (im <= len)
    loop

        valchar := substr(in_value, iv, 1);
        maskchar := substr(in_mask, im, 1);

        if maskchar = '\' then
            im := im+1;
            esc := TRUE;
            maskchar := substr(in_mask, im, 1);
        end if;

        if esc then
            if maskchar != valchar then
                return FALSE;
            end if;
            esc := FALSE;
            goto continue;
        end if;
    -- not in escape mode so do normal checking
        if (maskchar = 'A') then               -- letters only
            if (valchar not between 'A' and 'Z') then
                return FALSE;
            end if;
        elsif (maskchar = '9') then            -- numbers only
            if (valchar not between '0' and '9') then
                return FALSE;
            end if;
        elsif (maskchar = 'X') then            -- letters or numbers
            if ((valchar not between 'A' and 'Z') and (valchar not between '0' and '9')) then
                return FALSE;
            end if;
        elsif (maskchar = '~') then            -- match any character
            null;
        else                                   -- match mask character
            if (valchar != maskchar) then
                return FALSE;
            end if;
        end if;

<<continue>>
        im := im + 1;
        iv := iv + 1;
        esc := FALSE;
    end loop;

   return TRUE;

EXCEPTION WHEN OTHERS THEN
      return FALSE;
END is_value_for_exclude_mask;



function is_check_digit_ok
	(in_value in varchar2)
return boolean
is
   digit_sum pls_integer := 0;
   tmp pls_integer;
begin
   for i in 1..nvl(length(in_value), 0)
   loop
      if (mod(i, 2) = 1) then
--       odd digit - add in the value
         digit_sum := digit_sum + to_number(substr(in_value, -i, 1));
      else
--       even digit - add in sum of digits from double the value
         tmp := to_number(substr(in_value, -i, 1)) * 2;
         digit_sum := digit_sum + floor(tmp/10) + mod(tmp, 10);
      end if;
	end loop;

	return mod(digit_sum, 10) = 0;

exception
   when OTHERS then
      return FALSE;
end is_check_digit_ok;


function get_rcpt_dupes
	(in_custid 		in varchar2,
	 in_item 		in varchar2,
	 in_data_name	in varchar2,
	 in_data_value in varchar2)
return number
is
   dupecnt number := 0;
begin
   if (upper(in_data_name) = 'S') then
      select count(1) into dupecnt
         from orderdtlrcpt
         where custid = in_custid
           and item = in_item
           and serialnumber = upper(in_data_value);
   elsif (upper(in_data_name) = '1') then
      select count(1) into dupecnt
         from orderdtlrcpt
         where custid = in_custid
           and item = in_item
           and useritem1 = upper(in_data_value);
   elsif (upper(in_data_name) = '2') then
      select count(1) into dupecnt
         from orderdtlrcpt
         where custid = in_custid
           and item = in_item
           and useritem2 = upper(in_data_value);
   elsif (upper(in_data_name) = '3') then
      select count(1) into dupecnt
         from orderdtlrcpt
         where custid = in_custid
           and item = in_item
           and useritem3 = upper(in_data_value);
   end if;

   return dupecnt;

exception
   when OTHERS then
   	return 0;
end get_rcpt_dupes;


procedure verify_format
	(in_custid 		in varchar2,
	 in_item 		in varchar2,
	 in_data_name	in varchar2, -- 'LD' is for lots no dup check
	 in_data_value in varchar2,
	 out_action    out varchar2,
    out_errno     out number,
    out_errmsg    out varchar2)
is
	fmtruleid formatvalidationrule.ruleid%type := null;
	fmtaction custitem.lotfmtaction%type := null;
	cursor c_item is
		select lotfmtruleid, lotfmtaction,
				 serialfmtruleid, serialfmtaction,
				 user1fmtruleid, user1fmtaction,
				 user2fmtruleid, user2fmtaction,
				 user3fmtruleid, user3fmtaction
			from custitemview
			where custid = in_custid
			  and item = in_item;
	fmtids c_item%rowtype;
	cursor c_rule is
		select nvl(minlength, 0) minlength, nvl(maxlength, 0) maxlength,
             nvl(datatype, 'D') datatype, mask, nvl(dupesok, 'Y') dupesok,
             nvl(mod10check, 'N') mod10check, excludemask
			from formatvalidationrule
			where ruleid = fmtruleid;
	rule c_rule%rowtype;
	rowfound boolean;
	datum varchar(255);
   dupe_cnt pls_integer;
begin
	out_errno := 0;
	out_errmsg := null;
	out_action := 'P';	-- to handle "non-verify" and duplicate errors

-- try item first
	open c_item;
	fetch c_item into fmtids;
	rowfound := c_item%found;
	close c_item;
	if not rowfound then
		out_errno := 1;
		out_errmsg := 'Item not found';
		return;
	end if;

	if (upper(in_data_name) in ('L', 'LD')) then
		fmtruleid := fmtids.lotfmtruleid;
		fmtaction := fmtids.lotfmtaction;
	elsif (upper(in_data_name) = 'S') then
		fmtruleid := fmtids.serialfmtruleid;
		fmtaction := fmtids.serialfmtaction;
	elsif (in_data_name = '1') then
		fmtruleid := fmtids.user1fmtruleid;
		fmtaction := fmtids.user1fmtaction;
	elsif (in_data_name = '2') then
		fmtruleid := fmtids.user2fmtruleid;
		fmtaction := fmtids.user2fmtaction;
	elsif (in_data_name = '3') then
		fmtruleid := fmtids.user3fmtruleid;
		fmtaction := fmtids.user3fmtaction;
	else
		out_errno := 2;
		out_errmsg := 'Bad data type';
		return;
	end if;

-- no rule active, assume data is OK
	if (fmtruleid is null) then
		return;
	end if;

	open c_rule;
	fetch c_rule into rule;
	rowfound := c_rule%found;
	close c_rule;
	if not rowfound then
		out_errno := 4;
		out_errmsg := 'Rule not found';
		return;
	end if;

	datum := upper(in_data_value);

-- need to check for dupes first so user can't override if warning
   if (rule.dupesok = 'N') then
		if (upper(in_data_name) = 'L') then
         select count(1) into dupe_cnt
            from plate
            where custid = in_custid
              and item = in_item
              and type = 'PA'
              and lotnumber = datum;
         if (dupe_cnt = 0) then
            select count(1) into dupe_cnt
               from shippingplate
               where custid = in_custid
                 and item = in_item
                 and lotnumber = datum
                 and status != 'SH';
         end if;
		elsif (upper(in_data_name) = 'S') then
         select count(1) into dupe_cnt
            from plate
            where custid = in_custid
              and item = in_item
              and type = 'PA'
              and serialnumber = datum;
         if (dupe_cnt = 0) then
            select count(1) into dupe_cnt
               from shippingplate
               where custid = in_custid
                 and item = in_item
                 and serialnumber = datum
                 and status != 'SH';
         end if;
		elsif (in_data_name = '1') then
         select count(1) into dupe_cnt
            from plate
            where custid = in_custid
              and item = in_item
              and type = 'PA'
              and useritem1 = datum;
         if (dupe_cnt = 0) then
            select count(1) into dupe_cnt
               from shippingplate
               where custid = in_custid
                 and item = in_item
                 and useritem1 = datum
                 and status != 'SH';
         end if;
		elsif (in_data_name = '2') then
         select count(1) into dupe_cnt
            from plate
            where custid = in_custid
              and item = in_item
              and type = 'PA'
              and useritem2 = datum;
         if (dupe_cnt = 0) then
            select count(1) into dupe_cnt
               from shippingplate
               where custid = in_custid
                 and item = in_item
                 and useritem2 = datum
                 and status != 'SH';
         end if;
		else
         select count(1) into dupe_cnt
            from plate
            where custid = in_custid
              and item = in_item
              and type = 'PA'
              and useritem3 = datum;
         if (dupe_cnt = 0) then
            select count(1) into dupe_cnt
               from shippingplate
               where custid = in_custid
                 and item = in_item
                 and useritem3 = datum
                 and status != 'SH';
         end if;
      end if;
      if (dupe_cnt != 0) then
         out_errno := 13;
         out_errmsg := 'No duplicates';
         return;
      end if;
   end if;

-- now we can set the "true" action
	out_action := nvl(fmtaction, 'P');

	if (nvl(length(datum), 0) < rule.minlength) then
		out_errno := 5;
		out_errmsg := 'To few chars';
      return;
   end if;

	if (nvl(length(datum), 0) > rule.maxlength) then
		out_errno := 6;
		out_errmsg := 'To many chars';
      return;
   end if;

-- note that it's safe to use 'x' since the value has been uppercased
	if (rule.datatype = '9') then
      if (replace(translate(datum, '0123456789', 'xxxxxxxxxx'), 'x') is not null) then
			out_errno := 7;
			out_errmsg := 'Only numbers';
         return;
		end if;
	elsif (rule.datatype = 'A') then
      if (replace(translate(datum, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'xxxxxxxxxxxxxxxxxxxxxxxxxx'), 'x')
            is not null) then
			out_errno := 8;
			out_errmsg := 'Only alpha';
         return;
		end if;
	elsif (rule.datatype = 'B') then
      if (replace(translate(datum, '0123456789', 'xxxxxxxxxx'), 'x') is null) then
			out_errno := 9;
			out_errmsg := 'Needs alpha';
         return;
      elsif (replace(translate(datum, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'xxxxxxxxxxxxxxxxxxxxxxxxxx'), 'x')
            is null) then
			out_errno := 10;
			out_errmsg := 'Needs numbers';
         return;
      elsif (replace(translate(datum, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789',
            'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'), 'x') is not null) then
			out_errno := 14;
			out_errmsg := 'No special';
         return;
		end if;
	elsif (rule.datatype = 'M') then
      if not is_value_for_mask(datum, rule.mask) then
			out_errno := 11;
			out_errmsg := 'Not like mask';
         return;
		end if;
	end if;

   if (rtrim(rule.excludemask) is not null)
    and is_value_for_exclude_mask(datum,rule.excludemask) then
			out_errno := 15;
			out_errmsg := 'Exclude Mask';
   end if;

   if (rule.mod10check = 'Y') then
      if not is_check_digit_ok(datum) then
			out_errno := 12;
			out_errmsg := 'Mod 10 failed';
         return;
		end if;
	end if;

exception
   when OTHERS then
   	out_errno := sqlcode;
   	out_errmsg := substr(sqlerrm, 1, 80);
      out_action := 'P';
end verify_format;


procedure verify_asncap_fmt
	(in_custid 		in varchar2,
	 in_item 		in varchar2,
	 in_data_name	in varchar2,
	 in_data_value in varchar2,
    in_orderid    in number,
    in_shipid     in number,
	 out_action    out varchar2,
    out_errno     out number,
    out_errmsg    out varchar2)
is
	fmtruleid formatvalidationrule.ruleid%type := null;
	fmtaction custitem.lotfmtaction%type := null;
	cursor c_item is
		select lotfmtruleid, lotfmtaction,
				 serialfmtruleid, serialfmtaction,
				 user1fmtruleid, user1fmtaction,
				 user2fmtruleid, user2fmtaction,
				 user3fmtruleid, user3fmtaction
			from custitemview
			where custid = in_custid
			  and item = in_item;
	fmtids c_item%rowtype;
	cursor c_rule is
		select nvl(minlength, 0) minlength, nvl(maxlength, 0) maxlength,
             nvl(datatype, 'D') datatype, mask, nvl(dupesok, 'Y') dupesok,
             nvl(mod10check, 'N') mod10check, excludemask
			from formatvalidationrule
			where ruleid = fmtruleid;
	rule c_rule%rowtype;
	rowfound boolean;
	datum varchar(255);
   dupe_cnt pls_integer;
begin
	out_errno := 0;
	out_errmsg := null;
	out_action := 'P';	-- to handle "non-verify" and duplicate errors

-- try item first
	open c_item;
	fetch c_item into fmtids;
	rowfound := c_item%found;
	close c_item;
	if not rowfound then
		out_errno := 1;
		out_errmsg := 'Item not found';
		return;
	end if;

	if (upper(in_data_name) in ('L', 'LD')) then
		fmtruleid := fmtids.lotfmtruleid;
		fmtaction := fmtids.lotfmtaction;
	elsif (upper(in_data_name) = 'S') then
		fmtruleid := fmtids.serialfmtruleid;
		fmtaction := fmtids.serialfmtaction;
	elsif (in_data_name = '1') then
		fmtruleid := fmtids.user1fmtruleid;
		fmtaction := fmtids.user1fmtaction;
	elsif (in_data_name = '2') then
		fmtruleid := fmtids.user2fmtruleid;
		fmtaction := fmtids.user2fmtaction;
	elsif (in_data_name = '3') then
		fmtruleid := fmtids.user3fmtruleid;
		fmtaction := fmtids.user3fmtaction;
	else
		out_errno := 2;
		out_errmsg := 'Bad data type';
		return;
	end if;

-- no rule active, assume data is OK
	if (fmtruleid is null) then
		return;
	end if;

	open c_rule;
	fetch c_rule into rule;
	rowfound := c_rule%found;
	close c_rule;
	if not rowfound then
		out_errno := 4;
		out_errmsg := 'Rule not found';
		return;
	end if;

	datum := upper(in_data_value);

-- need to check for dupes first so user can't override if warning
   if (rule.dupesok = 'N') then
		if (upper(in_data_name) = 'L') then
         select count(1) into dupe_cnt
            from plate
            where custid = in_custid
              and item = in_item
              and type = 'PA'
              and lotnumber = datum;
         if (dupe_cnt = 0) then
            select count(1) into dupe_cnt
               from shippingplate
               where custid = in_custid
                 and item = in_item
                 and lotnumber = datum
                 and status != 'SH';
         end if;
		elsif (upper(in_data_name) = 'S') then
         select count(1) into dupe_cnt
            from plate
            where custid = in_custid
              and item = in_item
              and type = 'PA'
              and serialnumber = datum;
         if (dupe_cnt = 0) then
            select count(1) into dupe_cnt
               from shippingplate
               where custid = in_custid
                 and item = in_item
                 and serialnumber = datum
                 and status != 'SH';
            if (dupe_cnt = 0) then
               select count(1) into dupe_cnt
                  from orderdtlrcpt
                  where custid = in_custid
                    and item = in_item
                    and serialnumber = upper(in_data_value)
                    and orderid = in_orderid
                    and shipid = in_shipid;
            end if;
         end if;
		elsif (in_data_name = '1') then
         select count(1) into dupe_cnt
            from plate
            where custid = in_custid
              and item = in_item
              and type = 'PA'
              and useritem1 = datum;
         if (dupe_cnt = 0) then
            select count(1) into dupe_cnt
               from shippingplate
               where custid = in_custid
                 and item = in_item
                 and useritem1 = datum
                 and status != 'SH';
            if (dupe_cnt = 0) then
               select count(1) into dupe_cnt
                  from orderdtlrcpt
                  where custid = in_custid
                    and item = in_item
                    and useritem1 = upper(in_data_value)
                    and orderid = in_orderid
                    and shipid = in_shipid;
            end if;
         end if;
		elsif (in_data_name = '2') then
         select count(1) into dupe_cnt
            from plate
            where custid = in_custid
              and item = in_item
              and type = 'PA'
              and useritem2 = datum;
         if (dupe_cnt = 0) then
            select count(1) into dupe_cnt
               from shippingplate
               where custid = in_custid
                 and item = in_item
                 and useritem2 = datum
                 and status != 'SH';
            if (dupe_cnt = 0) then
               select count(1) into dupe_cnt
                  from orderdtlrcpt
                  where custid = in_custid
                    and item = in_item
                    and useritem2 = upper(in_data_value)
                    and orderid = in_orderid
                    and shipid = in_shipid;
            end if;
         end if;
		else
         select count(1) into dupe_cnt
            from plate
            where custid = in_custid
              and item = in_item
              and type = 'PA'
              and useritem3 = datum;
         if (dupe_cnt = 0) then
            select count(1) into dupe_cnt
               from shippingplate
               where custid = in_custid
                 and item = in_item
                 and useritem3 = datum
                 and status != 'SH';
            if (dupe_cnt = 0) then
               select count(1) into dupe_cnt
                  from orderdtlrcpt
                  where custid = in_custid
                    and item = in_item
                    and useritem3 = upper(in_data_value)
                    and orderid = in_orderid
                    and shipid = in_shipid;
            end if;
         end if;
      end if;
      if (dupe_cnt != 0) then
         out_errno := 13;
         out_errmsg := 'No duplicates';
         return;
      end if;
   end if;

-- now we can set the "true" action
	out_action := nvl(fmtaction, 'P');

	if (nvl(length(datum), 0) < rule.minlength) then
		out_errno := 5;
		out_errmsg := 'To few chars';
      return;
   end if;

	if (nvl(length(datum), 0) > rule.maxlength) then
		out_errno := 6;
		out_errmsg := 'To many chars';
      return;
   end if;

-- note that it's safe to use 'x' since the value has been uppercased
	if (rule.datatype = '9') then
      if (replace(translate(datum, '0123456789', 'xxxxxxxxxx'), 'x') is not null) then
			out_errno := 7;
			out_errmsg := 'Only numbers';
         return;
		end if;
	elsif (rule.datatype = 'A') then
      if (replace(translate(datum, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'xxxxxxxxxxxxxxxxxxxxxxxxxx'), 'x')
            is not null) then
			out_errno := 8;
			out_errmsg := 'Only alpha';
         return;
		end if;
	elsif (rule.datatype = 'B') then
      if (replace(translate(datum, '0123456789', 'xxxxxxxxxx'), 'x') is null) then
			out_errno := 9;
			out_errmsg := 'Needs alpha';
         return;
      elsif (replace(translate(datum, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'xxxxxxxxxxxxxxxxxxxxxxxxxx'), 'x')
            is null) then
			out_errno := 10;
			out_errmsg := 'Needs numbers';
         return;
      elsif (replace(translate(datum, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789',
            'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'), 'x') is not null) then
			out_errno := 14;
			out_errmsg := 'No special';
         return;
		end if;
	elsif (rule.datatype = 'M') then
      if not is_value_for_mask(datum, rule.mask) then
			out_errno := 11;
			out_errmsg := 'Not like mask';
         return;
		end if;
	end if;

   if (rtrim(rule.excludemask) is not null)
    and is_value_for_exclude_mask(datum,rule.excludemask) then
			out_errno := 16;
			out_errmsg := 'Exclude Mask';
   end if;

   if (rule.mod10check = 'Y') then
      if not is_check_digit_ok(datum) then
			out_errno := 12;
			out_errmsg := 'Mod 10 failed';
         return;
		end if;
	end if;

-- force warning if received in another order
   if (rule.dupesok = 'N') then
      dupe_cnt := get_rcpt_dupes(in_custid, in_item, in_data_name, in_data_value);
      if (dupe_cnt != 0) then
         out_errno := 15;
	      out_action := 'W';
         out_errmsg := 'Already received';
      end if;
   end if;

exception
   when OTHERS then
   	out_errno := sqlcode;
   	out_errmsg := substr(sqlerrm, 1, 80);
      out_action := 'P';
end verify_asncap_fmt;


-- Note: the only difference between this procedure and verify_format, is that
-- here we ignore in_lpid when checking for duplicates
--
-- If in_lpid is null, then duplicate checks are bypassed
--
-- If in_lpid = 'S' then only consider (all) shippingplates
--
-- If in_lpid is for a shippingplate, then consider all other shippingplates
--    There are 2 separate selects since the user may have scanned a master or carton
--    and the "data value" could be on one of it's children
--
-- If in_lpid is for a licenseplate, then consider all other plates and all shippingplates
--
procedure verify_format_lp_exists
	(in_lpid       in varchar2,
    in_custid 		in varchar2,
	 in_item 		in varchar2,
	 in_data_name	in varchar2,
	 in_data_value in varchar2,
	 out_action    out varchar2,
    out_errno     out number,
    out_errmsg    out varchar2)
is
	fmtruleid formatvalidationrule.ruleid%type := null;
	fmtaction custitem.lotfmtaction%type := null;
	cursor c_item is
		select lotfmtruleid, lotfmtaction,
				 serialfmtruleid, serialfmtaction,
				 user1fmtruleid, user1fmtaction,
				 user2fmtruleid, user2fmtaction,
				 user3fmtruleid, user3fmtaction
			from custitemview
			where custid = in_custid
			  and item = in_item;
	fmtids c_item%rowtype;
	cursor c_rule is
		select nvl(minlength, 0) minlength, nvl(maxlength, 0) maxlength,
             nvl(datatype, 'D') datatype, mask, nvl(dupesok, 'Y') dupesok,
             nvl(mod10check, 'N') mod10check, excludemask
			from formatvalidationrule
			where ruleid = fmtruleid;
	rule c_rule%rowtype;
	rowfound boolean;
	datum varchar(255);
   dupe_cnt pls_integer;
begin
	out_errno := 0;
	out_errmsg := null;
	out_action := 'P';	-- to handle "non-verify" and duplicate errors

-- try item first
	open c_item;
	fetch c_item into fmtids;
	rowfound := c_item%found;
	close c_item;
	if not rowfound then
		out_errno := 1;
		out_errmsg := 'Item not found';
		return;
	end if;

	if (upper(in_data_name) in ('L', 'LD')) then
		fmtruleid := fmtids.lotfmtruleid;
		fmtaction := fmtids.lotfmtaction;
	elsif (upper(in_data_name) = 'S') then
		fmtruleid := fmtids.serialfmtruleid;
		fmtaction := fmtids.serialfmtaction;
	elsif (in_data_name = '1') then
		fmtruleid := fmtids.user1fmtruleid;
		fmtaction := fmtids.user1fmtaction;
	elsif (in_data_name = '2') then
		fmtruleid := fmtids.user2fmtruleid;
		fmtaction := fmtids.user2fmtaction;
	elsif (in_data_name = '3') then
		fmtruleid := fmtids.user3fmtruleid;
		fmtaction := fmtids.user3fmtaction;
	else
		out_errno := 2;
		out_errmsg := 'Bad data type';
		return;
	end if;

-- no rule active, assume data is OK
	if (fmtruleid is null) then
		return;
	end if;

	open c_rule;
	fetch c_rule into rule;
	rowfound := c_rule%found;
	close c_rule;
	if not rowfound then
		out_errno := 4;
		out_errmsg := 'Rule not found';
		return;
	end if;

	datum := upper(in_data_value);

-- need to check for dupes first so user can't override if warning
   if ((rule.dupesok = 'N') and (in_lpid is not null)) then
		if (upper(in_data_name) = 'L') then
         if (in_lpid = 'S') then
            select count(1) into dupe_cnt
               from shippingplate
               where custid = in_custid
                 and item = in_item
                 and lotnumber = datum
                 and status != 'SH';
         elsif (substr(in_lpid, -1, 1) = 'S') then
            select count(1) into dupe_cnt
               from shippingplate
               where custid = in_custid
                 and item = in_item
                 and lotnumber = datum
                 and status != 'SH'
                 and lpid not in
                     (select lpid from shippingplate
                        start with lpid = in_lpid
                        connect by prior lpid = parentlpid);
            if (dupe_cnt = 0) then
               select count(1) into dupe_cnt
                  from shippingplate
                  where custid = in_custid
                    and item = in_item
                    and lotnumber = datum
                    and status != 'SH'
                  start with lpid = in_lpid
                  connect by prior lpid = parentlpid;
               if (dupe_cnt = 1) then
                  dupe_cnt := 0;
               end if;
            end if;
         else
            select count(1) into dupe_cnt
               from plate
               where custid = in_custid
                 and item = in_item
                 and type = 'PA'
                 and lotnumber = datum
                 and lpid != in_lpid;
            if (dupe_cnt = 0) then
               select count(1) into dupe_cnt
                  from shippingplate
                  where custid = in_custid
                    and item = in_item
                    and lotnumber = datum
                    and status != 'SH';
            end if;
         end if;
		elsif (upper(in_data_name) = 'S') then
         if (in_lpid = 'S') then
            select count(1) into dupe_cnt
               from shippingplate
               where custid = in_custid
                 and item = in_item
                 and serialnumber = datum
                 and status != 'SH';
         elsif (substr(in_lpid, -1, 1) = 'S') then
            select count(1) into dupe_cnt
               from shippingplate
               where custid = in_custid
                 and item = in_item
                 and serialnumber = datum
                 and status != 'SH'
                 and lpid not in
                     (select lpid from shippingplate
                        start with lpid = in_lpid
                        connect by prior lpid = parentlpid);
            if (dupe_cnt = 0) then
               select count(1) into dupe_cnt
                  from shippingplate
                  where custid = in_custid
                    and item = in_item
                    and serialnumber = datum
                    and status != 'SH'
                  start with lpid = in_lpid
                  connect by prior lpid = parentlpid;
               if (dupe_cnt = 1) then
                  dupe_cnt := 0;
               end if;
            end if;
         else
            select count(1) into dupe_cnt
               from plate
               where custid = in_custid
                 and item = in_item
                 and type = 'PA'
                 and serialnumber = datum
                 and lpid != in_lpid;
            if (dupe_cnt = 0) then
               select count(1) into dupe_cnt
                  from shippingplate
                  where custid = in_custid
                    and item = in_item
                    and serialnumber = datum
                    and status != 'SH';
            end if;
         end if;
		elsif (in_data_name = '1') then
         if (in_lpid = 'S') then
            select count(1) into dupe_cnt
               from shippingplate
               where custid = in_custid
                 and item = in_item
                 and useritem1 = datum
                 and status != 'SH';
         elsif (substr(in_lpid, -1, 1) = 'S') then
            select count(1) into dupe_cnt
               from shippingplate
               where custid = in_custid
                 and item = in_item
                 and useritem1 = datum
                 and status != 'SH'
                 and lpid not in
                     (select lpid from shippingplate
                        start with lpid = in_lpid
                        connect by prior lpid = parentlpid);
            if (dupe_cnt = 0) then
               select count(1) into dupe_cnt
                  from shippingplate
                  where custid = in_custid
                    and item = in_item
                    and useritem1 = datum
                    and status != 'SH'
                  start with lpid = in_lpid
                  connect by prior lpid = parentlpid;
               if (dupe_cnt = 1) then
                  dupe_cnt := 0;
               end if;
            end if;
         else
            select count(1) into dupe_cnt
               from plate
               where custid = in_custid
                 and item = in_item
                 and type = 'PA'
                 and useritem1 = datum
                 and lpid != in_lpid;
            if (dupe_cnt = 0) then
               select count(1) into dupe_cnt
                  from shippingplate
                  where custid = in_custid
                    and item = in_item
                    and useritem1 = datum
                    and status != 'SH';
            end if;
         end if;
		elsif (in_data_name = '2') then
         if (in_lpid = 'S') then
            select count(1) into dupe_cnt
               from shippingplate
               where custid = in_custid
                 and item = in_item
                 and useritem2 = datum
                 and status != 'SH';
         elsif (substr(in_lpid, -1, 1) = 'S') then
            select count(1) into dupe_cnt
               from shippingplate
               where custid = in_custid
                 and item = in_item
                 and useritem2 = datum
                 and status != 'SH'
                 and lpid not in
                     (select lpid from shippingplate
                        start with lpid = in_lpid
                        connect by prior lpid = parentlpid);
            if (dupe_cnt = 0) then
               select count(1) into dupe_cnt
                  from shippingplate
                  where custid = in_custid
                    and item = in_item
                    and useritem2 = datum
                    and status != 'SH'
                  start with lpid = in_lpid
                  connect by prior lpid = parentlpid;
               if (dupe_cnt = 1) then
                  dupe_cnt := 0;
               end if;
            end if;
         else
            select count(1) into dupe_cnt
               from plate
               where custid = in_custid
                 and item = in_item
                 and type = 'PA'
                 and useritem2 = datum
                 and lpid != in_lpid;
            if (dupe_cnt = 0) then
               select count(1) into dupe_cnt
                  from shippingplate
                  where custid = in_custid
                    and item = in_item
                    and useritem2 = datum
                    and status != 'SH';
            end if;
         end if;
		else
         if (in_lpid = 'S') then
            select count(1) into dupe_cnt
               from shippingplate
               where custid = in_custid
                 and item = in_item
                 and useritem3 = datum
                 and status != 'SH';
         elsif (substr(in_lpid, -1, 1) = 'S') then
            select count(1) into dupe_cnt
               from shippingplate
               where custid = in_custid
                 and item = in_item
                 and useritem3 = datum
                 and status != 'SH'
                 and lpid not in
                     (select lpid from shippingplate
                        start with lpid = in_lpid
                        connect by prior lpid = parentlpid);
            if (dupe_cnt = 0) then
               select count(1) into dupe_cnt
                  from shippingplate
                  where custid = in_custid
                    and item = in_item
                    and useritem3 = datum
                    and status != 'SH'
                  start with lpid = in_lpid
                  connect by prior lpid = parentlpid;
               if (dupe_cnt = 1) then
                  dupe_cnt := 0;
               end if;
            end if;
         else
            select count(1) into dupe_cnt
               from plate
               where custid = in_custid
                 and item = in_item
                 and type = 'PA'
                 and useritem3 = datum
                 and lpid != in_lpid;
            if (dupe_cnt = 0) then
               select count(1) into dupe_cnt
                  from shippingplate
                  where custid = in_custid
                    and item = in_item
                    and useritem3 = datum
                    and status != 'SH';
            end if;
         end if;
      end if;
      if (dupe_cnt != 0) then
         out_errno := 13;
         out_errmsg := 'No duplicates';
         return;
      end if;
   end if;

-- now we can set the "true" action
	out_action := nvl(fmtaction, 'P');

	if (nvl(length(datum), 0) < rule.minlength) then
		out_errno := 5;
		out_errmsg := 'To few chars';
      return;
   end if;

	if (nvl(length(datum), 0) > rule.maxlength) then
		out_errno := 6;
		out_errmsg := 'To many chars';
      return;
   end if;

-- note that it's safe to use 'x' since the value has been uppercased
	if (rule.datatype = '9') then
      if (replace(translate(datum, '0123456789', 'xxxxxxxxxx'), 'x') is not null) then
			out_errno := 7;
			out_errmsg := 'Only numbers';
         return;
		end if;
	elsif (rule.datatype = 'A') then
      if (replace(translate(datum, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'xxxxxxxxxxxxxxxxxxxxxxxxxx'), 'x')
            is not null) then
			out_errno := 8;
			out_errmsg := 'Only alpha';
         return;
		end if;
	elsif (rule.datatype = 'B') then
      if (replace(translate(datum, '0123456789', 'xxxxxxxxxx'), 'x') is null) then
			out_errno := 9;
			out_errmsg := 'Needs alpha';
         return;
      elsif (replace(translate(datum, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'xxxxxxxxxxxxxxxxxxxxxxxxxx'), 'x')
            is null) then
			out_errno := 10;
			out_errmsg := 'Needs numbers';
         return;
      elsif (replace(translate(datum, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789',
            'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'), 'x') is not null) then
			out_errno := 14;
			out_errmsg := 'No special';
         return;
		end if;
	elsif (rule.datatype = 'M') then
      if not is_value_for_mask(datum, rule.mask) then
			out_errno := 11;
			out_errmsg := 'Not like mask';
         return;
		end if;
	end if;

   if (rtrim(rule.excludemask) is not null)
    and is_value_for_exclude_mask(datum,rule.excludemask) then
			out_errno := 15;
			out_errmsg := 'Exclude Mask';
   end if;

   if (rule.mod10check = 'Y') then
      if not is_check_digit_ok(datum) then
			out_errno := 12;
			out_errmsg := 'Mod 10 failed';
         return;
		end if;
	end if;

exception
   when OTHERS then
   	out_errno := sqlcode;
   	out_errmsg := substr(sqlerrm, 1, 80);
      out_action := 'P';
end verify_format_lp_exists;


/*
Note: the duplicate check logic is different that the above procedure
(the function is verifying existing LiPs so a record count of one is okay,
whereas the procedure is validating for new data so only a count of zero
is okay
*/
function is_valid_format
(in_custid      in varchar2,
 in_item        in varchar2,
 in_data_name	in varchar2,
 in_data_value  in varchar2
) return varchar2
is

fmtruleid formatvalidationrule.ruleid%type;
fmtaction custitem.lotfmtaction%type;
fmtids custitem%rowtype;
rule formatvalidationrule%rowtype;
datum varchar(255);
lp_dupe_cnt pls_integer;
sp_dupe_cnt pls_integer;
digit_sum pls_integer;
tmp pls_integer;

begin

fmtids := null;
select
lotfmtruleid,
lotfmtaction,
serialfmtruleid,
serialfmtaction,
user1fmtruleid,
user1fmtaction,
user2fmtruleid,
user2fmtaction,
user3fmtruleid,
user3fmtaction
into
fmtids.lotfmtruleid,
fmtids.lotfmtaction,
fmtids.serialfmtruleid,
fmtids.serialfmtaction,
fmtids.user1fmtruleid,
fmtids.user1fmtaction,
fmtids.user2fmtruleid,
fmtids.user2fmtaction,
fmtids.user3fmtruleid,
fmtids.user3fmtaction
from custitemview
where custid = in_custid
  and item = in_item;
if sql%rowcount = 0 then
  return 'Item Not Found';
end if;

if (upper(in_data_name) = 'L') then
        fmtruleid := fmtids.lotfmtruleid;
        fmtaction := fmtids.lotfmtaction;
elsif (upper(in_data_name) = 'S') then
        fmtruleid := fmtids.serialfmtruleid;
        fmtaction := fmtids.serialfmtaction;
elsif (in_data_name = '1') then
        fmtruleid := fmtids.user1fmtruleid;
        fmtaction := fmtids.user1fmtaction;
elsif (in_data_name = '2') then
        fmtruleid := fmtids.user2fmtruleid;
        fmtaction := fmtids.user2fmtaction;
elsif (in_data_name = '3') then
        fmtruleid := fmtids.user3fmtruleid;
        fmtaction := fmtids.user3fmtaction;
else
  return 'Bad data type';
end if;

-- no rule active, assume data is OK
if (fmtruleid is null) then
  return null;
end if;

select
  nvl(minlength, 0) minlength,
  nvl(maxlength, 0) maxlength,
  nvl(datatype, 'D') datatype,
  mask,
  nvl(dupesok, 'Y') dupesok,
  nvl(mod10check, 'N') mod10check,
  excludemask
  into
  rule.minlength,
  rule.maxlength,
  rule.datatype,
  rule.mask,
  rule.dupesok,
  rule.mod10check,
  rule.excludemask
  from formatvalidationrule
 where ruleid = fmtruleid;
if sql%rowcount = 0 then
  return 'Rule not found';
end if;

datum := upper(in_data_value);

-- need to check for dupes first so user can't override if warning
   if (rule.dupesok = 'N') then
		if (upper(in_data_name) = 'L') then
         select count(1) into lp_dupe_cnt
            from plate
            where custid = in_custid
              and item = in_item
              and lotnumber = datum;
         select count(1) into sp_dupe_cnt
            from shippingplate
            where custid = in_custid
              and item = in_item
              and lotnumber = datum
              and status != 'SH';
		elsif (upper(in_data_name) = 'S') then
         select count(1) into lp_dupe_cnt
            from plate
            where custid = in_custid
              and item = in_item
              and serialnumber = datum;
         select count(1) into sp_dupe_cnt
            from shippingplate
            where custid = in_custid
              and item = in_item
              and serialnumber = datum
              and status != 'SH';
		elsif (in_data_name = '1') then
         select count(1) into lp_dupe_cnt
            from plate
            where custid = in_custid
              and item = in_item
              and useritem1 = datum;
         select count(1) into sp_dupe_cnt
            from shippingplate
            where custid = in_custid
              and item = in_item
              and useritem1 = datum
              and status != 'SH';
		elsif (in_data_name = '2') then
         select count(1) into lp_dupe_cnt
            from plate
            where custid = in_custid
              and item = in_item
              and useritem2 = datum;
         select count(1) into sp_dupe_cnt
            from shippingplate
            where custid = in_custid
              and item = in_item
              and useritem2 = datum
              and status != 'SH';
		else
         select count(1) into lp_dupe_cnt
            from plate
            where custid = in_custid
              and item = in_item
              and useritem3 = datum;
         select count(1) into sp_dupe_cnt
            from shippingplate
            where custid = in_custid
              and item = in_item
              and useritem3 = datum
              and status != 'SH';
      end if;
      if ((lp_dupe_cnt > 1) or (sp_dupe_cnt > 1)) then
         return 'No duplicates';
      end if;
   end if;

   if (nvl(length(datum), 0) < rule.minlength) then
     return 'To few chars';
   end if;

   if (nvl(length(datum), 0) > rule.maxlength) then
     return 'To many chars';
   end if;

-- note that it's safe to use 'x' since the value has been uppercased
   if (rule.datatype = '9') then
      if (replace(translate(datum, '0123456789', 'xxxxxxxxxx'), 'x') is not null) then
        return 'Only numbers';
      end if;
   elsif (rule.datatype = 'A') then
      if (replace(translate(datum, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'xxxxxxxxxxxxxxxxxxxxxxxxxx'), 'x')
            is not null) then
       return 'Only alpha';
      end if;
	elsif (rule.datatype = 'B') then
      if (replace(translate(datum, '0123456789', 'xxxxxxxxxx'), 'x') is null) then
         return 'Needs alpha';
      elsif (replace(translate(datum, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'xxxxxxxxxxxxxxxxxxxxxxxxxx'), 'x')
            is null) then
	      return 'Needs numbers';
      elsif (replace(translate(datum, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789',
            'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'), 'x') is not null) then
			return 'No specials';
		end if;
	elsif (rule.datatype = 'M') then
      if not is_value_for_mask(datum, rule.mask) then
         return 'Not like mask';
		end if;
	end if;

   if (rtrim(rule.excludemask) is not null)
    and is_value_for_exclude_mask(datum,rule.excludemask) then
         return 'Exclude Mask';
   end if;

   if (rule.mod10check = 'Y') then
      if not is_check_digit_ok(datum) then
         return 'Mod 10 failed';
		end if;
	end if;

   return null;
exception when OTHERS then
  return 'Exception';
end is_valid_format;

procedure verify_orderedlot_format
	(in_custid 		in varchar2,
	 in_item 		  in varchar2,
	 in_lotnumber in varchar2,
	 out_errno    out number, 	 
   out_errmsg   out varchar2)
is
	fmtruleid formatvalidationrule.ruleid%type := null;

	cursor c_item is
		select lotfmtruleid, lotfmtaction,
				 serialfmtruleid, serialfmtaction,
				 user1fmtruleid, user1fmtaction,
				 user2fmtruleid, user2fmtaction,
				 user3fmtruleid, user3fmtaction
			from custitemview
			where custid = in_custid
			  and item = in_item;

	fmtids c_item%rowtype;

	cursor c_rule is
		select nvl(minlength, 0) minlength, nvl(maxlength, 0) maxlength,
             nvl(datatype, 'D') datatype, mask, nvl(dupesok, 'Y') dupesok,
             nvl(mod10check, 'N') mod10check, excludemask
			from formatvalidationrule
			where ruleid = fmtruleid;
	rule c_rule%rowtype;
	
	rowfound boolean;
  datum varchar(255); 
begin
	out_errno := 0;
	out_errmsg := null;
	
	-- try item first
	open c_item;
	fetch c_item into fmtids;
	rowfound := c_item%found;
	close c_item;
	if not rowfound then
		out_errno := 1;
		out_errmsg := 'Item not found';
		return;
	end if;

  fmtruleid := fmtids.lotfmtruleid;

-- no rule active, assume data is OK
  if (fmtruleid is null) then
		return;
	end if;

	open c_rule;
	fetch c_rule into rule;
	rowfound := c_rule%found;
	close c_rule;
	if not rowfound then
		out_errno := 4;
		out_errmsg := 'Rule not found';
		return;
	end if;

	datum := upper(in_lotnumber);

	if (nvl(length(datum), 0) < rule.minlength) then
		out_errno := 5;
		out_errmsg := 'To few chars';
    return;
  end if;

	if (nvl(length(datum), 0) > rule.maxlength) then
		out_errno := 6;
		out_errmsg := 'To many chars';
    return;
  end if;

-- note that it's safe to use 'x' since the value has been uppercased
	if (rule.datatype = '9') then
    if (replace(translate(datum, '0123456789', 'xxxxxxxxxx'), 'x') is not null) then
		  out_errno := 7;
			out_errmsg := 'Only numbers';
      return;
		end if;
	elsif (rule.datatype = 'A') then
    if (replace(translate(datum, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'xxxxxxxxxxxxxxxxxxxxxxxxxx'), 'x') is not null) then
			out_errno := 8;
			out_errmsg := 'Only alpha';
      return;
		end if;
	elsif (rule.datatype = 'B') then
    if (replace(translate(datum, '0123456789', 'xxxxxxxxxx'), 'x') is null) then
		  out_errno := 9;
			out_errmsg := 'Needs alpha';
      return;
    elsif (replace(translate(datum, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'xxxxxxxxxxxxxxxxxxxxxxxxxx'), 'x') is null) then
			out_errno := 10;
			out_errmsg := 'Needs numbers';
       return;
    elsif (replace(translate(datum, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'), 'x') is not null) then
		  out_errno := 14;
			out_errmsg := 'No special';
      return;
		end if;
	elsif (rule.datatype = 'M') then
    if not is_value_for_mask(datum, rule.mask) then
		  out_errno := 11;
			out_errmsg := 'Not like mask';
      return;
		end if;
	end if;

  if (rtrim(rule.excludemask) is not null)
      and is_value_for_exclude_mask(datum,rule.excludemask) then
	  out_errno := 15;
		out_errmsg := 'Exclude Mask';
  end if;

  if (rule.mod10check = 'Y') then
    if not is_check_digit_ok(datum) then
		  out_errno := 12;
			out_errmsg := 'Mod 10 failed';
      return;
		end if;
	end if;

exception
   when OTHERS then
   	out_errno := sqlcode;
   	out_errmsg := substr(sqlerrm, 1, 80);
end verify_orderedlot_format;

end formatvalidation;
/

show errors package body formatvalidation;
exit;
