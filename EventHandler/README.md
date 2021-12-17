# Setup
Drop the Event Handler in your libs folder (default is `macros/libs`)
**Very Important** : Make an entry where you bind the Event Listener to Anything (Optionally Chat too as its not included in the Anything group)
(you might want to filter out frequent events such as sounds (or combine your handler implementation of choice with the Event Splitter))
Then push the received events to the event handler : `require("EventCollector"):push(select(... == "event" and 2 or 1,...))`

Then feel free to use one of the pulling/listening functions in your wanted scripts

# Functions
* `event:pull(filters: ...): pusher's arguments: ...`
* `event:pull_after(callback: function, filters: ...): pusher's arguments: ...` Calls your callback after registering, making so you wont potentially miss your wanted event given it happens extremly shortly after pulling

* `event:listen(callback: function, filters: ...): cancelation identifier: table`
* `event:listen_times(times: number, filters: ...): cancelation identifier: table` At most calls your callback the specified amount of times
* `event:cancel(cancelation identifier: table)`

* `event:push(arguments: ...): pusher's arguments`

* `event:new(mutex's name: string): event handler instance`

# TODO
* ~~`event:timer(interval: number, callback: function ,[times: number]): cancelation identifier : table`~~ Delegated to `timer` library
* Timer library for `timed` methods (`pull_timed`, `pull_timed_after`, `listen_timed`, `listen_timed_times`)

# Filters
When pulling for events, you can add filters the pusher will check agains't and see if it should resume the puller or not
The implemented types as arguments are :
* `nil` : always returns true
* Strings, Numbers and Booleans (basic types) : will do a simple equality check
* Tables : will check the truthyness of the value as the key for the table
* Functions : will pass the argument into the function, expects a boolean

# Examples
## Pushing : More Events
Check `EventMore.lua`

## Pulling

## Listening
