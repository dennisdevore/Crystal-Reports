--
-- $Id$
--
update
   (select L.putawayseq l_putawayseq,
	        L.pickingseq l_pickingseq,
           L.lastupdate l_lastupdate,
           L.lastuser   l_lastuser,
           P.putawayseq p_putawayseq
      from location L, psq_location P
      where L.facility = P.facility
        and L.locid = P.locid)
   set l_putawayseq = p_putawayseq,
	    l_pickingseq = p_putawayseq,
       l_lastuser = 'SYSTEM',
       l_lastupdate = sysdate;
