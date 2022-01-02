local record Stack<T>
	items: {T}
end

function Stack.new<T>(): Stack<T>
	return setmetatable({ items = {} as {T} }, { __index = Stack })
end

function Stack:push<T>(item: T): Stack<T>
	table.insert(self.items, item)
	return self
end

function Stack:pop<T>():T
	if next(self.items) then
		return table.remove(self.items)
	end
end

function Stack:peek<T>():T
	return self.items[#self.items]
end

return Stack