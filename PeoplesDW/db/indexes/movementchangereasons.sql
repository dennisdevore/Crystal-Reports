--
-- $Id$
--
drop index movementchangereasons_idx;

create unique index movementchangereasons_idx
   on movementchangereasons(code);

exit;
