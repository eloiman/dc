-module(lock2key).
-compile([export_all]).

lock2key(Lock) ->
    [First | Tail] = Lock,
    {Key, _} = lists:mapfoldl(fun(Cur, Prev) -> {Cur bxor Prev, Cur} end, First, Tail),
    [Lock1, Lock2] = lists:nthtail(length(Lock) - 2, Lock), [Lock0 | _] = Lock,
    Key2 = [Lock0 bxor Lock1 bxor Lock2 bxor 5 | Key],
    Key3 = lists:map(fun(Val) -> <<Hi:4, Low:4>> = <<Val>>, <<Res>> = <<Low:4, Hi:4>>, Res end, Key2),
    Key4 = lists:foldl(fun(Val, AccIn) ->
        AccIn ++
        if
            Val ==   0 -> "/%DCN000%/";
            Val ==   5 -> "/%DCN005%/";
            Val ==  36 -> "/%DCN036%/";
            Val ==  96 -> "/%DCN096%/";
            Val == 124 -> "/%DCN124%/";
            Val == 126 -> "/%DCN126%/";
            true -> [Val]
        end
    end, [], Key3),
    Key4.
