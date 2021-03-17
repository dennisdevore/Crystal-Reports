--
-- $Id$
--
delete
from systemdefaults
where defaultid='PDFBOLURL';

insert into systemdefaults values ('WEBPDFPATH', null, 'SUP', sysdate);

exit;
