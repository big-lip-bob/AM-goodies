# Setup
Drop the Event Handler in your libs folder (default is `macros/libs`), and an entry where you Event Listener to Anything (you might want to filter out frequent events such as sounds or have one handler per event type so frequent events avoid triggerning other ones and iterating trough the whole parked listeners)
Then use one of the pulling/listening functions in your wanted scripts

# TODO
* `event.timer(interval: number, callback: function ,[times: number]): cancelation id : tabme`

# Functions
* `event.pull(filters: ...): pusher's arguments: ...`
* `event.pull_timed(timeout: number, filters: ...): pusher's arguments: ...`
* `event.pull_after(callback: function, filters: ...): pusher's arguments: ...`
* `event.pull_timed_after(timeout: number, callback: function, filters: ...): pusher's arguments: ...`
* `event.push(arguments: ...): pusher's arguments`
* `event.listen(callback: function, filters: ...): cancelation id : tabme`
* `event.ignore(cancelation id : number)`

* `event.new(mutex's name: string): event handler instance`
Above functions apply to said new event handler but it has a separate listeners queue

# Filters
When pulling for events, you can add filters the pusher will check agains't and see if it should resume the puller or not
The implemented types as arguments are :
* `nil` : always returns true
* Strings, Numbers and Booleans (basic types) : will do a simple equality check
* Tables : will check the truthyness of the value as the key for the table
* Functions : will pass the argument into the function, expects a boolean

# Examples
Soon, i don't have anything overly simple and that clearly demonstrates the superiority of the event handler (don't get me wrong, its already the superior solution)
