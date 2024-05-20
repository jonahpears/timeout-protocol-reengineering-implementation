-compile({nowarn_unused_function, [ {reng_show,2} ]}).

-record(graph, {graph_ref, name, type}).

-record(edge_data, {event_type, event, trans_type, timeout, pattern, args, guard, code, attributes, comments = []}).
-record(edge, {from, to, edge_data, is_silent = false, is_delayable_send = false, is_custom_end = false, is_internal_timeout_to_supervisor = false }).

-record(trans, {from, to, data}).
-record(data, {action, var, event, cons = []}).


-record(clock_value, {is_abs, lower_bound, upper_bound}).
-record(clock, {label, value, is_global}).

reng_show(edge, Edge) -> 
  io:format("edge.from: ~p.\n", [Edge#edge.from]),
  io:format("edge.to: ~p.\n", [Edge#edge.to]),
  io:format("edge.is_silent: ~p.\n", [Edge#edge.is_silent]),
  io:format("edge.is_delayable_send: ~p.\n", [Edge#edge.is_delayable_send]),
  io:format("edge.is_custom_end: ~p.\n", [Edge#edge.is_custom_end]),
  io:format("edge.is_internal_timeout_to_supervisor: ~p.\n", [Edge#edge.is_internal_timeout_to_supervisor]),
  reng_show(edge_data, Edge#edge.edge_data);


reng_show(edge_data, EdgeData) -> 
  io:format("edge_data.args: ~p.\n", [EdgeData#edge_data.args]),
  io:format("edge_data.attributes: ~p.\n", [EdgeData#edge_data.attributes]),
  io:format("edge_data.code: ~p.\n", [EdgeData#edge_data.code]),
  io:format("edge_data.comments: ~p.\n", [EdgeData#edge_data.comments]),
  io:format("edge_data.event: ~p.\n", [EdgeData#edge_data.event]),
  io:format("edge_data.event_type: ~p.\n", [EdgeData#edge_data.event_type]),
  io:format("edge_data.guard: ~p.\n", [EdgeData#edge_data.guard]),
  io:format("edge_data.pattern: ~p.\n", [EdgeData#edge_data.pattern]),
  io:format("edge_data.timeout: ~p.\n", [EdgeData#edge_data.timeout]),
  io:format("edge_data.trans_type: ~p.\n", [EdgeData#edge_data.trans_type]);

reng_show(Kind, Record) -> io:format("unexpected kind ~p: ~p.\n", [Kind, Record]).