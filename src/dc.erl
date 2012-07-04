-module(dc).
-compile([export_all]).

connect_hub(Host, Port) ->
    {ok, Sock} = gen_tcp:connect(Host, Port, [{active,false}, {packet,2}]),
    hub_fsm:start_link({Sock, "AAA", "AAA"}),
    speak_to_hub(Sock),
    gen_tcp:close(Sock).

speak_to_hub(Sock) ->
    {ok, Packet} = gen_tcp:recv(Sock, 0),
    hub_fsm:process_message(Packet).
