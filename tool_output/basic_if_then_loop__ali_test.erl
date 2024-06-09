-module('basic_if_then_loop__ali_test.erl').

-file("basic_if_then_loop__ali_test.erl", 1).

-define(MONITORED, false).

-define(MONITOR_SPEC, #{}).

-define(PROTOCOL_SPEC, {timer, "t", 5000, {rec, "a", {if_timer, "t", {act, s_finished, {rvar, "a"}}}}}).

-include("stub.hrl").

-export([]).

run(CoParty) -> run(CoParty, #{timers => #{}, msgs => #{}}).

run(CoParty, Data) -> main(CoParty, Data).

main(CoParty, Data) ->
    {Data, _TID_t} = set_timer(t, 5000, Data),
    loop_if_then_else_state(CoParty, Data).

loop_if_then_else_state(CoParty, Data2) ->
    receive
        {timeout, _TID_t, timer_t} ->
            CoParty ! {self(), finished, Payload},
            loop_if_then_else_state(CoParty, Data2_3)
        after 0 -> error(unspecified_error), stopping(CoParty, Data2_6)
    end.

stopping(CoParty, Data) -> stopping(normal, CoParty, Data).

stopping(normal = _Reason, _CoParty, _Data) -> exit(normal);
stopping({error, Reason, Details}, _CoParty, _Data) when is_atom(Reason) -> erlang:error(Reason, Details);
stopping({error, Reason}, CoParty, Data) when is_atom(Reason) -> stopping({error, Reason, []}, CoParty, Data);
stopping(Reason, _CoParty, _Data) when is_atom(Reason) -> exit(Reason).

get_state_1_payload(Data) -> extend_with_functionality.