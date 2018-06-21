-module(calling).
-export([start_calling/1, register_caller/3]).

%%% Start the master
start_calling(Calls) ->
    lists:foreach(fun start_calls/1, Calls).
    % TEST
    % register(john_PID, spawn(project, client, [self(), john, [jill,joe, bob]])),
    % register(jill_PID, spawn(project, client, [self(), jill, [bob, joe, bob]])),
    % register(sue_PID, spawn(project, client, [self(), sue, [jill,jill,jill,bob,jill]])),
    % register(bob_PID, spawn(project, client, [self(), bob, [john]])),
    % register(joe_PID, spawn(project, client, [self(), joe, [sue]])),
    % server([{john_PID, john}, {jill_PID, jill}, {sue_PID, sue}, {bob_PID, bob}, {joe_PID, joe}]).

 start_calls({Caller, Friends}) -> 
    spawn(calling, register_caller, [self(), Caller, Friends]),
    % register(Caller, spawn(project, client, [self(), Caller, Friends])),
    io:format("~p: ~p~n",[Caller, Friends]).


register_caller(Server_Node, From, To) ->
    Server_Node ! {self(), register, From},
    call_friends(Server_Node, From, To).

%%% The client process which runs on each user node
call_friends(Server_Node, From, To) ->
    % io:format("~p client start: ~n", [To]),
    [First | Rest ] = To,
    % timer:sleep(timer:seconds(rand:uniform(10))),
    timer:sleep(rand:uniform(100)),
    Server_Node ! {self(), intro, From, First, "intro"},
    await_result(Server_Node, From),
    case Rest of
        [] ->
            always_await_result(Server_Node, From);
        _ ->
        call_friends(Server_Node, From, Rest)
    end.