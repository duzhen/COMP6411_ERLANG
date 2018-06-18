-module(project).
-export([start_server/0, server/1, message/2, client/3]).

server(User_List) ->
    receive
        {PID, intro, From, To, Message} ->
            
            server_transfer(intro, PID, From, To, Message, User_List),
            io:format("~p list is now: ~n", [From]),
            server(User_List);
        {PID, reply, From, To, Message} ->
            
            server_transfer(reply, PID, From, To, Message, User_List),
            io:format("~p list is now: ~n", [From]),
            server(User_List)
    after 5000 ->
            io:format("No response server~n", []),
            exit(timeout)
    end.

%%% Start the server
start_server() ->

    register(john_PID, spawn(project, client, [self(), john, [jill,joe, bob]])),
    register(jill_PID, spawn(project, client, [self(), jill, [bob, joe, bob]])),
    register(sue_PID, spawn(project, client, [self(), sue, [jill,jill,jill,bob,jill]])),
    register(bob_PID, spawn(project, client, [self(), bob, [john]])),
    register(joe_PID, spawn(project, client, [self(), joe, [sue]])),
    server([{john_PID, john}, {jill_PID, jill}, {sue_PID, sue}, {bob_PID, bob}, {joe_PID, joe}]).

%%% Server transfers a message between user
server_transfer(Type, P, From, To, Message, User_List) ->
    %% check that the user is logged on and who he is
    case lists:keysearch(From, 2, User_List) of
        false ->
            P ! {messenger, stop, you_are_not_logged_on};
        {value, {PID, Name}} ->
            server_transfer(Type, PID, Name, To, Message, User_List, User_List)
    end.

%%% If the user exists, send the message
server_transfer(Type, From, Name, To, Message, User_List, User_List) ->
    %% Find the receiver and send the message
    case lists:keysearch(To, 2, User_List) of
        false ->
            From ! {messenger, receiver_not_found};
        {value, {ToPid, To}} ->
            io:format("~p~n~p~n", [ToPid, Message]),
            ToPid ! {Type, Name, Message}
            % From ! {messenger, sent} 
    end.

message(ToName, Message) ->
    case whereis(mess_client) of % Test if the client is running
        undefined ->
            not_logged_on;
        _ -> mess_client ! {message_to, ToName, Message},
             ok
end.

%%% The client process which runs on each user node
client(Server_Node, From, To) ->
    io:format("~p client start: ~n", [To]),
    [First | Rest ] = To,
    Server_Node ! {self(), intro, From, First, "intro"},
    await_result(Server_Node, From),
    case Rest of
        [] ->
            always_await_result(Server_Node, From);
        _ ->
        client(Server_Node, From, Rest)
    end.

%%% wait for a response from the server
await_result(Server_Node,From) ->
    receive
        % {messenger, stop, Why} -> % Stop the client 
        %     io:format("~p~n", [Why]),
        %     exit(normal);
        {intro, Name, Message} ->  % Normal response
            io:format("~p receive message from: ~p say: ~p~n", [From, Name, Message]),
            Server_Node ! {self(), reply, From, Name, "reply"};
            % await_result(Server_Node,From);
        {reply, Name, Message} ->  % Normal response
            io:format("Message reply: ~p say: ~p~n", [Name, Message])
            % await_result(Server_Node,From)
    after 5000 ->
            io:format("No response from server~n", []),
            exit(timeout)
    end.

always_await_result(Server_Node,From) ->
    receive
        {intro, Name, Message} ->  % Normal response
            io:format("~p receive message from: ~p say: ~p~n", [From, Name, Message]),
            Server_Node ! {self(), reply, From, Name, "reply"},
            always_await_result(Server_Node,From);
        {reply, Name, Message} ->  % Normal response
            io:format("Message reply: ~p say: ~p~n", [Name, Message]),
            always_await_result(Server_Node,From)
    after 5000 ->
            io:format("No response from server~n", []),
            exit(timeout)
    end.