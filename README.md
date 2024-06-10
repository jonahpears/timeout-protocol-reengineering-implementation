Erlang on TOAST artifact,

GitHub <https://github.com/jonahpears/Erlang-on-TOAST-timeout-protocol-reengineering-implementation->

An extension (fork) of:
Protocol re-engineering artifact,
GitHub  <https://github.com/LauraVoinea/protocol-reengineering-implementation>

# this tools is currently still a work in progress
> as of 10th June 2024, this tool is still in progress, but now features an example of how to run two stubs generated by this tool (with or without monitors) under [`/sample_project/`](https://github.com/jonahpears/Erlang-on-TOAST-timeout-protocol-reengineering-implementation-/tree/main/sample_project).

> as of 8th June 2024 this tool is being developed/finished ASAP. this README will be updated to say when it is finished.

### todo

- update readme properly
- improve `sample_app` directory tutorial/example
- add sample `configuration presets` for monitors (verify only, enforce light, enforce strong) - (currently, these have to be configured manually over several options. adding presets would essentially bundle sets of options together.)
- update monitors with functionality developed recently, and clear up the file
- clean up repo (alot of remnants from the original project still exist that are no longer relevant.)


## 1. Getting started guide

This is a tool for composing protocols, generating state machines based on
protocol specification, and extracting protocols from existing code.

The protocol type is defined within interleave.erl. This file also contains a few
examples together with the algorithm for protocol composition.

### Prerequisites

The following software needs to be installed:

- Erlang: Erlang/OTP 24 Erts 12.2.1
- rebar3: rebar 3.17.0

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
