Erlang on TOAST artifact,

GitHub <https://github.com/jonahpears/Erlang-on-TOAST-timeout-protocol-reengineering-implementation->

An extension (fork) of:
Protocol re-engineering artifact,
GitHub  <https://github.com/LauraVoinea/protocol-reengineering-implementation>

# update (June 2024) 
The tool has now been overhauled and the entirty of the desired features are now implemented.
The remaining todo's are listed further below.

## for examples and demo please see [`/sample_project/`](https://github.com/jonahpears/Erlang-on-TOAST-timeout-protocol-reengineering-implementation-/tree/main/sample_project).

### todo
- Find a way to include macros in clauses when generating using `?Q([])` from `merl_build`, currently had to substitute macros in the stubs generated with `temp_` instead of `?`. The `?` itself seemed to be causing issues when using `?Q([])`. Currently thinking about trying to use parse_transform to fix this, along with adding comments inside bodies of functions (as this is another issue I have encountered when using `merl_build`).

### general todo
- update readme properly
- improve `sample_app` directory tutorial/example
- add sample `configuration presets` for monitors (verify only, enforce light, enforce strong) - (currently, these have to be configured manually over several options. adding presets would essentially bundle sets of options together.)
- clean up repo (alot of remnants from the original project still exist that are no longer relevant.)

#### monitors todo
In the current example, we have not showcased the enforcement monitoring tested in an earlier version.
- create an example that uses the enforcement monitoring,
- offer presets for easire configuration (currently, with the monitors the examples are based upon, you have to specify individual features and their constraints to get enforcement monitors).

#### mapping function
This is a stretch goal, to provide a mapping from a subset of TOAST protocols (session types) to the input language used by our tool.
- currently, there is a mapping function for TOAST with no timing constraints
- but we need to finish those with simple timing constraints (there are manual examples of simple timing constraints, but this has not been automated yet)

## 1. Getting started guide

This is a tool for composing protocols, generating state machines based on
protocol specification, and extracting protocols from existing code.

The protocol type is defined within interleave.erl. This file also contains a few
examples together with the algorithm for protocol composition.

### Building

The tool can be built using rebar3:
```erl
rebar3 compile
```

## Step-by-Step Instructions

### Stub Generation (via toolchain)

Compile and enter the rebar3 shell:
```erl
rebar3 compile; rebar3 shell
```

Run the following command:
```erl
gen_stub:gen(ProtocolName,Protocol,FileNameSuffix).
```

For example:
```erl
gen_stub:gen(basic_send_recv,ali:spec(basic_send_recv),"_ali_test.erl").
```
Will generate a stub named `basic_send_recv_ali_test.erl` to `/tool_output/`, using the protocol retrned by `ali:spec(basic_send_recv)`.

Alternatively, the above is the same as writing: (via a helper function)
```erl
gen_stub:gen(ali,spec,basic_send_recv,"_ali_test.erl").
```

Additionally, a file named `mon_spec_basic_send_recv_ali_test.erl` will be created in `/tool_output/` containing the FSM map used by the monitor.
This file is already included in the generated stubs automatically, to allow more convenient enabling/disabling of the runtime monitors.

### Running `/Sample Project/`

For now, please see [`/sample_project/`](https://github.com/jonahpears/Erlang-on-TOAST-timeout-protocol-reengineering-implementation-/tree/main/sample_project).
(This page will be updated shortly.)


# need to update

> The examples can be found under src/examples/
most of these examples will not work since we have removed some features from the original tool
