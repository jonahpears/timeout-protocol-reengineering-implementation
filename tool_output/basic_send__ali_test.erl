-module(basic_send__ali_test).

-file("basic_send__ali_test", 1).

-define(MONITORED, false).

-define(MONITOR_SPEC, #{init => state1_std, map => #{state1_std => #{send => #{msgA => stop_state}}}, timeouts => #{}, resets => #{}}).

-define(PROTOCOL_SPEC, {act, s_msgA, endP}).

-include("stub.hrl").

-export([main/2, run/1, run/2, stopping/2, stopping/3]).

run(CoParty) -> run(CoParty, #{timers => #{}, msgs => #{}}).

run(CoParty, Data) -> main(CoParty, Data).

main(CoParty, Data) ->
    CoParty ! {self(), msgA, Payload},
    stopping(CoParty, Data).

stopping(CoParty, Data) -> stopping(normal, CoParty, Data).

stopping(normal = _Reason, _CoParty, _Data) -> exit(normal);
stopping({error, Reason, Details}, _CoParty, _Data) when is_atom(Reason) -> erlang:error(Reason, Details);
stopping({error, Reason}, CoParty, Data) when is_atom(Reason) -> stopping({error, Reason, []}, CoParty, Data);
stopping(Reason, _CoParty, _Data) when is_atom(Reason) -> exit(Reason).