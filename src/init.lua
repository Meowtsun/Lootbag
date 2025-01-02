
--[[
	
	Lootbag:
		- LootTable generator for Roblox with built-in luck system
	
	
	Quick Start:
		local Lootbag = require(...)
		local rarity = Lootbag.new('Rarity')
		local server_luck = 3
		
		rarity:AddItem('Common', 1/4)
		rarity:AddItem('Unommon', 1/8)
		rarity:AddItem('Rare', 1/16)
		
		local result = rarity:GetItem(server_luck)
		print(result)
		
		-- testing result with and without luck (check output)
		rarity:Sample(100, server_luck)
		rarity:Sample(100)


	API:
		Lootbag.new() -> Lootbag
			- create and return Lootbag object
		
		
		Lootbag:AddItem(item, weight, label) -> nil
			- add item to Lootbag, You can add [label] to item if you need to remove them later
		
		
		Lootbag:RemoveItem(label)
			- remove item inside Lootbag using [label] previously added


		Lootbag:RemoveIf(predicate)
			- remove item using given function, remove Item if said function return true
			
				lootbag:AddItem(Instance.new('Part'), 1/2)
				lootbag:RemoveIf(function(item)
					if item.Name == 'Part' then
						return true -- removing it
					end
				end)
				
			
		Lootbag:GetItem(luck, retries)
			- get Item from Lootbag relative to luck and retries, return Item and weight of said Item
			
			
		Lootbag:GetItems(count, luck, retries)
			- get multiple Items from Lootbag relative to luck and retries, return a table
			
				table: {
					{
						Weight: number,
						Value: number,
						Item: any,
					},
					...
				}
				
			
		Lootbag:Sample(count, luck, retries)
			- get multiple Items from Lootbag relative to luck and retries, print result in output and return table
			
				table: {
					{
						Weight: number,
						Value: number,
						Item: any,
					},
					...
				}
				
				
		Lootbag:ListItems(usePercentage)
			- return table containing all Items, optionally accept boolean to replace weight with percentage
			
				table: {
					{
						Weight: number,
						Value: number,
						Item: any,
					},
					...
				}
			
			
			
	Licence: MIT licence


	Authors:
		Huonzales - Sep 8th, 2024
		
]]


local Lootbag = { Name = 'Lootbag', Factor = 1.2 }
local Module = {}
Module.__index = Lootbag

-- I assumed nobody would want to edit this on run-time?
local lowestBound = 1e-3
local weightAdjustment = 1e9


local function rollnumber(max, factor, luck)
	return math.max(
		lowestBound, max - math.floor(max * math.random() ^ (factor / luck))
	)
end


local function weightedSort(a, b)
	return a.Weight > b.Weight
end


local function nameFormat(item)
	return item.Label
		or tostring(item.Item)
end


-- create and return Lootbag object
function Module.new(name)
	return setmetatable({
		Name = name,
		Factor = nil,
		Weight = 0,
		Items = {
		--[[
			Item,
			...
		]]
		},
	}, Module)
end


-- add item to Lootbag, You can add [label] to item if you need to remove them later
function Lootbag:AddItem(item, weight, label)
	local total = #self.Items
	
	local weight = weight * weightAdjustment
	local position = math.max(1, total + 1)
	
	if total > 0 then
		for index = total, 1, -1 do
			local item = self.Items[index]
			if item.Weight <= weight then
				position = index
			else
				break
			end
		end
	end
	
	table.insert(self.Items, position, {
		Weight = weight,
		Item = item,
		Label = label,
	})
	
	self.Weight += weight
end


-- remove item inside Lootbag using [label] previously added
function Lootbag:RemoveItem(label)
	for index = #self.Items, 1, -1 do
		local item = self.Items[index]
		if item.Label == label then
			self.Weight -= item.Weight
			table.remove(self.Items, index)
		end
	end
end


