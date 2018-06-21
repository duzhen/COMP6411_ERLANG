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

%%% wait for a response from the server
await_result(Server_Node,From) ->
    receive
        % {messenger, stop, Why} -> % Stop the client 
        %     io:format("~p~n", [Why]),
        %     exit(normal);
        {intro, Name, Message} ->  % Normal response
            % io:format("~p receive message from: ~p say: ~p~n", [From, Name, Message]),
            Server_Node ! {self(), reply, From, Name, "reply"};
            % await_result(Server_Node,From);
        {reply, Name, Message} ->  % Normal response
            % io:format("Message reply: ~p say: ~p~n", [Name, Message])
            % await_result(Server_Node,From)
            pass
    after 1000 ->
            io:format("~nProcess ~p has received no calls for 1 second, ending...~n", [From]),
            exit(timeout)
    end.

always_await_result(Server_Node,From) ->
    receive
        {intro, Name, Message} ->  % Normal response
            % io:format("~p receive message from: ~p say: ~p~n", [From, Name, Message]),
            Server_Node ! {self(), reply, From, Name, "reply"},
            always_await_result(Server_Node,From);
        {reply, Name, Message} ->  % Normal response
            % io:format("Message reply: ~p say: ~p~n", [Name, Message]),
            always_await_result(Server_Node,From)
    after 1000 ->
            io:format("~nProcess ~p has received no calls for 1 second, ending...~n", [From]),
            exit(timeout)
    end.