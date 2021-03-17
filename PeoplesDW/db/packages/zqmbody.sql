CREATE OR REPLACE PACKAGE BODY zqueuemsg
IS
--
-- $Id$
--
-- ******************************************************************
-- *                                                                *
-- *    CONSTANTS                                                   *
-- *                                                                *
-- ******************************************************************

hexr        CONSTANT varchar2(16) := '0123456789ABCDEF';
-- message offsets
MOS_type    CONSTANT integer := 1;
MOS_length  CONSTANT integer := 5;
MOS_message_ID CONSTANT integer := 9;
MOS_port    CONSTANT integer := 13;
MOS_status  CONSTANT integer := 17;


-- ******************************************************************
-- *                                                                *
-- *    CURSORS                                                     *
-- *                                                                *
-- ******************************************************************

-- ******************************************************************
-- *                                                                *
-- *  MESSAGING FUNCTIONS                                           *
-- *                                                                *
-- ******************************************************************


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
RETURN integer
IS
    msg_p   dbms_aq.message_properties_t;
    enq_o   dbms_aq.enqueue_options_t;
    msgid   raw(16);
    msg    qmsg;
BEGIN

    msg_p.priority := in_priority;
    msg_p.correlation := in_correlation;

    msg := qmsg(in_trans, in_message);

    dbms_aq.enqueue(
        queue_name => 'alps.'||in_queue,
        message_properties => msg_p,
        enqueue_options  => enq_o,
        payload => msg,
        msgid => msgid);

    return 1;
EXCEPTION when others then
    if sqlcode = -25228 then
        return -1;
    else
        raise;
    end if;
END send;

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
RETURN integer
IS
BEGIN
    return send(in_queue,'MSG',in_message,1,null);

END send;

------------------------------------------------------------------------
--
-- send - send a message using Oracle AQ system by calling zqm.send
--        then commit
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
RETURN integer
is PRAGMA AUTONOMOUS_TRANSACTION;
rc integer;
BEGIN
    rc := zqm.send(in_queue,in_trans,in_message,in_priority,in_correlation);
    commit;
    return rc;
EXCEPTION when others then
    rollback;
    if sqlcode = -25228 then
        return -1;
    else
        raise;
    end if;
END send_commit;



------------------------------------------------------------------------
--
-- receive - receive a message using Oracle AQ system
--      returns a -1 if wait expired
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
RETURN integer
IS
    msg_p   dbms_aq.message_properties_t;
    deq_o   dbms_aq.dequeue_options_t;
    msgid   raw(16);
    msg qmsg;
BEGIN
    deq_o.correlation := in_correlation;
    deq_o.navigation := dbms_aq.first_message;
    if in_wait is not null then
        if in_wait < 0 then
            deq_o.wait := dbms_aq.NO_WAIT;
        else
            deq_o.wait := in_wait;
        end if;
    end if;
    if in_dq_mode = 0 then
        deq_o.dequeue_mode := dbms_aq.remove;
    elsif in_dq_mode = 1 then
        deq_o.dequeue_mode := dbms_aq.browse;
        deq_o.navigation := dbms_aq.next_message;
    elsif in_dq_mode = 2 then
        deq_o.dequeue_mode := dbms_aq.locked;
    end if;

    dbms_aq.dequeue(
        queue_name => 'alps.'||in_queue,
        message_properties => msg_p,
        dequeue_options  => deq_o,
        payload => msg,
        msgid => msgid);

    out_trans := msg.trans;
    out_message := msg.message;


    return 1;
EXCEPTION when others then
    if sqlcode = -25228 then
        return -1;
    else
        raise;
    end if;
END receive;

------------------------------------------------------------------------
--
-- receive - receive a message using Oracle AQ system
--      returns a -1 if wait expired
--
------------------------------------------------------------------------
FUNCTION receive
(
    in_queue        IN varchar2,    -- name of the queue to receive on
    out_message     OUT varchar2,   -- the message we got (if we got one)
    in_wait         IN integer := WT_FOREVER    -- optional waittime
)
RETURN integer
IS
l_trans varchar2(20);

BEGIN
    return receive(in_queue,null,in_wait,DQ_REMOVE,l_trans,out_message);
END receive;

------------------------------------------------------------------------
--
-- receive - receive a message using Oracle AQ system by calling
--           zqm.receive, then commit
--
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
RETURN integer
is PRAGMA AUTONOMOUS_TRANSACTION;
   rc integer;
begin
   rc := zqm.receive(in_queue,in_correlation, in_wait, in_dq_mode, out_trans, out_message);
   commit;
   return rc;

EXCEPTION when others then
    rollback;
    if sqlcode = -25228 then
        return -1;
    else
        raise;
    end if;
END receive_commit;


------------------------------------------------------------------------
--
-- get_field parse the returned string
--
--
------------------------------------------------------------------------

FUNCTION get_field(in_str varchar2, in_pos number)
return varchar2
IS
 l_type  varchar2(20);
 l_data  varchar2(2000);
 pos integer;
 endpos integer;
 ix integer;

BEGIN

    ix := 0;
    l_data := null;
    pos := 1;
    loop
        ix := ix + 1;
        endpos := instr(substr(in_str,pos),chr(9));
        exit when endpos = 0;
        if ix >= in_pos then
            if endpos = 0 then
                l_data := substr(in_str,pos);
            else
                l_data := substr(in_str,pos,endpos-1);
            end if;
            return l_data;
        end if;
        pos := pos + endpos;

    end loop;

    return NULL;

