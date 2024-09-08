
--[[
	
	Lootbag:
		- LootTable generator for Roblox, with built-in luck system
		   
		   
	API:
		Lootbag.new() -> Lootbag
			- create and return lootbag object
			
		Lootbag:AddItem(item, weight) -> nil,
			- add item to lootbag
			
		Lootbag:GetItem(luck, retries)	 -> any, number
			- get one item from lootbag relative to luck and retries, returns item and weight
			
		Lootbag:GetItems(count, luck, retries) -> Items
			- perform multiple GetItem() then return Items table as result
			
			Items: {
				[item]: {
					Weight: number,
					Value: number,
				},
				...
			}
		
		Lootbag:Sample(count, luck, retries, format) -> nil
			- sample by getting {count} items from lootbag using provided luck and retries then printing entire result in output
			additionally accept format to format how item would be display in string
		
			format: (item) -> string
		
		Lootbag:ListItems(usePercentage) -> {[item]: number}
			- returns table that has items as key and weight or percentage as value, return weight by default 
		
		Lootbag:SetItem(item, weight) -> nil
			- similar to AddItem but would overwrite the same exact item in lootbag
			
		Lootbag:RemoveItem(item, weight) -> nil
			- remove the same exact item in lootbag
			
		Lootbag:RemoveIf(predicate) -> nil
			- remove item if predicate(item) return true
			
			predicate: (item) -> boolean
		
	Licence: MIT licence

	Authors:
		Huonzales - Sep 8th, 2024
]]

local WeightAdjustment = 1e9
local Lootbag = {}
Lootbag.__index = Lootbag


local function random(max, factor, luck)
	return math.max(0.001, max - math.floor(max * math.random() ^ (factor / luck)))
end

local function weightSort(a, b)
	return a.Weight > b.Weight
end

local function emptyformat(s)
	return s
end



function Lootbag.new()
	return setmetatable({
		Factor = 1.2,
		Weight = 0,
		Items = {
			--[[
				{
					Weight: number,
					Item: any,
				},
				...
			]]
		}
	}, Lootbag)
end



function Lootbag:AddItem(item, weight)
	local total = #self.Items
	
	local weight = weight * WeightAdjustment
	local position = math.max(1, total + 1)
	
	if total > 0 then
		for index = total, 1, -1 do
			local loot = self.Items[index] -- Hello c:
			if loot.Weight <= weight then
				position = index
			else
				break
			end
		end
	end
	
	table.insert(self.Items, position, {
		Item = item,
		Weight = weight,
	})
	
	self.Weight += weight
end



function Lootbag:GetItem(luck, retries)
	
	local best_score, best_item, entry = math.huge, nil
	local luck = math.clamp(luck or 1, 0.01, math.huge)
	local retries = retries or 1
	
	for index = 1, retries do
		local value = random(self.Weight, self.Factor, luck)
		local upperbound = 0
		
		for index = #self.Items, 1, -1 do
			local loot = self.Items[index]
			upperbound += loot.Weight
			if value <= upperbound and loot.Weight < best_score then
				best_score, best_item, entry = loot.Weight, loot.Item, index
				break
			end
		end
	end
	
	return best_item, best_score / WeightAdjustment, entry
end



function Lootbag:GetItems(count, luck, retries)
	
	local results = {
		--[[
			[item]: {
				Weight: number,
				Value: number,
			},
			...
		]]
	}
	
	for index = 1, count or 1 do
		local item, weight = self:GetItem(luck, retries)
		
		if results[item] then
			results[item].Value += 1
			continue
		end
		
		results[item] = {
			Weight = weight,
			Value = 1
		}
		
	end
	
	return results
end



function Lootbag:Sample(count, luck, retries, format)
	local tests = {}

	local luck = math.clamp(luck or 1, 0.01, math.huge)
	local format = format or emptyformat
	local retries = retries or 1

	for index ,loot in self.Items do
		tests[index] = table.clone(loot)
		tests[index].Count = 0
	end

	for index = 1, count do
		local item, chance, entry = self:GetItem(luck, retries)
		tests[entry].Count += 1
	end

	table.sort(tests, weightSort)

	local message = `[Lootbag]: {count} Samples (Luck:{luck}, Retries:{retries - 1}) `
	for _, loot in next, tests do
		local estimated_rarity = string.format('%.2f', loot.Weight / self.Weight * 100)
		local sampled_rarity = string.format('%.2f', loot.Count / count * 100)
		message ..= '\n	' .. `{format(loot.Item)}: {loot.Count} [{estimated_rarity}% : {sampled_rarity}%]`
	end

	print(message)
	return tests
end



function Lootbag:ListItems(usePercentage)
	local tests = {}

	for index ,loot in self.Items do
		tests[index] = table.clone(loot)
		tests[index].Weight = usePercentage
			and loot.Weight / self.Weight * 100 
			or self.Weight
	end
	
	return tests
end



function Lootbag:SetItem(item, weight)
	for _, loot in self.Items do
		if loot.Item == item then
			loot.Weight = weight
		end
	end
	
	table.sort(Lootbag, weightSort)
end



function Lootbag:RemoveItem(item)
	for index, loot in self.Items do
		if loot.Item == item then
			return table.remove(self.Items, index)
		end
	end
end



function Lootbag:RemoveIf(predicate)
	for index, loot in self.Items do
		if predicate(loot.Item) then
			table.remove(self.Items, index)
		end
	end
end


export type Lootbag = {
	
	Factor: number,
	Weight: number,
	Items: {
		{
			Weight: number,
			Item: any,
		}
	},
	
	AddItem: (self: Lootbag, item: any, weight: number) -> nil,
	GetItem: (self: Lootbag, luck: number?, retries: number?) -> nil,
	GetItems: (self: Lootbag, count: number?, luck: number?, retries: number?) -> nil,
	Sample: (self: Lootbag, count: number?, luck: number?, retries: number?, format: (item: any) -> (boolean?)) -> nil,
	ListItems: (self: Lootbag, usePercentage: boolean) -> nil,
	SetItem: (self: Lootbag, item: any, weight: number) -> nil,
	RemoveItem: (self: Lootbag, item: any) -> nil,
	RemoveIf: (self: Lootbag, predicate: (item: any) -> (boolean)) -> nil,
	
}


return Lootbag :: {
	new: () -> Lootbag
}
