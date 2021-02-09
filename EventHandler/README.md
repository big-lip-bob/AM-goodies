# TODO
Finish my [OC Event API](https://ocdoc.cil.li/api:event) mimic
* `event.timer(interval: number, callback: function ,[times: number]): cancelation id : number`
* `event.listen(callback: function, filters: ...): cancelation id : number`
* `event.ignore(cancelation id : number): boolean`

# Functions
* `event.pull([timeout: number], filters: ...): pusher's arguments: ...`
* `event.push(arguments: ...): pusher's arguments: ...`

# Filters
When pulling for events, you can add filters the pusher will check agains't and see if it should resume the puller or not
The implemented types as arguments are :
* `nil` : always returns true
* Strings, Numbers and Booleans (basic types) : will do a simple equality check
* Tables : will check the truthyness of the value as the key for the table
* Functions : will pass the argument into the function, expects a boolean
