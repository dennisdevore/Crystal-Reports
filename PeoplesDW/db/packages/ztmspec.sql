--
-- $Id$
--

create or replace package alps.ztaskmanager as

WORK_DEFAULT_QUEUE      CONSTANT       varchar2(4) := 'work';
USER_DEFAULT_QUEUE      CONSTANT       varchar2(5) := 'userq';

FUNCTION find_correlation(in_facility varchar2)
return varchar2;

procedure get_cluster_pick
   (in_requested in number,
    in_userid    in varchar2,
    in_facility  in varchar2,
    in_location  in varchar2,
    in_equipment in varchar2,
    in_allcusts  in varchar2,
    in_groupid   in varchar2,
    in_onlycust  in varchar2,
    in_wave      in number,
    in_tasktype  in varchar2,
    out_assigned out number,
    out_msg      out varchar2);

procedure get_sys_order_pick
   (in_userid    in varchar2,
    in_facility  in varchar2,
    in_equipment in varchar2,
    in_orderid   in number,
    in_shipid    in number,
    in_allcusts  in varchar2,
    in_groupid   in varchar2,
    in_onlycust  in varchar2,
    in_tasktype  in varchar2,
    out_taskid   out varchar2,
    out_msg      out varchar2);

procedure get_sort_item_pick
   (in_userid    in varchar2,
    in_facility  in varchar2,
    in_equipment in varchar2,
    in_lpid      in varchar2,
    in_allcusts  in varchar2,
    in_groupid   in varchar2,
    in_onlycust  in varchar2,
    in_tasktype  in varchar2,
    out_taskid   out varchar2,
    out_msg      out varchar2);

procedure get_sort_item_pick_wave
   (in_userid    in varchar2,
    in_facility  in varchar2,
    in_equipment in varchar2,
    in_wave      in number,
    in_allcusts  in varchar2,
    in_groupid   in varchar2,
    in_onlycust  in varchar2,
    in_tasktype  in varchar2,
    out_taskid   out varchar2,
    out_msg      out varchar2);

procedure get_sort_item_pick_load
   (in_userid    in varchar2,
    in_facility  in varchar2,
    in_equipment in varchar2,
    in_loadno    in number,
    in_allcusts  in varchar2,
    in_groupid   in varchar2,
    in_onlycust  in varchar2,
    in_tasktype  in varchar2,
    out_taskid   out varchar2,
    out_msg      out varchar2);

procedure get_a_task
   (in_userid            in varchar2,
    in_facility          in varchar2,
    in_location          in varchar2,
    in_equipment         in varchar2,
    in_tasktypeindicator in varchar2,
    in_tasktypestr       in varchar2,
    in_allcusts          in varchar2,
    in_groupid           in varchar2,
    in_onlycust          in varchar2,
    in_nextlinepickby    in varchar2,
    out_taskid           out varchar2,
    out_tasktype         out varchar2,
    out_msg              out varchar2,
    in_wave              in number default null);

procedure work_request
   (in_type              in varchar2,
    in_userid            in varchar2,
    in_facility          in varchar2,
    in_location          in varchar2,
    in_equipment         in varchar2,
    in_tasktypeindicator in varchar2,
    in_tasktypestr       in varchar2,
    in_allcusts          in varchar2,
    in_groupid           in varchar2,
    in_onlycust          in varchar2,
    in_nextlinepickby    in varchar2,
    in_wave              in number,
    out_msg              out varchar2);

procedure work_response
   (in_userid      in varchar2,
    in_facility    in varchar2,
    out_taskid     out varchar2,
    out_tasktype   out varchar2,
    out_msg        out varchar2);

procedure get_conveyor_pick
   (in_userid     in varchar2,
    in_facility   in varchar2,
    io_location   in out varchar2,
    io_direction  in out varchar2,
    out_taskid    out varchar2,
    out_tasktype  out varchar2,
    out_msg       out varchar2);

procedure assign_by_priority
   (userfacility       in varchar2,
    equipment          in varchar2,
    tasktypeindicator  in varchar2,
    tasktypestr        in varchar2,
    userid             in varchar2,
    custtype           in varchar2,
    custaux            in varchar2,
    nextlinepickby     in varchar2,
    userlocation       in varchar2,
    voice              in varchar2,
    out_taskid         out number,
    out_tasktype       out varchar2,
    out_msg            out varchar2);

procedure assign_by_section
   (userfacility      in varchar2,
    usersection       in varchar2,
    equipment         in varchar2,
    tasktypestr       in varchar2,
    tasktypeindicator in varchar2,
    userid            in varchar2,
    prilevel          in varchar2,
    custtype          in varchar2,
    custaux           in varchar2,
    nextlinepickby    in varchar2,
    userlocation      in varchar2,
    voice             in varchar2,
    pickwave          number,
    out_taskid        out number,
    out_tasktype      out varchar2,
    out_msg           out varchar2);

procedure assign_preassigned_by_section
   (userfacility      in varchar2,
    usersection       in varchar2,
    tasktypestr       in varchar2,
    tasktypeindicator in varchar2,
    userid            in varchar2,
    prilevel          in varchar2,
    custtype          in varchar2,
    custaux           in varchar2,
    nextlinepickby    in varchar2,
    userlocation      in varchar2,
    voice             in varchar2,
    pickwave          in number,
    out_taskid        out number,
    out_tasktype      out varchar2,
    out_msg           out varchar2);

