--
-- $Id$
--
alter table zone add
(
   deconsolidation char(1) default 'N'
);

exit;
