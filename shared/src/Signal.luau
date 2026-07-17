--!strict
-- Signal.lua
-- Lightweight custom event class (avoids BindableEvent overhead, works for pure Lua-side pub/sub).
-- Usage:
--   local mySignal = Signal.new()
--   local connection = mySignal:Connect(function(a, b) ... end)
--   mySignal:Fire(a, b)
--   connection:Disconnect()

local Signal = {}
Signal.__index = Signal

type Callback = (...any) -> ()

export type Connection = {
	Disconnect: (self: Connection) -> (),
	Connected: boolean,
}

export type SignalObject = {
	Connect: (self: SignalObject, callback: Callback) -> Connection,
	Once: (self: SignalObject, callback: Callback) -> Connection,
	Fire: (self: SignalObject, ...any) -> (),
	DisconnectAll: (self: SignalObject) -> (),
	Destroy: (self: SignalObject) -> (),
}

local Connection = {}
Connection.__index = Connection

local function newConnection(signal, callback: Callback)
	local self = setmetatable({}, Connection)
	self._signal = signal
	self._callback = callback
	self.Connected = true
	return self
end

function Connection:Disconnect()
	if not self.Connected then
		return
	end
	self.Connected = false
	local signal = self._signal
	for i, conn in ipairs(signal._connections) do
		if conn == self then
			table.remove(signal._connections, i)
			break
		end
	end
end

function Signal.new(): SignalObject
	local self = setmetatable({}, Signal)
	self._connections = {}
	return (self :: any)
end

function Signal:Connect(callback: Callback): Connection
	local conn = newConnection(self, callback)
	table.insert(self._connections, conn)
	return (conn :: any)
end

function Signal:Once(callback: Callback): Connection
	local conn
	conn = self:Connect(function(...)
		conn:Disconnect()
		callback(...)
	end)
	return conn
end

function Signal:Fire(...: any)
	-- Copy the list first: callbacks may Connect/Disconnect during iteration.
	local connectionsCopy = table.clone(self._connections)
	for _, conn in ipairs(connectionsCopy) do
		if conn.Connected then
			local ok, err = pcall(conn._callback, ...)
			if not ok then
				warn("[Signal] listener error:", err)
			end
		end
	end
end

function Signal:DisconnectAll()
	self._connections = {}
end

function Signal:Destroy()
	self:DisconnectAll()
end

return Signal