procedure assign_order_pick
   (userfacility  in varchar2,
    userid        in varchar2,
    equipment     in varchar2,
    pickorderid   in number,
    pickshipid    in number,
    custtype      in varchar2,
    custaux       in varchar2,
    in_tasktype   in varchar2,
    out_taskid    out number,
    out_msg       out varchar2);

procedure assign_sort_item_pick
   (userfacility  in varchar2,
    userid        in varchar2,
    equipment     in varchar2,
    picklpid      in varchar2,
    custtype      in varchar2,
    custaux       in varchar2,
    in_tasktype   in varchar2,
    out_taskcount out number,
    out_msg       out varchar2);

procedure assign_sort_item_pick_load
   (userfacility  in varchar2,
    userid        in varchar2,
    equipment     in varchar2,
    in_loadno     in number,
    custtype      in varchar2,
    custaux       in varchar2,
    in_tasktype   in varchar2,
    out_taskcount out number,
    out_msg       out varchar2);

procedure assign_sort_item_pick_wave
   (userfacility  in varchar2,
    userid        in varchar2,
    equipment     in varchar2,
    in_wave       in number,
    custtype      in varchar2,
    custaux       in varchar2,
    in_tasktype   in varchar2,
    out_taskcount out number,
    out_msg       out varchar2);

procedure assign_conveyor_pick
   (in_userid     in varchar2,
    in_facility   in varchar2,
    io_location   in out varchar2,
    io_direction  in out varchar2,
    out_taskid    out varchar2,
    out_tasktype  out varchar2,
    out_msg       out varchar2);

procedure get_voice_cluster
   (in_requested in number,
    in_userid    in varchar2,
    in_facility  in varchar2,
    in_location  in varchar2,
    in_equipment in varchar2,
    in_allcusts  in varchar2,
    in_groupid   in varchar2,
    in_onlycust  in varchar2,
    out_assigned out number,
    out_msg      out varchar2);

procedure get_voice_task
   (in_userid            in varchar2,
    in_facility          in varchar2,
    in_location          in varchar2,
    in_equipment         in varchar2,
    in_tasktypeindicator in varchar2,
    in_tasktypestr       in varchar2,
    in_allcusts          in varchar2,
    in_groupid           in varchar2,
    in_onlycust          in varchar2,
    in_nextlinepickby    in varchar2,
    out_taskid           out varchar2,
    out_tasktype         out varchar2,
    out_msg              out varchar2);

FUNCTION subtask_min_apptdate
(in_taskid number
) return date;

PRAGMA RESTRICT_REFERENCES (subtask_min_apptdate, WNDS, WNPS, RNPS);

procedure assign_max_line_picks
   (in_taskid in number,
    in_userid in varchar2,
    out_msg   out varchar2);

function count_task_restrictions
   (in_voice  in varchar2,
    in_taskid in number)
return number;

procedure assign_preassigned_by_sequence
   (userfacility      in varchar2,
    tasktypestr       in varchar2,
    tasktypeindicator in varchar2,
    userid            in varchar2,
    prilevel          in varchar2,
    custtype          in varchar2,
    custaux           in varchar2,
    pickwave          in number,
    out_taskid        out number,
    out_tasktype      out varchar2,
    out_msg           out varchar2);

procedure assign_by_sequence
   (userfacility      in varchar2,
    equipment         in varchar2,
    tasktypestr       in varchar2,
    tasktypeindicator in varchar2,
    userid            in varchar2,
    prilevel          in varchar2,
    custtype          in varchar2,
    custaux           in varchar2,
    pickwave          in number,
    out_taskid        out number,
    out_tasktype      out varchar2,
    out_msg           out varchar2);



procedure assign_wave_pick
   (in_facility  in varchar2,
    in_userid    in varchar2,
    in_equipment in varchar2,
    in_tasktype  in varchar2,
    in_wave      in number,
    out_taskid   out number,
    out_msg      out varchar2);

procedure get_section_pick
   (in_userid    in varchar2,
    in_facility  in varchar2,
    in_section   in varchar2,
    in_equipment in varchar2,
    in_allcusts  in varchar2,
    in_groupid   in varchar2,
    in_onlycust  in varchar2,
    in_tasktypes in varchar2,
    in_startpos  in number,
    out_assigned out number,
    out_msg      out varchar2);

procedure assign_section_pick
   (in_userid    in varchar2,
    in_facility  in varchar2,
    in_section   in varchar2,
    in_equipment in varchar2,
    in_tasktypes in varchar2,
    in_ctype     in varchar2,
    in_caux      in varchar2,
    in_startpos  in number,
    out_assigned out number,
    out_msg      out varchar2);

procedure is_sort_by_item
   (in_lpid  in varchar2,
    is_sbi   out number);

procedure is_sort_by_item_wave
   (in_wave  in number,
    is_sbi   out number);

procedure is_sort_by_item_load
   (in_loadno in number,
    is_sbi    out number);

procedure sbi_task_count
   (in_lpid  in varchar2,
    in_user  in varchar2,
    out_count out number);

procedure updt_appt_sched
   (in_loadno  in varchar2,
    in_userid  in varchar2,
    out_msg    out varchar2);

procedure kill_rfwhse_user
   (in_facility  in varchar2,
    in_rf_userid in varchar2,
    in_userid    in varchar2,
    out_errorno  out number,
    out_msg      out varchar2);
pragma restrict_references (count_task_restrictions, wnds, wnps, rnps);


end ztaskmanager;
/

show errors package ztaskmanager;
exit;
