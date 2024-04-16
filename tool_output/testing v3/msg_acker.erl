-module('msg_acker').

-file("msg_acker", 1).

-behaviour(gen_statem).

-define(SERVER, ?MODULE).

-export([callback_mode/0,
         custom_end_state/3,
         init/1,
         init/2,
         init_setup_state/3,
         issue_timeout/2,
         receive_msg1/1,
         receive_msg2/1,
         receive_tout/1,
         recv/1,
         send/2,
         send_ack1/1,
         send_ack2/1,
         start_link/0,
         start_link/1,
         state1_std/3,
         state2_send_after/3,
         state4_std/3,
         state5_send_after/3,
         state7_std/3,
         stop/0,
         terminate/3]).

-record(statem_options, {allow_delayable_sends = false, printout_enabled = true}).

-record(statem_data, {coparty_id = undefined, state_stack = [], msg_stack = [], queued_actions = [], options = #statem_options{}}).

-record(stop_data, {reason = undefined, statem_data = #statem_data{}}).

printout(Str, Params) -> io:format("[~p|~p]: " ++ Str ++ "\n", [?MODULE, self()] ++ Params).

start_link(Params) -> gen_statem:start_link({local, ?SERVER}, ?MODULE, Params, []).

start_link() -> ?MODULE:start_link([]).

callback_mode() -> [state_functions, state_enter].

send(Label, Msg) ->
    printout("~p: {~p, ~p}.", [?FUNCTION_NAME, Label, Msg]),
    gen_statem:cast(?MODULE, {send, {Label, Msg}}).

recv(Label) ->
    printout("~p: ~p.", [?FUNCTION_NAME, Label]),
    gen_statem:call(?MODULE, {recv, Label}).

issue_timeout(Label, Msg) ->
    printout("~p: {~p, ~p}.", [?FUNCTION_NAME, Label, Msg]),
    gen_statem:cast(?MODULE, {issue_timeout, {Msg, Label}}).

init([{HKey, HVal} | T]) when is_atom(HKey) and is_map_key(HKey, #statem_options{}) -> init(T, #statem_data{options = maps:put(HKey, HVal, #statem_options{})});
init([_H | T]) -> init(T, #statem_data{});
init([]) -> {ok, init_setup_state, #statem_data{}}.

init([{HKey, HVal} | T], #statem_data{coparty_id = _CoPartyID, state_stack = _States, msg_stack = _Msgs, queued_actions = _Queue, options = Options} = Data)
    when is_atom(HKey) and is_map_key(HKey, Options) ->
    init(T, maps:put(options, maps:put(HKey, HVal, Options), Data));
init([_H | T], #statem_data{coparty_id = _CoPartyID, state_stack = _States, msg_stack = _Msgs, queued_actions = _Queue, options = _Options} = Data) ->
    init(T, Data);
init([_H | T], #statem_data{coparty_id = _CoPartyID, state_stack = _States, msg_stack = _Msgs, queued_actions = _Queue, options = _Options} = Data) ->
    init(T, Data);
init([], #statem_data{coparty_id = _CoPartyID, state_stack = _States, msg_stack = _Msgs, queued_actions = _Queue, options = _Options} = Data) ->
    {ok, init_setup_state, Data}.

init_setup_state(enter, _OldState,
                 #statem_data{coparty_id = _CoPartyID, state_stack = _States, msg_stack = _Msgs, queued_actions = _Queue, options = _Options} = _Data) ->
    {keep_state_and_data, [{state_timeout, 0, wait_to_finish_setup}]};
init_setup_state(state_timeout, wait_to_finish_setup,
                 #statem_data{coparty_id = _CoPartyID, state_stack = States, msg_stack = Msgs, queued_actions = Queue, options = Options} = _Data) ->
    printout("~p, waiting to finish setup.", [?FUNCTION_NAME]),
    receive
        {_SupervisorID, sup_init, CoPartyID} ->
            printout("~p, received coparty ID (~p).", [?FUNCTION_NAME, CoPartyID]),
            {next_state, state1_std, #statem_data{coparty_id = CoPartyID, state_stack = States, msg_stack = Msgs, queued_actions = Queue, options = Options}}
    end.

state1_std(enter, _OldState,
           #statem_data{coparty_id = _CoPartyID, state_stack = _States, msg_stack = _Msgs, queued_actions = [_H], options = _Options} = _Data) ->
    printout("(->) ~p, queued actions.", [?FUNCTION_NAME]),
    {keep_state_and_data, [{state_timeout, 0, process_queue}]};
state1_std(enter, _OldState,
           #statem_data{coparty_id = _CoPartyID, state_stack = _States, msg_stack = _Msgs, queued_actions = [], options = _Options} = _Data) ->
    printout("(->) ~p.", [?FUNCTION_NAME]),
    keep_state_and_data;
state1_std(state_timeout, process_queue,
           #statem_data{coparty_id = CoPartyID, state_stack = States, msg_stack = Msgs, queued_actions = [H | T], options = Options} = _Data) ->
    printout("(->) ~p, queued action: ~p.", [?FUNCTION_NAME, H]),
    Data1 = #statem_data{coparty_id = CoPartyID, state_stack = States, msg_stack = Msgs, queued_actions = T, options = Options},
    {repeat_state, Data1, [{next_event, cast, H}]};
state1_std(info, {CoPartyID, Msg1},
           #statem_data{coparty_id = CoPartyID, state_stack = States, msg_stack = Msgs, queued_actions = Queue,
                        options = #statem_options{allow_delayable_sends = _AllowDelayableSends, printout_enabled = _PrintoutEnabled} = Options} =
               _Data) ->
    printout("~p, send (~p) to ~p.", [?FUNCTION_NAME, Msg1, CoPartyID]),
    NextState = state2_send_after,
    Data1 = #statem_data{coparty_id = CoPartyID, state_stack = [NextState] ++ States, msg_stack = [{recv, Msg1}] ++ Msgs, queued_actions = Queue,
                         options = Options},
    {next_state, NextState, Data1};
state1_std({call, From}, {recv, Label},
           #statem_data{coparty_id = _CoPartyID, state_stack = _States, msg_stack = Msgs, queued_actions = _Queue, options = _Options} = _Data) ->
    printout("~p, looking for msg with label (~p).", [?FUNCTION_NAME, Label]),
    case maps:find(Label, Msgs) of
        {ok, [H]} ->
            printout("~p, found msg (~p: ~p) out of 1.", [?FUNCTION_NAME, Label, H]),
            ReplyMsg = {ok, #{label => Label, msg => H, total => 1}};
        {ok, [H | T]} ->
            NumMsgs = lists:length(T) + 1,
            printout("~p, found msg (~p: ~p) out of ~p.", [?FUNCTION_NAME, Label, H, NumMsgs]),
            ReplyMsg = {ok, #{label => Label, msg => H, total => NumMsgs}};
        error ->
            printout("~p, no msgs with label (~p) found.", [?FUNCTION_NAME, Label]),
            ReplyMsg = {error, no_msg_found_under_label}
    end,
    {keep_state_and_data, [{reply, From, ReplyMsg}]};
state1_std(cast, {Label, Msg},
           #statem_data{coparty_id = CoPartyID, state_stack = States, msg_stack = Msgs, queued_actions = Queue,
                        options = #statem_options{allow_delayable_sends = _AllowDelayableSends, printout_enabled = _PrintoutEnabled} = Options} =
               _Data) ->
    printout("~p, too early to send,\n\tadding to queue: ~p.", [?FUNCTION_NAME, {Label, Msg}]),
    Data1 = #statem_data{coparty_id = CoPartyID, state_stack = States, msg_stack = Msgs, queued_actions = Queue ++ [{Label, Msg}], options = Options},
    {keep_state, Data1};
state1_std(info, {Label, Msg},
           #statem_data{coparty_id = CoPartyID, state_stack = States, msg_stack = Msgs, queued_actions = Queue,
                        options = #statem_options{allow_delayable_sends = _AllowDelayableSends, printout_enabled = _PrintoutEnabled} = Options} =
               _Data) ->
    printout("~p, too early to recv,\n\tadding to queue: ~p.", [?FUNCTION_NAME, {Label, Msg}]),
    Data1 = #statem_data{coparty_id = CoPartyID, state_stack = States, msg_stack = Msgs, queued_actions = Queue ++ [{Label, Msg}], options = Options},
    {keep_state, Data1}.

state2_send_after(enter, _OldState,
                  #statem_data{coparty_id = _CoPartyID, state_stack = _States, msg_stack = _Msgs, queued_actions = [_H], options = _Options} = _Data) ->
    printout("(->) ~p, queued actions.", [?FUNCTION_NAME]),
    {keep_state_and_data, [{state_timeout, 0, process_queue}]};
state2_send_after(enter, _OldState,
                  #statem_data{coparty_id = _CoPartyID, state_stack = _States, msg_stack = _Msgs, queued_actions = [], options = _Options} = Data) ->
    io:format("(~p ->.)\n", [?FUNCTION_NAME]),
    {keep_state, Data, [{state_timeout, 3000, state4_std}]};
state2_send_after(state_timeout, process_queue,
                  #statem_data{coparty_id = CoPartyID, state_stack = States, msg_stack = Msgs, queued_actions = [H | T], options = Options} = _Data) ->
    printout("(->) ~p, queued action: ~p.", [?FUNCTION_NAME, H]),
    Data1 = #statem_data{coparty_id = CoPartyID, state_stack = States, msg_stack = Msgs, queued_actions = T, options = Options},
    {repeat_state, Data1, [{next_event, cast, H}]};
state2_send_after(cast, {send, {send_ack1, Ack1}},
                  #statem_data{coparty_id = CoPartyID, state_stack = States, msg_stack = Msgs, queued_actions = Queue,
                               options = #statem_options{allow_delayable_sends = _AllowDelayableSends, printout_enabled = _PrintoutEnabled} = Options} =
                      _Data) ->
    CoPartyID ! {self(), Ack1},
    printout("~p, send (~p) to ~p.", [?FUNCTION_NAME, Ack1, CoPartyID]),
    NextState = state1_std,
    Data1 = #statem_data{coparty_id = CoPartyID, state_stack = [NextState] ++ States, msg_stack = [{send, Ack1}] ++ Msgs, queued_actions = Queue,
                         options = Options},
    {next_state, NextState, Data1};
%% This is a timeout branch:
state2_send_after(state_timeout, state4_std, Data) ->
    io:format("(timeout[~p] -> ~p.)\n", [3000, state4_std]),
    {next_state, state4_std, Data}.

state4_std(enter, _OldState,
           #statem_data{coparty_id = _CoPartyID, state_stack = _States, msg_stack = _Msgs, queued_actions = [_H], options = _Options} = _Data) ->
    printout("(->) ~p, queued actions.", [?FUNCTION_NAME]),
    {keep_state_and_data, [{state_timeout, 0, process_queue}]};
state4_std(enter, _OldState,
           #statem_data{coparty_id = _CoPartyID, state_stack = _States, msg_stack = _Msgs, queued_actions = [], options = _Options} = _Data) ->
    printout("(->) ~p.", [?FUNCTION_NAME]),
    keep_state_and_data;
state4_std(state_timeout, process_queue,
           #statem_data{coparty_id = CoPartyID, state_stack = States, msg_stack = Msgs, queued_actions = [H | T], options = Options} = _Data) ->
    printout("(->) ~p, queued action: ~p.", [?FUNCTION_NAME, H]),
    Data1 = #statem_data{coparty_id = CoPartyID, state_stack = States, msg_stack = Msgs, queued_actions = T, options = Options},
    {repeat_state, Data1, [{next_event, cast, H}]};
state4_std(info, {CoPartyID, Msg2},
           #statem_data{coparty_id = CoPartyID, state_stack = States, msg_stack = Msgs, queued_actions = Queue,
                        options = #statem_options{allow_delayable_sends = _AllowDelayableSends, printout_enabled = _PrintoutEnabled} = Options} =
               _Data) ->
    printout("~p, send (~p) to ~p.", [?FUNCTION_NAME, Msg2, CoPartyID]),
    NextState = state5_send_after,
    Data1 = #statem_data{coparty_id = CoPartyID, state_stack = [NextState] ++ States, msg_stack = [{recv, Msg2}] ++ Msgs, queued_actions = Queue,
                         options = Options},
    {next_state, NextState, Data1};
state4_std({call, From}, {recv, Label},
           #statem_data{coparty_id = _CoPartyID, state_stack = _States, msg_stack = Msgs, queued_actions = _Queue, options = _Options} = _Data) ->
    printout("~p, looking for msg with label (~p).", [?FUNCTION_NAME, Label]),
    case maps:find(Label, Msgs) of
        {ok, [H]} ->
            printout("~p, found msg (~p: ~p) out of 1.", [?FUNCTION_NAME, Label, H]),
            ReplyMsg = {ok, #{label => Label, msg => H, total => 1}};
        {ok, [H | T]} ->
            NumMsgs = lists:length(T) + 1,
            printout("~p, found msg (~p: ~p) out of ~p.", [?FUNCTION_NAME, Label, H, NumMsgs]),
            ReplyMsg = {ok, #{label => Label, msg => H, total => NumMsgs}};
        error ->
            printout("~p, no msgs with label (~p) found.", [?FUNCTION_NAME, Label]),
            ReplyMsg = {error, no_msg_found_under_label}
    end,
    {keep_state_and_data, [{reply, From, ReplyMsg}]};
state4_std(cast, {Label, Msg},
           #statem_data{coparty_id = CoPartyID, state_stack = States, msg_stack = Msgs, queued_actions = Queue,
                        options = #statem_options{allow_delayable_sends = _AllowDelayableSends, printout_enabled = _PrintoutEnabled} = Options} =
               _Data) ->
    printout("~p, too early to send,\n\tadding to queue: ~p.", [?FUNCTION_NAME, {Label, Msg}]),
    Data1 = #statem_data{coparty_id = CoPartyID, state_stack = States, msg_stack = Msgs, queued_actions = Queue ++ [{Label, Msg}], options = Options},
    {keep_state, Data1};
state4_std(info, {Label, Msg},
           #statem_data{coparty_id = CoPartyID, state_stack = States, msg_stack = Msgs, queued_actions = Queue,
                        options = #statem_options{allow_delayable_sends = _AllowDelayableSends, printout_enabled = _PrintoutEnabled} = Options} =
               _Data) ->
    printout("~p, too early to recv,\n\tadding to queue: ~p.", [?FUNCTION_NAME, {Label, Msg}]),
    Data1 = #statem_data{coparty_id = CoPartyID, state_stack = States, msg_stack = Msgs, queued_actions = Queue ++ [{Label, Msg}], options = Options},
    {keep_state, Data1}.

state5_send_after(enter, _OldState,
                  #statem_data{coparty_id = _CoPartyID, state_stack = _States, msg_stack = _Msgs, queued_actions = [_H], options = _Options} = _Data) ->
    printout("(->) ~p, queued actions.", [?FUNCTION_NAME]),
    {keep_state_and_data, [{state_timeout, 0, process_queue}]};
state5_send_after(enter, _OldState,
                  #statem_data{coparty_id = _CoPartyID, state_stack = _States, msg_stack = _Msgs, queued_actions = [], options = _Options} = Data) ->
    io:format("(~p ->.)\n", [?FUNCTION_NAME]),
    {keep_state, Data, [{state_timeout, 3000, state7_std}]};
state5_send_after(state_timeout, process_queue,
                  #statem_data{coparty_id = CoPartyID, state_stack = States, msg_stack = Msgs, queued_actions = [H | T], options = Options} = _Data) ->
    printout("(->) ~p, queued action: ~p.", [?FUNCTION_NAME, H]),
    Data1 = #statem_data{coparty_id = CoPartyID, state_stack = States, msg_stack = Msgs, queued_actions = T, options = Options},
    {repeat_state, Data1, [{next_event, cast, H}]};
state5_send_after(cast, {send, {send_ack2, Ack2}},
                  #statem_data{coparty_id = CoPartyID, state_stack = States, msg_stack = Msgs, queued_actions = Queue,
                               options = #statem_options{allow_delayable_sends = _AllowDelayableSends, printout_enabled = _PrintoutEnabled} = Options} =
                      _Data) ->
    CoPartyID ! {self(), Ack2},
    printout("~p, send (~p) to ~p.", [?FUNCTION_NAME, Ack2, CoPartyID]),
    NextState = state2_send_after,
    Data1 = #statem_data{coparty_id = CoPartyID, state_stack = [NextState] ++ States, msg_stack = [{send, Ack2}] ++ Msgs, queued_actions = Queue,
                         options = Options},
    {next_state, NextState, Data1};
%% This is a timeout branch:
state5_send_after(state_timeout, state7_std, Data) ->
    io:format("(timeout[~p] -> ~p.)\n", [3000, state7_std]),
    {next_state, state7_std, Data}.

state7_std(enter, _OldState,
           #statem_data{coparty_id = _CoPartyID, state_stack = _States, msg_stack = _Msgs, queued_actions = [_H], options = _Options} = _Data) ->
    printout("(->) ~p, queued actions.", [?FUNCTION_NAME]),
    {keep_state_and_data, [{state_timeout, 0, process_queue}]};
state7_std(enter, _OldState,
           #statem_data{coparty_id = _CoPartyID, state_stack = _States, msg_stack = _Msgs, queued_actions = [], options = _Options} = _Data) ->
    printout("(->) ~p.", [?FUNCTION_NAME]),
    keep_state_and_data;
state7_std(state_timeout, process_queue,
           #statem_data{coparty_id = CoPartyID, state_stack = States, msg_stack = Msgs, queued_actions = [H | T], options = Options} = _Data) ->
    printout("(->) ~p, queued action: ~p.", [?FUNCTION_NAME, H]),
    Data1 = #statem_data{coparty_id = CoPartyID, state_stack = States, msg_stack = Msgs, queued_actions = T, options = Options},
    {repeat_state, Data1, [{next_event, cast, H}]};
state7_std(info, {CoPartyID, Tout},
           #statem_data{coparty_id = CoPartyID, state_stack = States, msg_stack = Msgs, queued_actions = Queue,
                        options = #statem_options{allow_delayable_sends = _AllowDelayableSends, printout_enabled = _PrintoutEnabled} = Options} =
               _Data) ->
    printout("~p, send (~p) to ~p.", [?FUNCTION_NAME, Tout, CoPartyID]),
    NextState = custom_end_state,
    Data1 = #statem_data{coparty_id = CoPartyID, state_stack = [NextState] ++ States, msg_stack = [{recv, Tout}] ++ Msgs, queued_actions = Queue,
                         options = Options},
    {next_state, NextState, Data1};
state7_std({call, From}, {recv, Label},
           #statem_data{coparty_id = _CoPartyID, state_stack = _States, msg_stack = Msgs, queued_actions = _Queue, options = _Options} = _Data) ->
    printout("~p, looking for msg with label (~p).", [?FUNCTION_NAME, Label]),
    case maps:find(Label, Msgs) of
        {ok, [H]} ->
            printout("~p, found msg (~p: ~p) out of 1.", [?FUNCTION_NAME, Label, H]),
            ReplyMsg = {ok, #{label => Label, msg => H, total => 1}};
        {ok, [H | T]} ->
            NumMsgs = lists:length(T) + 1,
            printout("~p, found msg (~p: ~p) out of ~p.", [?FUNCTION_NAME, Label, H, NumMsgs]),
            ReplyMsg = {ok, #{label => Label, msg => H, total => NumMsgs}};
        error ->
            printout("~p, no msgs with label (~p) found.", [?FUNCTION_NAME, Label]),
            ReplyMsg = {error, no_msg_found_under_label}
    end,
    {keep_state_and_data, [{reply, From, ReplyMsg}]};
state7_std(cast, {Label, Msg},
           #statem_data{coparty_id = CoPartyID, state_stack = States, msg_stack = Msgs, queued_actions = Queue,
                        options = #statem_options{allow_delayable_sends = _AllowDelayableSends, printout_enabled = _PrintoutEnabled} = Options} =
               _Data) ->
    printout("~p, too early to send,\n\tadding to queue: ~p.", [?FUNCTION_NAME, {Label, Msg}]),
    Data1 = #statem_data{coparty_id = CoPartyID, state_stack = States, msg_stack = Msgs, queued_actions = Queue ++ [{Label, Msg}], options = Options},
    {keep_state, Data1};
state7_std(info, {Label, Msg},
           #statem_data{coparty_id = CoPartyID, state_stack = States, msg_stack = Msgs, queued_actions = Queue,
                        options = #statem_options{allow_delayable_sends = _AllowDelayableSends, printout_enabled = _PrintoutEnabled} = Options} =
               _Data) ->
    printout("~p, too early to recv,\n\tadding to queue: ~p.", [?FUNCTION_NAME, {Label, Msg}]),
    Data1 = #statem_data{coparty_id = CoPartyID, state_stack = States, msg_stack = Msgs, queued_actions = Queue ++ [{Label, Msg}], options = Options},
    {keep_state, Data1}.

custom_end_state(enter, _OldState, #stop_data{reason = _Reason, statem_data = _StatemData} = _Data) ->
    {keep_state_and_data, [{state_timeut, 0, go_to_terminate}]};
custom_end_state(state_timeout, go_to_terminate, #stop_data{reason = Reason, statem_data = StatemData} = Data) ->
    printout("(->) ~p, Reason: ~p,\nStatemData: \n\t~p.", [?FUNCTION_NAME, Reason, StatemData]),
    {stop, Reason, Data}.

terminate(Reason, State, Data) ->
    printout("(->) ~p, ~p, Reason: ~p,\nData: \n\t~p.", [?FUNCTION_NAME, State, Reason, Data]),
    ok.

receive_msg1(Msg1) -> gen_statem:cast(?SERVER, {receive_msg1, Msg1}).

receive_msg2(Msg2) -> gen_statem:cast(?SERVER, {receive_msg2, Msg2}).

receive_tout(Tout) -> gen_statem:cast(?SERVER, {receive_tout, Tout}).

send_ack1(Ack1) -> gen_statem:internal(?SERVER, {send_ack1, Ack1}).

send_ack2(Ack2) -> gen_statem:internal(?SERVER, {send_ack2, Ack2}).

stop() -> gen_statem:stop(?SERVER).