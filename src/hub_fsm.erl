-module(hub_fsm).
-compile([export_all]).

-behaviour(gen_fsm).

-record(hubStatus, {
    sock,
    lock_key,
    pk_key,
    key,
    hubname,
    nick,
    pass,
    is_loggedin    
}).

start_link(Args) ->
    gen_fsm:start_link({'local', 'hub_fsm'}, 'hub_fsm', Args, []).

validate_command(Command) ->
    L = lists:last(Command),
    F = lists:first(Command),
    if 
        (L == $|) and (F == $$) -> 'ok';
        true -> 'nil'
    end.

parse_commands([], R) ->
    R;
parse_commands([Command | T] = Commands, R) ->
    case validate_command(Command) of
        'ok' -> parse_commands(T, R ++ [Command]);
        _ -> parse_commands(T, R)
    end.

list_commands(Msgs) ->
    Commands = string:tokens(Msgs, "|"),
    parse_commands(Commands, []).

process_message(Msg) ->
    lists:map(
        fun(C) -> gen_fsm:send_event('hub_fsm', {'command', C}) end,
        list_commands(Msg)
    ).

send_command(C, Status) ->
    gen_tcp:send(Status#hubStatus.sock, "$" ++ C ++ "|").

init({Sock, Nick, Pass}) ->
    {'ok', 'unknown', #hubStatus{is_loggedin = false, sock = Sock, nick = Nick, pass = Pass}}.

unknown({'command', C}, Status) ->
    case scan_command('lock', C, Status) of
        {'ok', NewStatus} ->
            {'next_state', 'nick', NewStatus};
        E -> 
            {'next_state', 'unknown', Status}
    end.

nick({'command', C}, Status) ->
    case scan_command('validate_denide', C, Status) of
        {'ok', NewStatus} ->
            {'stop', 'denied', NewStatus};
        E -> 
            case scan_command('get_pass', C, Status) of
                {'ok', NewStatus} ->
                    {'next_state', 'pass_validation', NewStatus};
                E0 -> 
                    {'next_state', 'unknown', Status}
            end
    end.

pass_validation({'command', C}, Status) ->
    case scan_command('bad_pass', C, Status) of
        {'ok', NewStatus} ->
            {'stop', 'denied', NewStatus};
        E -> case scan_command('loggedin', C, Status) of
                {'ok', NewStatus} ->
                    {'stop', 'loggedin', NewStatus};
                E0 -> 
                    {'stop', 'denied', Status}
            end
    end.    

command_to_tuple(C) ->
    list_to_tuple(string:tokens(C, " ")).

scan_command(NextCommand, C, Status) ->
    CT = command_to_tuple(C),
    case parse_command(NextCommand, CT, Status) of
        {'ok', NewStatus} = R -> R;
        E -> E
    end.

parse_command('lock', {"Lock", LockKey, "Pk", PkKey} = C, Status) ->
    Key = lock2key:lock2key(LockKey),
    NewStatus = Status#hubStatus{
        'lock_key' = LockKey,
        'pk_key' = PkKey,
        'key' = Key
        },
    send_command("Key " ++ Key, NewStatus#hubStatus.sock),
    send_command("ValidateNick " ++ NewStatus#hubStatus.nick, NewStatus#hubStatus.sock),
    {'ok', NewStatus};
parse_command('validate_denide', {"ValidateDenide"} = C, Status) ->
    NewStatus = Status#hubStatus{
        'lock_key' = 'nil',
        'pk_key' = 'nil',
        'key' = 'nil'
        },
    {'ok', NewStatus};
parse_command('get_pass', {"GetPass"} = C, Status) ->
    send_command("MyPass " ++ Status#hubStatus.pass, Status#hubStatus.sock),
    {'ok', Status};
parse_command('get_pass', {"BadPass"} = C, Status) ->
    {'ok', Status};
parse_command('loggedin', {"LoggedIn"} = C, Status) ->    
    NewStatus = Status#hubStatus{
        'is_loggedin' = true
        },
    {'ok', NewStatus};
parse_command(_, _, _) ->
    {'error', "Failed to parse command"}.
