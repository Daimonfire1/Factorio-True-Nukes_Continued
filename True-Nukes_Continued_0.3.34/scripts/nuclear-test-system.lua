local function reevaluateResearch(force)
  if not storage.nuclearTests then
    storage.nuclearTests = {}
  end
  if not storage.nuclearTests[force.index] then
    storage.nuclearTests[force.index] = {}
  end
  if(force.current_research) then
    local ingCount = 0
    for _,i in pairs(force.current_research.research_unit_ingredients) do
      if(string.match(i.name, "test.pack.atomic.*")) then
        ingCount = ingCount + i.amount
      else
        return
      end
    end
    ingCount = ingCount*force.current_research.research_unit_count
    local matchCount = 0
    for _,i in pairs(force.current_research.research_unit_ingredients) do
      matchCount = matchCount + math.min(storage.nuclearTests[force.index][i.name] or 0, i.amount*force.current_research.research_unit_count)
    end
    if(ingCount ~= 0) then -- just to really make sure we don't mess up any other mods...
      if(matchCount == ingCount) then
        --force.script_trigger_research()
        force.current_research.researched = true;
    else
      force.research_progress = (matchCount + 0.0)/ingCount
      for _,i in pairs(force.current_research.research_unit_ingredients) do
        if((storage.nuclearTests[force.index][i.name] or 0)<i.amount*force.current_research.research_unit_count) then
          force.print({"script-text.required-tests", (i.amount*force.current_research.research_unit_count-(storage.nuclearTests[force.index][i.name] or 0)), game.item_prototypes[i.name].localised_name})
        end
      end
    end
    end
  end
end

local function testDetonation(force, warhead)
  local packName = "test-pack" .. warhead.name .. warhead.label
  if not storage.nuclearTests then
    storage.nuclearTests = {}
  end
  if not storage.nuclearTests[force.index] then
    storage.nuclearTests[force.index] = {}
  end
  if not storage.nuclearTests[force.index][packName] then
    storage.nuclearTests[force.index][packName] = 0
  end
  storage.nuclearTests[force.index][packName] = storage.nuclearTests[force.index][packName]+1
  reevaluateResearch(force)
end
local function reevaluateResearchFull(event)
  for _,f in pairs(game.forces) do
    reevaluateResearch(f)
  end
end
script.on_event(defines.events.on_research_started, reevaluateResearchFull)
return {testDetonation = testDetonation}
