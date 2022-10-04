------------------- Queue Stuff
Queue = {}

function Queue.new()
    return {first = 0, last = -1, data = {}}
end

-- Grab last value in Queue
function Queue.push(q, value)
    q.last = q.last + 1
    q.data[q.last] = value
end

function Queue.peek(q)
    if (Queue.empty(q)) then return nil end

    return q.data[q.first]
end

-- Grab first value in Queue
function Queue.pop(q)
    if (Queue.empty(q)) then error("Queue is empty") end

    local value = q.data[q.first]

    -- Clear value
    q.data[q.first] = nil

    -- Increment
    q.first = q.first + 1

    return value
end

-- Returns size of queue
function Queue.size(q)
    return (q.last - q.first) + 1
end

-- Goes through all values and sets to nil
function Queue.clear(q)
    while not Queue.empty(q) do
        Queue.pop(q) -- Ignore return value since we're clearing
    end
end

function Queue.empty(q)
    return q.first > q.last
end