END;

FUNCTION get_field_no_null(in_str varchar2, in_pos number)
return varchar2
IS
 l_type  varchar2(20);
 l_data  varchar2(2000);
 pos integer;
 endpos integer;
 ix integer;

BEGIN

    return(nvl(get_field(in_str,in_pos),chr(9)));

END;

------------------------------------------------------------------------
--
-- bsend - send a message using Oracle AQ system
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
RETURN integer
IS
    msg_p   dbms_aq.message_properties_t;
    enq_o   dbms_aq.enqueue_options_t;
    msgid   raw(16);
    msg    qmsg_blob;
    lob_loc      BLOB;
    v_queue_table  varchar2(100);
BEGIN

    msg_p.priority := in_priority;
    msg_p.correlation := in_correlation;

    --msg := qmsg_blob(in_trans, in_message, empty_blob());
    msg := qmsg_blob(in_trans, in_message, in_fileblob);

    dbms_aq.enqueue(
        queue_name => 'alps.'||in_queue,
        message_properties => msg_p,
        enqueue_options  => enq_o,
        payload => msg,
        msgid => msgid);
      
    /*
    select queue_table into v_queue_table
    from user_queues where upper(name) = upper(in_queue);
    
    execute immediate 'select user_data.file_object from ' || v_queue_table || ' where msg_id = :msg_id'
    into lob_loc
    using msgid;

    dbms_lob.copy(lob_loc, in_fileblob, dbms_lob.getlength(in_fileblob));
    */
    
    return 1;
EXCEPTION when others then
    if sqlcode = -25228 then
        return -1;
    else
        raise;
    end if;
END bsend;

------------------------------------------------------------------------
--
-- bsend - send a message using Oracle AQ system
--
------------------------------------------------------------------------
FUNCTION bsend
(
    in_queue        IN varchar2,    -- name of the queue to transmit on
    in_message      IN varchar2,     -- the message to send
    in_fileblob     in blob
)
RETURN integer
IS
BEGIN
    return bsend(in_queue,'MSG',in_message,1,null,in_fileblob);

END bsend;

------------------------------------------------------------------------
--
-- bsend - send a message using Oracle AQ system by calling zqm.send
--        then commit
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
RETURN integer
is PRAGMA AUTONOMOUS_TRANSACTION;
rc integer;
BEGIN
    rc := zqm.bsend(in_queue,in_trans,in_message,in_priority,in_correlation,in_fileblob);
    commit;
    return rc;
EXCEPTION when others then
    rollback;
    if sqlcode = -25228 then
        return -1;
    else
        raise;
    end if;
END bsend_commit;

------------------------------------------------------------------------
--
-- breceive - receive a message using Oracle AQ system
--      returns a -1 if wait expired
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
RETURN integer
IS
    msg_p   dbms_aq.message_properties_t;
    deq_o   dbms_aq.dequeue_options_t;
    msgid   raw(16);
    msg qmsg_blob;
BEGIN
    out_fileblob := empty_blob();
    
    deq_o.correlation := in_correlation;
    deq_o.navigation := dbms_aq.first_message;
    if in_wait is not null then
        if in_wait < 0 then
            deq_o.wait := dbms_aq.NO_WAIT;
        else
            deq_o.wait := in_wait;
        end if;
    end if;
    if in_dq_mode = 0 then
        deq_o.dequeue_mode := dbms_aq.remove;
    elsif in_dq_mode = 1 then
        deq_o.dequeue_mode := dbms_aq.browse;
        deq_o.navigation := dbms_aq.next_message;
    elsif in_dq_mode = 2 then
        deq_o.dequeue_mode := dbms_aq.locked;
    end if;

    dbms_aq.dequeue(
        queue_name => 'alps.'||in_queue,
        message_properties => msg_p,
        dequeue_options  => deq_o,
        payload => msg,
        msgid => msgid);

    out_trans := msg.trans;
    out_message := msg.message;
    out_fileblob := msg.file_object;


    return 1;
EXCEPTION when others then
    if sqlcode = -25228 then
        return -1;
    else
        raise;
    end if;
END breceive;

------------------------------------------------------------------------
--
-- breceive - receive a message using Oracle AQ system
--      returns a -1 if wait expired
--
------------------------------------------------------------------------
FUNCTION breceive
(
    in_queue        IN varchar2,    -- name of the queue to receive on
    out_message     OUT varchar2,   -- the message we got (if we got one)
    out_fileblob    out blob,
    in_wait         IN integer := WT_FOREVER    -- optional waittime
)
RETURN integer
IS
l_trans varchar2(20);

BEGIN
    return breceive(in_queue,null,in_wait,DQ_REMOVE,l_trans,out_message,out_fileblob);
END breceive;

------------------------------------------------------------------------
--
-- breceive - receive a message using Oracle AQ system by calling
--           zqm.receive, then commit
--
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
RETURN integer
is PRAGMA AUTONOMOUS_TRANSACTION;
   rc integer;
begin
   rc := zqm.breceive(in_queue,in_correlation, in_wait, in_dq_mode, out_trans, out_message, out_fileblob);
   commit;
   return rc;

EXCEPTION when others then
    rollback;
    if sqlcode = -25228 then
        return -1;
    else
        raise;
    end if;
END breceive_commit;

END zqueuemsg;
/
show errors package body zqueuemsg;
exit;
