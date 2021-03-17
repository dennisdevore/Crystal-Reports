--
-- $Id$
--
drop public synonym zmn;
create public synonym zmn for alps.zmanifest;

drop public synonym multishipdtl;
create public synonym multishipdtl for alps.multishipdtl;

drop public synonym multishiphdr;
create public synonym multishiphdr for alps.multishiphdr;

drop public synonym worldshipdtl;
create public synonym worldshipdtl for alps.worldshipdtl;

exit;
