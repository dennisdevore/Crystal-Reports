--
-- $Id$
--
update orderdtl
   set linestatus = 'A',
       lastuser = 'SYNAPSE',
       lastupdate = sysdate
   where orderid in
(22855, 22856, 22857, 22858, 22887, 23078, 23079, 23080, 23081,
 23082, 23083, 23084, 23086, 23087, 23088, 23089, 23090, 23091,
 23092, 23093, 23094, 23095, 23096, 23097, 23098, 23099, 23100,
 23101, 23102, 23103, 23104);

update orderhdr
   set orderstatus = '0',
       commitstatus = '0',
       rejectcode = null,
       rejecttext = null,
       edicancelpending = null,
       lastuser = 'SYNAPSE',
       lastupdate = sysdate
   where orderid in
(22855, 22856, 22857, 22858, 22887, 23078, 23079, 23080, 23081,
 23082, 23083, 23084, 23086, 23087, 23088, 23089, 23090, 23091,
 23092, 23093, 23094, 23095, 23096, 23097, 23098, 23099, 23100,
 23101, 23102, 23103, 23104)
   and rejectcode = 400;

update orderhdr
   set orderstatus = '0',
       commitstatus = '0',
       lastuser = 'SYNAPSE',
       lastupdate = sysdate
   where orderid in
(22855, 22856, 22857, 22858, 22887, 23078, 23079, 23080, 23081,
 23082, 23083, 23084, 23086, 23087, 23088, 23089, 23090, 23091,
 23092, 23093, 23094, 23095, 23096, 23097, 23098, 23099, 23100,
 23101, 23102, 23103, 23104)
   and rejectcode != 400;
