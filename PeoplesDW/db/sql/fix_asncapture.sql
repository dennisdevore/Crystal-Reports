--
-- $Id$
--
update customer set
       serialasncapture = 'N',
       user1asncapture = 'N',
       user2asncapture = 'N',
       user3asncapture = 'N';

update custproductgroup set
       serialasncapture = 'C',
       user1asncapture = 'C',
       user2asncapture = 'C',
       user3asncapture = 'C';

update custitem set
       serialasncapture = 'C',
       user1asncapture = 'C',
       user2asncapture = 'C',
       user3asncapture = 'C';

commit;
