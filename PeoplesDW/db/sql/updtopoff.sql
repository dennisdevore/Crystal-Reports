--
-- $Id$
--
update itempickfronts
set topoffqty = replenishqty,
    topoffuom = replenishuom
where topoffuom is null
   or topoffqty is null;
commit;
exit;
