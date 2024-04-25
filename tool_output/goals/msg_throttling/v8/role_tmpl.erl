-module(role_tmpl).
-file("role_tmpl.erl", 1).

-behaviour(gen_statem).

-include("tpri_data_records.hrl").

%% gen_statem
-export([ start_link/0,
          callback_mode/0,
          init/1,
          stop/0,
          terminate/3 ]).

%% custom wrappers for gen_statem
-export([ start_link/1, 
          init/2 ]).

%% callbacks
-export([ handle_event/4 ]).

%% better printing
% -export([ format_status/1 ]).

%% generic callbacks
-export([ send/2, recv/1 ]).

-include("printout.hrl").

%% gen_statem
start_link([{name, Name}|_T]=Params) -> 
    % printout("~p, Name: ~p, Tail: ~p.", [self(), Name, Params]),
    gen_statem:start_link({global, Name}, ?MODULE, Params, []);
start_link([_H|_T]=Params) -> 
    % printout("~p, Params: ~p.", [self(), Params]),
    gen_statem:start_link({local, ?MODULE}, ?MODULE, Params, []).
start_link() -> 
    printout("~p.", [self()]),
    msg_worker:start_link([]).

callback_mode() -> [handle_event_function, state_enter].

-spec init([{atom(),any()}|[]]) -> {atom(), atom(), map()}.
init([_H|_T]=Params) -> init(Params, #statem_data{});
init(Params) -> init([Params], #statem_data{}).

-spec init([{atom(),any()}|[]], map()) -> {atom(), atom(), map()}.
% init([{HKey,HVal}|T], #statem_data{ name=_Name, coparty_id = undefined=_CoPartyID, init_state=_InitState, states = _States, msgs = _Msgs, timeouts = _Timeouts, state_map = _StateMap, queued_actions = _Queue, options = Options} = StatemData) 
%   when is_atom(HKey) ->
%     case HKey of 
%       options ->
%         {OKey, OVal} = HVal,
%         Data#statem_data.options = maps:put(OKey, OVal, Data#statem_data.options),
%         init(T, Data);
      




init([{HKey,HVal}|T], #statem_data{ name=_Name, coparty_id = undefined=_CoPartyID, init_state=_InitState, states = _States, msgs = _Msgs, timeouts = _Timeouts, state_map = _StateMap, queued_actions = _Queue, options = Options} = StatemData) 
    when is_atom(HKey) and is_map_key(HKey, Options) -> init(T, maps:put(options, maps:put(HKey, HVal, Options), StatemData));
init([{name,HVal}|T], #statem_data{ name=_Name, coparty_id = undefined=CoPartyID, init_state=InitState, states = States, msgs = Msgs, timeouts = Timeouts, state_map = StateMap, queued_actions = Queue, options = Options} = _StatemData) -> 
    StatemData1 = #statem_data{ name = HVal,
                                coparty_id = CoPartyID,
                                init_state = InitState,
                                states = States,
                                msgs = Msgs,
                                timeouts = Timeouts,
                                state_map = StateMap,
                                queued_actions = Queue,
                                options = Options },
    init(T, StatemData1);
init([{init_state,HVal}|T], #statem_data{ name=Name, coparty_id = undefined=CoPartyID, init_state=_InitState, states = States, msgs = Msgs, timeouts = Timeouts, state_map = StateMap, queued_actions = Queue, options = Options} = _StatemData) -> 
    StatemData1 = #statem_data{ name = Name,
                                coparty_id = CoPartyID,
                                init_state = HVal,
                                states = States,
                                msgs = Msgs,
                                timeouts = Timeouts,
                                state_map = StateMap,
                                queued_actions = Queue,
                                options = Options },
    init(T, StatemData1);
init([{timeouts,HVal}|T], #statem_data{ name=Name, coparty_id = undefined=CoPartyID, init_state=InitState, states = States, msgs = Msgs, timeouts = Timeouts, state_map = StateMap, queued_actions = Queue, options = Options} = _StatemData) -> 
    Timeouts1 = maps:merge(Timeouts, HVal),
    StatemData1 = #statem_data{ name = Name,
                                coparty_id = CoPartyID,
                                init_state = InitState,
                                states = States,
                                msgs = Msgs,
                                timeouts = Timeouts1,
                                state_map = StateMap,
                                queued_actions = Queue,
                                options = Options },
    init(T, StatemData1);
init([{state_map,HVal}|T], #statem_data{ name=Name, coparty_id = undefined=CoPartyID, init_state=InitState, states = States, msgs = Msgs, timeouts = Timeouts, state_map = StateMap, queued_actions = Queue, options = Options} = _StatemData) -> 
    StateMap1 = maps:merge(StateMap, HVal),
    StatemData1 = #statem_data{ name = Name,
                                coparty_id = CoPartyID,
                                init_state = InitState,
                                states = States,
                                msgs = Msgs,
                                timeouts = Timeouts,
                                state_map = StateMap1,
                                queued_actions = Queue,
                                options = Options },
    init(T, StatemData1);
init([_H|T], #statem_data{ name=_Name, coparty_id = undefined=_CoPartyID, init_state=_InitState, states = _States, msgs = _Msgs, timeouts = _Timeouts, state_map = _StateMap, queued_actions = _Queue, options = _Options} = StatemData) -> init(T, StatemData);
init([], #statem_data{ name=Name, coparty_id = undefined=_CoPartyID, init_state=_InitState, states = _States, msgs = _Msgs, timeouts = _Timeouts, state_map = _StateMap, queued_actions = _Queue, options = _Options} = StatemData) -> 
    %% get app ID and send self()
    [{app_id,AppID}|_T] = ets:lookup(tpri,app_id),
    AppID ! {tpri, Name, mon, self()},
    {ok, init_setup_state, StatemData}.


stop() -> 
    printout("~p.", [?FUNCTION_NAME]),
    gen_statem:stop(?MODULE).


terminate(Reason, issue_timeout, #statem_data{name=Name, coparty_id = _CoPartyID, init_state=_InitState, states = _States, msgs = _Msgs, timeouts = _Timeouts, state_map = _StateMap, queued_actions = _Queue, options = _Options} = StatemData) ->
    printout(Name, "~p, timeout: {Reason: ~p},\n\t{State: ~p}", [?FUNCTION_NAME, Reason, StatemData]);
terminate(Reason, State, #statem_data{name=Name, coparty_id = _CoPartyID, init_state=_InitState, states = _States, msgs = _Msgs, timeouts = _Timeouts, state_map = _StateMap, queued_actions = _Queue, options = _Options} = StatemData) -> 
    printout(Name, "~p, {Reason: ~p},\n\t{State: ~p},\n\t{StatemData: ~p}.", [?FUNCTION_NAME,Reason,State,StatemData]),
    ok.



%% generic callbacks
send(Label, Msg) -> gen_statem:cast(?MODULE, {send, Label, Msg}).
recv(Label) -> gen_statem:call(?MODULE, {recv, Label}).






%% % % % % % %
%% handling instructions from user/implementation/controller
%% % % % % % %
handle_event(info, {act, send, Label, Msg}, _State, #statem_data{ name=Name, coparty_id = _CoPartyID, init_state=_InitState, states = _States, msgs = _Msgs, timeouts = _Timeouts, state_map = _StateMap, queued_actions = _Queue, options = _Options} = _StatemData) ->
    % printout(Name, "~p, wrong state to recv (~p: ~p), postponing.", [State, Label, Msg]),
    io:format("\n"),
    printout(Name, "~p, {act, send, ~p, ~p}...", [?FUNCTION_NAME, Label, Msg]),
    {keep_state_and_data, [{next_event, cast, {send, Label, Msg}}]};

handle_event(info, {act, recv, Label}, _State, #statem_data{ name=Name, coparty_id = _CoPartyID, init_state=_InitState, states = _States, msgs = _Msgs, timeouts = _Timeouts, state_map = _StateMap, queued_actions = _Queue, options = _Options} = _StatemData) ->
    % printout(Name, "~p, wrong state to recv (~p: ~p), postponing.", [State, Label, Msg]),
    io:format("\n"),
    printout(Name, "~p, {recv, ~p},\n\n\tThis is a mistake! To retrieve messages use:\n\t\t\"gen_statem(?THIS_PID, {recv, ~p}).\"", [?FUNCTION_NAME, Label, Label]),
    {keep_state_and_data, [{next_event, cast, {recv, Label}}]};





%% % % % % % %
%% custom init/stop wrappers
%% % % % % % %

%% catch before start (to receive the CoPartyID)
handle_event(enter, _OldState, init_setup_state=State, #statem_data{name=Name, coparty_id = undefined, init_state=_InitState, states = _States, msgs = _Msgs, timeouts = _Timeouts, state_map = _StateMap, queued_actions = _Queue, options = _Options} = StatemData) -> 
    printout(Name, "(->) ~p.", [State]),
    {keep_state, StatemData, [{state_timeout, 0, wait_to_finish}]};
handle_event(state_timeout, wait_to_finish, init_setup_state=State, #statem_data{name=Name, coparty_id = undefined, init_state=InitState, states = States, msgs = Msgs, timeouts = Timeouts, state_map = StateMap, queued_actions = Queue, options = Options} = _StatemData) ->
    printout(Name, "~p, waiting to finish setup.", [State]),
    receive
        {_SupID, sup_init, CoID} ->
            printout(Name, "~p, received coparty ID (~p).", [State,CoID]),
            {next_state, InitState, #statem_data{ name=Name,
                                                         coparty_id = CoID, 
                                                         init_state = InitState,
                                                         states = States,
                                                         msgs = Msgs,
                                                         timeouts = Timeouts,
                                                         state_map = StateMap,
                                                         queued_actions = Queue,
                                                         options = Options }}
    end;

%% catch before stop
handle_event(enter, _OldState, stop_state=State, #stop_data{reason = _Reason, statem_data = _StatemData} = Data) -> 
    printout("(->) ~p.", [State]),
    {keep_state, Data, [{state_timeout, 0, exit_deferral}]};
handle_event(state_timeout, exit_deferral, stop_state=State, #stop_data{reason = Reason, statem_data = #statem_data{name=Name, coparty_id = _CoPartyID, init_state=_InitState, states = _States, msgs = _Msgs, timeouts = _Timeouts, state_map = _StateMap, queued_actions = _Queue, options = _Options} = StatemData} = Data) -> 
    printout(Name, "~p, ~p, StatemData: \n\t~p.", [State, Reason, StatemData]),
    {stop, Reason, Data};





%% % % % % % %
%% states enter
%% % % % % % %


%% state enter, issue timeout (stop and cause supervisor to notice)
handle_event(enter, _OldState, issue_timeout=State, #statem_data{ name=Name, coparty_id = _CoPartyID, init_state=_InitState, states = _States, msgs = _Msgs, timeouts = _Timeouts, state_map = _StateMap, queued_actions = _Queue, options = _Options} = StatemData) ->
    printout(Name, "(->) ~p.", [State]),
    {keep_state, #stop_data{reason = error_exceeded_throttling_capacity, statem_data = StatemData}, [{state_timeout, 0, goto_stop}]};
handle_event(state_timeout, goto_stop, issue_timeout=_State, Data) ->
    {next_state, stop_state, Data};


%% state enter, mixed choice (and no queued actions)
handle_event(enter, _OldState, State, #statem_data{ name=Name, coparty_id = _CoPartyID, init_state=_InitState, states = _States, msgs = _Msgs, timeouts = Timeouts, state_map = StateMap, queued_actions = [], options = _Options} = StatemData)
    when is_map_key(State, Timeouts) ->
        {TimeoutDuration, TimeoutState} = maps:get(State, Timeouts),
        Actions = maps:get(State, StateMap, none),
        printout(Name, "(->) ~p [t:~p], available actions: ~p.", [State, TimeoutDuration, Actions]),
        if Actions=:=none -> printout(Name, "~p, StateMap: ~p.", [State, StateMap]); true-> ok end,
        {keep_state, StatemData, [{state_timeout, TimeoutDuration, TimeoutState}]};


%% state enter, no queued actions and no mixed-choice
handle_event(enter, _OldState, State, #statem_data{ name=Name, coparty_id = _CoPartyID, init_state=_InitState, states = _States, msgs = _Msgs, timeouts = _Timeouts, state_map = StateMap, queued_actions = [], options = _Options} = _StatemData) ->
    Actions = maps:get(State, StateMap, none),
    printout(Name, "(->) ~p: ~p.", [State, Actions]),
    if Actions=:=none -> printout(Name, "~p, StateMap: ~p.", [State, StateMap]); true-> ok end,
    keep_state_and_data;


%% state enter, handle queued actions
handle_event(enter, _OldState, State, #statem_data{ name=Name, coparty_id = _CoPartyID, init_state=_InitState, states = _States, msgs = _Msgs, timeouts = _Timeouts, state_map = _StateMap, queued_actions = [_H], options = _Options} = _StatemData) ->
    printout(Name, "(->) ~p, with queued actions.", [State]),
    {keep_state_and_data, [{state_timeout,0,process_queue}]};
handle_event(enter, _OldState, State, #statem_data{ name=Name, coparty_id = _CoPartyID, init_state=_InitState, states = _States, msgs = _Msgs, timeouts = _Timeouts, state_map = _StateMap, queued_actions = [_H|T], options = _Options} = _StatemData) ->
    printout(Name, "(->) ~p, with (~p) queued actions.", [State, length(T)+1]),
    {keep_state_and_data, [{state_timeout,0,process_queue}]};
handle_event(state_timeout, process_queue, State, #statem_data{ name=Name, coparty_id = CoPartyID, init_state=InitState, states = States, msgs = Msgs, timeouts = Timeouts, state_map = StateMap, queued_actions = [H|T], options = Options} = _StatemData) ->
    printout(Name, "(->) ~p, queued action: ~p.", [State, H]),
    StatemData1 = #statem_data{ name=Name,
                                coparty_id = CoPartyID,
                                init_state = InitState,
                                states = States,
                                msgs = Msgs,
                                timeouts = Timeouts,
                                state_map = StateMap,
                                queued_actions = T,
                                options = Options },
    {repeat_state, StatemData1, [{next_event, cast, H}]};



%% % % % % % %
%% sending actions, from correct states
%% % % % % % %
handle_event(cast, {send, Label, Msg}, State, #statem_data{ name=Name, coparty_id = CoPartyID, init_state=InitState, states = States, msgs = Msgs, timeouts = Timeouts, state_map = StateMap, queued_actions = Queue, options = Options} = _StatemData) 
    when is_map_key(State, StateMap)
    and is_atom(map_get(Label, map_get(send, map_get(State, StateMap)))) ->
    CoPartyID ! {self(), Label, Msg},
    NextState = maps:get(Label, maps:get(send, maps:get(State, StateMap))),
    StatemData1 = #statem_data{ name=Name,
                                coparty_id = CoPartyID,
                                init_state = InitState,
                                states = [NextState] ++ States,
                                msgs = Msgs,
                                timeouts = Timeouts,
                                state_map = StateMap,
                                queued_actions = Queue,
                                options = Options },
    printout(Name, "~p, send (~p: ~p).", [State, Label, Msg]),
    {next_state, NextState, StatemData1};



%% % % % % % %
%% sending actions, from wrong states
%% % % % % % %
handle_event(cast, {send, Label, Msg}, State, #statem_data{ name=Name, coparty_id = CoPartyID, init_state=InitState, states = States, msgs = Msgs, timeouts = Timeouts, state_map = StateMap, queued_actions = Queue, options = Options} = _StatemData) ->
    printout(Name, "~p, wrong state to send (~p: ~p), adding to queue.", [State, Label, Msg]),
    StatemData1 = #statem_data{ name=Name,
                                coparty_id = CoPartyID,
                                init_state = InitState,
                                states = States,
                                msgs = Msgs,
                                timeouts = Timeouts,
                                state_map = StateMap,
                                queued_actions = Queue ++ [{send, Label, Msg}],
                                options = Options },
    {keep_state, StatemData1};



%% % % % % % %
%% receiving actions, from correct states
%% % % % % % %
handle_event(info, {CoPartyID, Label, Msg}, State, #statem_data{ name=Name, coparty_id = CoPartyID, init_state=InitState, states = States, msgs = Msgs, timeouts = Timeouts, state_map = StateMap, queued_actions = Queue, options = Options} = _StatemData) 
    when is_map_key(State, StateMap)
    and is_atom(map_get(Label, map_get(recv, map_get(State, StateMap)))) ->    
    %% forward if necessary
    {ForwardMsg, ForwardTo} = maps:get(forward_receptions, Options),
    if ForwardMsg -> ForwardTo ! {self(), Label, Msg} end,
    %% add message to the front of the queue of messages received by this label
    case maps:find(Label, Msgs) of
        {ok, StateMsgs} -> 
            Msgs1 = maps:put(Label, [Msg] ++ StateMsgs, Msgs);
        error -> 
            Msgs1 = maps:put(Label, [Msg], Msgs)
    end,
    NextState = maps:get(Label, maps:get(recv, maps:get(State, StateMap))),
    StatemData1 = #statem_data{ name=Name,
                                coparty_id = CoPartyID,
                                init_state = InitState,
                                states = [NextState] ++ States,
                                msgs = Msgs1,
                                timeouts = Timeouts,
                                state_map = StateMap,
                                queued_actions = Queue,
                                options = Options },
    printout(Name, "~p, recv (~p: ~p) -> ~p.", [State, Label, Msg, NextState]),
    {next_state, NextState, StatemData1};



%% % % % % % %
%% receiving actions, from wrong states
%% % % % % % %
handle_event(info, {CoPartyID, Label, Msg}, State, #statem_data{ name=Name, coparty_id = CoPartyID, init_state=_InitState, states = _States, msgs = _Msgs, timeouts = _Timeouts, state_map = _StateMap, queued_actions = _Queue, options = _Options} = _StatemData) ->
    printout(Name, "~p, wrong state to recv (~p: ~p), postponing.", [State, Label, Msg]),
    {keep_state_and_data, [postpone]};



%% % % % % % %
%% mixed-choice (timeouts)
%% % % % % % %
handle_event(state_timeout, NextState, State, #statem_data{ name=Name, coparty_id = _CoPartyID, init_state=_InitState, states = _States, msgs = _Msgs, timeouts = _Timeouts, state_map = _StateMap, queued_actions = _Queue, options = _Options} = StatemData) ->
    printout(Name, "~p, internal timeout (~p).", [State, NextState]),
    {next_state, NextState, StatemData};



%% % % % % % %
%% retreive latest message of given label
%% % % % % % %
handle_event({call, From}, {recv, Label}, State, #statem_data{ name=Name, coparty_id = _CoPartyID, init_state=_InitState, states = _States, msgs = Msgs, timeouts = _Timeouts, state_map = _StateMap, queued_actions = _Queue, options = _Options} = _StatemData) -> 
    printout(Name, "~p, ~p, looking for msg with label (~p).", [?FUNCTION_NAME, State, Label]),
    case maps:find(Label, Msgs) of
        {ok, [H]=Matches} -> 
            printout("~p, ~p, found msg (~p: ~p) out of 1.", [?FUNCTION_NAME, State, Label, H]),
            ReplyMsg = {ok, #{  label => Label, msg => H, total => 1, matches => Matches }};
        {ok, [H|T]=Matches} -> 
            NumMsgs = lists:length(T)+1,
            printout("~p, ~p, found msg (~p: ~p) out of ~p.", [?FUNCTION_NAME, State, Label, H, NumMsgs]),
            ReplyMsg = {ok, #{  label => Label, msg => H, total => NumMsgs, matches => Matches }};
         error -> 
            printout("~p, ~p, no msgs with label (~p) found.", [?FUNCTION_NAME, State, Label]),
            ReplyMsg = {error, no_msg_found_under_label}
    end,
    {keep_state_and_data, [{reply, From, ReplyMsg}]};


%% % % % % % %
%% handle external requests to change options
%% % % % % % %
handle_event({call, From}, {options, Key, Val}, _State, #statem_data{ name=Name, coparty_id = CoPartyID, init_state=InitState, states = States, msgs = Msgs, timeouts = Timeouts, state_map = StateMap, queued_actions = Queue, options = Options} = _StatemData) 
  when is_map_key(Key, Options) ->    
    printout(Name, "~p, changing option: ~p => ~p}.", [?FUNCTION_NAME, Key, Val]),
    Data1 = #statem_data{ name = Name,
                          coparty_id = CoPartyID,
                          init_state = InitState,
                          states = States,
                          msgs = Msgs,
                          timeouts = Timeouts,
                          state_map = StateMap,
                          queued_actions = Queue,
                          options = maps:put(Key, Val, Options) },
    {keep_state, Data1, [{reply, From, ok}]};


%% % % % % % %
%% anything else
%% % % % % % %
handle_event(EventType, EventContent, State, Data) ->
    printout(Data#statem_data.name, "error, reached unknown event:\n\tEventType: ~p,\n\tEventContent: ~p,\n\tState: ~p,\n\tData: ~p.", [EventType, EventContent, State, Data]),
    {next_state, stop_state, #stop_data{ reason = unknown_event_to_handle, statem_data = Data}}.



