--
-- $Id$
--
create or replace PACKAGE zqueuemsg
IS
-- DQ Modes 
DQ_REMOVE       CONSTANT        integer := 0;
DQ_BROWSE       CONSTANT        integer := 1;
DQ_LOCKED       CONSTANT        integer := 2;

-- Wait Modes
WT_NOWAIT       CONSTANT        integer := -1;
WT_FOREVER      CONSTANT        integer := null;


------------------------------------------------------------------------
--
-- send - send a message using Oracle AQ system
--
------------------------------------------------------------------------
FUNCTION send
(
    in_queue        IN varchar2,    -- name of the queue to transmit on
    in_trans        IN varchar2,    -- transaction for message
    in_message      IN varchar2,    -- the message to send
    in_priority     IN integer,     -- priority to queue this message at
    in_correlation  IN varchar2     -- correlation field for filtering
)
RETURN integer;
------------------------------------------------------------------------
--
-- send - send a message using Oracle AQ system
--
------------------------------------------------------------------------
FUNCTION send
(
    in_queue        IN varchar2,    -- name of the queue to transmit on
    in_message      IN varchar2     -- the message to send
)
RETURN integer;

------------------------------------------------------------------------
--
-- send_commit - send a message using Oracle AQ system then commit
--
------------------------------------------------------------------------
FUNCTION send_commit
(
    in_queue        IN varchar2,    -- name of the queue to transmit on
    in_trans        IN varchar2,    -- transaction for message
    in_message      IN varchar2,    -- the message to send
    in_priority     IN integer,     -- priority to queue this message at
    in_correlation  IN varchar2     -- correlation field for filtering
)
RETURN integer;

------------------------------------------------------------------------
--
-- receive - receive a message using Oracle AQ system
--
------------------------------------------------------------------------
FUNCTION receive
(
    in_queue        IN varchar2,    -- name of the queue to receive on
    in_correlation  IN varchar2,    -- correlation field for filtering
    in_wait         IN integer,     -- time to wait for a response
    in_dq_mode      IN integer,     -- type of dequeueing to do
    out_trans       OUT varchar2,   -- transaction for message
    out_message     OUT varchar2    -- the message we got (if we got one)
)
RETURN integer;

------------------------------------------------------------------------
--
-- receive - receive a message using Oracle AQ system
--
------------------------------------------------------------------------
FUNCTION receive
(
    in_queue        IN varchar2,    -- name of the queue to receive on
    out_message     OUT varchar2,   -- the message we got (if we got one)
    in_wait         IN integer := WT_FOREVER    -- optional waittime
)
RETURN integer;
------------------------------------------------------------------------
--
-- receive_commit - receive a message using Oracle AQ system, then commit
--
------------------------------------------------------------------------
FUNCTION receive_commit
(
    in_queue        IN varchar2,    -- name of the queue to receive on
    in_correlation  IN varchar2,    -- correlation field for filtering
    in_wait         IN integer,     -- time to wait for a response
    in_dq_mode      IN integer,     -- type of dequeueing to do
    out_trans       OUT varchar2,   -- transaction for message
    out_message     OUT varchar2    -- the message we got (if we got one)
)
RETURN integer;

------------------------------------------------------------------------
--
-- get_field - parse the returned string
--
------------------------------------------------------------------------

FUNCTION get_field
(
   in_str varchar2, 
   in_pos number
)
return varchar2;

FUNCTION get_field_no_null
(
   in_str varchar2, 
   in_pos number
)
return varchar2;


------------------------------------------------------------------------
--
-- send - send a message using Oracle AQ system
--
------------------------------------------------------------------------
FUNCTION bsend
(
    in_queue        IN varchar2,    -- name of the queue to transmit on
    in_trans        IN varchar2,    -- transaction for message
    in_message      IN varchar2,    -- the message to send
    in_priority     IN integer,     -- priority to queue this message at
    in_correlation  IN varchar2,     -- correlation field for filtering
    in_fileblob     in blob
)
RETURN integer;
------------------------------------------------------------------------
--
-- send - send a message using Oracle AQ system
--
------------------------------------------------------------------------
FUNCTION bsend
(
    in_queue        IN varchar2,    -- name of the queue to transmit on
    in_message      IN varchar2,     -- the message to send
    in_fileblob     in blob
)
RETURN integer;

------------------------------------------------------------------------
--
-- bsend_commit - send a message using Oracle AQ system then commit
--
------------------------------------------------------------------------
FUNCTION bsend_commit
(
    in_queue        IN varchar2,    -- name of the queue to transmit on
    in_trans        IN varchar2,    -- transaction for message
    in_message      IN varchar2,    -- the message to send
    in_priority     IN integer,     -- priority to queue this message at
    in_correlation  IN varchar2,     -- correlation field for filtering
    in_fileblob     in blob
)
RETURN integer;

------------------------------------------------------------------------
--
-- breceive - receive a message using Oracle AQ system
--
------------------------------------------------------------------------
FUNCTION breceive
(
    in_queue        IN varchar2,    -- name of the queue to receive on
    in_correlation  IN varchar2,    -- correlation field for filtering
    in_wait         IN integer,     -- time to wait for a response
    in_dq_mode      IN integer,     -- type of dequeueing to do
    out_trans       OUT varchar2,   -- transaction for message
    out_message     OUT varchar2,    -- the message we got (if we got one)
    out_fileblob    out blob
)
RETURN integer;

------------------------------------------------------------------------
--
-- breceive - receive a message using Oracle AQ system
--
------------------------------------------------------------------------
FUNCTION breceive
(
    in_queue        IN varchar2,    -- name of the queue to receive on
    out_message     OUT varchar2,   -- the message we got (if we got one)
    out_fileblob    out blob,
    in_wait         IN integer := WT_FOREVER    -- optional waittime
)
RETURN integer;
------------------------------------------------------------------------
--
-- breceive_commit - receive a message using Oracle AQ system, then commit
--
------------------------------------------------------------------------
FUNCTION breceive_commit
(
    in_queue        IN varchar2,    -- name of the queue to receive on
    in_correlation  IN varchar2,    -- correlation field for filtering
    in_wait         IN integer,     -- time to wait for a response
    in_dq_mode      IN integer,     -- type of dequeueing to do
    out_trans       OUT varchar2,   -- transaction for message
    out_message     OUT varchar2,    -- the message we got (if we got one)
    out_fileblob    out blob
)
RETURN integer;

END zqueuemsg;
/
show errors package zqueuemsg;

exit;
