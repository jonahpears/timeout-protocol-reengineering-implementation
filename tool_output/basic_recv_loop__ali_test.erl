-module('basic_recv_loop__ali_test.erl').

-file("basic_recv_loop__ali_test.erl", 1).

-define(MONITORED, false).

-define(MONITOR_SPEC,
        #{init => init_state, map => #{state1_std => #{recv => #{msg1 => {state1_std, []}}}}, timeouts => #{}, resets => #{}, states_to_resolve => #{},
          timers => #{}}).

-define(PROTOCOL_SPEC, {rec, "a", {act, r_msg1, {rvar, "a"}}}).

-include("stub.hrl").

-export([]).

run(CoParty) -> run(CoParty, #{timers => #{}, msgs => #{}}).

run(CoParty, Data) -> main(CoParty, Data).

main(CoParty, Data) -> loop_standard_state(CoParty, Data).

loop_standard_state(CoParty, Data1) ->
    receive
        {CoParty, msg1, Payload_Msg1} ->
            Data1 = save_msg(msg1, Payload_Msg1, Data1),
            loop_standard_state(CoParty, Data1)
    end.