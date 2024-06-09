-module('advanced_mixed_choice_recv_first__ali_test.erl').

-file("advanced_mixed_choice_recv_first__ali_test.erl", 1).

-define(MONITORED, false).

-define(MONITOR_SPEC,
        #{init => state2_recv_after,
          map =>
              #{state2_recv_after => #{recv => #{first => state3_send_after}}, state3_send_after => #{send => #{second => stop_state}},
                state9_send_after => #{send => #{second => stop_state}}, state12_std => #{recv => #{third => stop_state}}},
          timeouts => #{state2_recv_after => {3000, state9_send_after}, state3_send_after => {t1, error_state}, state9_send_after => {t1, standard_state}},
          resets => #{init_state => #{t1 => 5000}}, timers => #{}}).

-define(PROTOCOL_SPEC,
        {timer, "t1", 5000, {act, r_first, {act, s_second, endP, aft, "t1", error}, aft, 3000, {act, s_second, endP, aft, "t1", {act, r_third, endP}}}}).

-include("stub.hrl").

-export([main/2, run/1, run/2, stopping/2, stopping/3]).

run(CoParty) -> run(CoParty, #{timers => #{}, msgs => #{}}).

run(CoParty, Data) -> main(CoParty, Data).

main(CoParty, Data) ->
    {Data, _TID_t1} = set_timer(t1, 5000, Data),
    receive
        {CoParty, first, Payload_First} ->
            Data = save_msg(first, Payload_First, Data),
            AwaitPayload = nonblocking_payload(fun get_state_3_payload/1, Data, self(), get_timer(t1, Data)),
            receive
                {AwaitPayload, ok, {Label, Payload}} ->
                    case Label of
                        second ->
                            CoParty ! {self(), second, Payload},
                            stopping(CoParty, Data);
                        _ -> error(unexpected_label_selected)
                    end;
                {AwaitPayload, ko} ->
                    error(unspecified_error),
                    stopping(CoParty, Data)
            end
    end.

stopping(CoParty, Data) -> stopping(normal, CoParty, Data).

stopping(normal = _Reason, _CoParty, _Data) -> exit(normal);
stopping({error, Reason, Details}, _CoParty, _Data) when is_atom(Reason) -> erlang:error(Reason, Details);
stopping({error, Reason}, CoParty, Data) when is_atom(Reason) -> stopping({error, Reason, []}, CoParty, Data);
stopping(Reason, _CoParty, _Data) when is_atom(Reason) -> exit(Reason).

get_state_2_payload(Data) -> extend_with_functionality.

get_state_1_payload(Data) -> extend_with_functionality.