-- remove item using given function, remove Item if said function return true
function Lootbag:RemoveIf(predicate)
	for index = #self.Items, 1, -1 do
		local item = self.Items[index]
		if predicate(item.Item) == true then
			self.Weight -= item.Weight
			table.remove(self.Items, index)
		end
	end
end


-- get Item from Lootbag relative to luck and retries, return Item and weight of said Item
function Lootbag:GetItem(luck, retries)
	
	local luck = math.clamp(luck or 1, lowestBound, math.huge)
	local best_score, best_item, entry = math.huge, nil
	local retries = retries or 1
	
	for index = 1, retries do
		local value = rollnumber(self.Weight, self.Factor, luck)
		local upperbound = 0
		
		for index = #self.Items, 1, -1 do
			local item = self.Items[index]
			upperbound += item.Weight
			
			print(value <= upperbound, ';', value, upperbound)
			-- print delay it for a sec and now it just works 
			
			if value <= upperbound and item.Weight < best_score then
				best_score, best_item, entry = item.Weight, item.Item, index
				break
			end
		end
	end
	
	if not best_item then
		local item = self.Items[1]
		best_score = item.Weight
		best_item = item.Item
		entry = 1
	end

	return best_item, best_score / weightAdjustment, entry
end


-- get multiple Items from Lootbag relative to luck and retries, return a table
function Lootbag:GetItems(count, luck, retries)
	
	local result = {}
	local temp = {
		--[[
			[item]: {
				Weight: number,
				Value: number,
			},
			...
		]]
	}
	
	for index = 1, count or 1 do
		local item, weight = self:	GetItem(luck, retries)
		if temp[item] then
			temp[item].Value += 1
			continue
		end
		
		temp[item] = {
			Weight = weight,
			Value = 1
		}
	end
	
	for item, info in temp do
		table.insert(result, {
			Weight = info.Weight,
			Value = info.Value,
			Item = item,
		})
	end
	
	table.sort(result, weightedSort)
	table.clear(temp)

	return result
end


-- get multiple Items from Lootbag relative to luck and retries, print result in output and return table
function Lootbag:Sample(count, luck, retries)
	local result = {}
	
	for index, item in self.Items do
		local copy = table.clone(item)
		copy.Value = 0
		result[index] = copy
	end
	
	for index = 1, count do
		local item, weight, entry = self:GetItem(luck, retries)
		result[entry].Value += 1
	end
	
	local log = `[Lootbag]: {count} Samples (Luck:{luck or 0}, Retries:{retries or 0}) `
	for _, item in result do
		local estimated_rarity = string.format('%.3f', item.Weight / self.Weight * 100)
		local sampled_rarity = string.format('%.3f', item.Value / count * 100)
		log ..= '\n	' .. `{nameFormat(item)}: {item.Value} [{estimated_rarity}% : {sampled_rarity}%]`
	end
	
	print(log)
	return result
end


-- return table containing all Items, optionally accept boolean to replace weight with percentage
function Lootbag:ListItems(usePercentage)
	local list = {}
	
	for index, item in self.Items do
		local copy =  table.clone(item)
		list[index] =copy
		if usePercentage then
			copy.Weight = item.Weight / self.Weight * 100
		end
	end
	
	return list
end



export type Item = {
	Weight: number,
	Item: any,
	Label: string,
	Value: number,
}


export type Lootbag = {
	
	Weight: number,
	Name: string,
	Factor: number,
	Items: {Item},
	
	AddItem: (self: Lootbag, item: any, weight: number, label: string?) -> (),
	RemoveIf: (self: Lootbag, predicate: (item: any) -> (boolean?))-> (),
	RemoveItem: (self: Lootbag, label: string) -> (),
	GetItem: (self: Lootbag, luck: number?, retries: number?) -> (any, number),
	GetItems: (self: Lootbag, count: number, luck: number?, retries: number?) -> ({Item}),
	Sample: (self: Lootbag, count: number, luck: number?, retries: number?) -> ({Item}),
	ListItems: (self:Lootbag, usePercentage: boolean?) -> ({Item}),
	
}



return Module 
