--
-- $Id$
--
alter table customer add
(sip_wsa_945_summarize_lots_yn char(1)
);
update customer
   set sip_wsa_945_summarize_lots_yn = 'N'
 where sip_wsa_945_summarize_lots_yn is null;
commit;
--exit;
