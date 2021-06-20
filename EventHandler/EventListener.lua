require("EventSplitter"):push(select(... == "event" and 2 or 1,...))
-- (...)=="event" and 2 or 1 : transforming key and mouse into real event keys

