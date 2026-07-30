local function reevaluateResearch(force, packName)
  for _, i in pairs(force.technologies) do
    if not i.researched then
      if i.prototype.research_trigger then
        if i.prototype.research_trigger["type"] == "craft-item" then
          if i.prototype.research_trigger["item"].name == packName then -- idk why tf its .item.name here but ok
            local researchable = true
            for j, h in pairs(i.prerequisites) do
              if not h.researched then
                researchable = false
                break
              end
            end
            if researchable then
              force.technologies[i.name].researched = true
              break
            end
          end
        end
      end
    end
  end
end

local function testDetonation(force, warhead)
  local packName = "test-pack" .. warhead.name .. warhead.label
  --[[if not storage.nuclearTests then
    storage.nuclearTests = {}
  end
  if not storage.nuclearTests[force.index] then
    storage.nuclearTests[force.index] = {}
  end
  if not storage.nuclearTests[force.index][packName] then
    storage.nuclearTests[force.index][packName] = 0
  end
  storage.nuclearTests[force.index][packName] = storage.nuclearTests[force.index][packName]+1]]
  reevaluateResearch(force, packName)
end
--script.on_event(defines.events.on_research_started, reevaluateResearchFull)
return {testDetonation = testDetonation}
