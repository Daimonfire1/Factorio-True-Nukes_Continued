-- Helper: normalise a Trigger / TriggerDelivery value (single item or array)
-- into an array we can safely iterate with ipairs.
local function as_array(t)
  if t == nil then return {} end
  if type(t) ~= "table" then return {} end
  if type(t.type) == "string" then return { t } end
  return t
end

-- Helper: recursively find the first delivery node that has a `projectile`
-- field. In Factorio 2.0+ the shotgun shell's projectile delivery is nested
-- inside target_effects -> nested-result -> area -> action_delivery.
local function find_projectile_delivery(node)
  if type(node) ~= "table" then return nil end
  if type(node.type) == "string" and node.projectile ~= nil then
    return node
  end
  for _, act in ipairs(as_array(node.action)) do
    local r = find_projectile_delivery(act)
    if r then return r end
  end
  for _, del in ipairs(as_array(node.action_delivery)) do
    local r = find_projectile_delivery(del)
    if r then return r end
  end
  for _, eff in ipairs(as_array(node.target_effects)) do
    if eff.type == "nested-result" then
      local r = find_projectile_delivery(eff)
      if r then return r end
    end
  end
  for _, eff in ipairs(as_array(node.source_effects)) do
    if eff.type == "nested-result" then
      local r = find_projectile_delivery(eff)
      if r then return r end
    end
  end
  return nil
end

-- Helper: recursively find the first "area" TriggerItem (where repeat_count
-- lives in Factorio 2.0+ shotgun shells).
local function find_area_action(node)
  if type(node) ~= "table" then return nil end
  if type(node.type) == "string" and node.type == "area" then
    return node
  end
  for _, act in ipairs(as_array(node.action)) do
    local r = find_area_action(act)
    if r then return r end
  end
  for _, del in ipairs(as_array(node.action_delivery)) do
    local r = find_area_action(del)
    if r then return r end
  end
  for _, eff in ipairs(as_array(node.target_effects)) do
    if eff.type == "nested-result" then
      local r = find_area_action(eff)
      if r then return r end
    end
  end
  for _, eff in ipairs(as_array(node.source_effects)) do
    if eff.type == "nested-result" then
      local r = find_area_action(eff)
      if r then return r end
    end
  end
  return nil
end

weaponTypes["shotgun-shell-birdshot"]= {
  type = "projectile",
  ignore = not settings.startup["enable-shotgun-bird"].value,
  size = 1,
  baseName = "shotgun-shell-birdshot",
  baseOrder = "b[shotgun]-f",
  base_item = "piercing-shotgun-shell",
  icon = "__base__/graphics/icons/piercing-shotgun-shell.png",
  energy_required = 0.5,
  warhead_count = 20*10,
  collide_anyway = true,
  appearance_fallbacks = {"shotgun-shell", "shotgun-shell-slug", "shotgun-shell-buckshot"},
  icons = {},
  lights = {},
  image_base_shift = {4, 2},
  image_warhead_shift = {-8, -8},
  ammo_category = "bullet",
  item = table.deepcopy(data.raw.ammo["piercing-shotgun-shell"]),
  projectile = table.deepcopy(data.raw.projectile["piercing-shotgun-pellet"]),
}
-- In Factorio 1.1 the piercing-shotgun-shell had two actions in its ammo_type:
--   action[1] = gunshot visual (instant), action[2] = pellet-firing (projectile).
-- In Factorio 2.0+ there is only one action, and the projectile delivery is
-- nested inside target_effects -> nested-result -> area -> action_delivery.
-- The birdshot weaponType replaces the entire action_delivery with a flat
-- projectile delivery so the warhead system can substitute the projectile.
-- We need to find the right action index to modify.
local birdshot_item = weaponTypes["shotgun-shell-birdshot"].item
local birdshot_actions = as_array(birdshot_item.ammo_type.action)
local shotgunActionIndex = nil
for i, act in ipairs(birdshot_actions) do
  -- Prefer the action whose action_delivery (or nested delivery) has a projectile.
  if find_projectile_delivery(act) or find_area_action(act) then
    shotgunActionIndex = i
    break
  end
end
-- Fallback to index 1 if nothing matched.
if not shotgunActionIndex then
  shotgunActionIndex = 1
end
-- Set the repeat_count on the area action (Factorio 2.0+ nests it there).
do
  local area_act = find_area_action(birdshot_actions[shotgunActionIndex])
  if area_act then
    area_act.repeat_count = 20
  elseif birdshot_actions[shotgunActionIndex] then
    birdshot_actions[shotgunActionIndex].repeat_count = 20
  end
end
-- Replace the action_delivery with a flat projectile delivery so the
-- warhead action_creator can find and substitute the projectile.
birdshot_actions[shotgunActionIndex].action_delivery = {
  type = "projectile",
  projectile = "piercing-shotgun-pellet",
  starting_speed = 1,
  starting_speed_deviation = 0.3,
  direction_deviation = 0.4,
  range_deviation = 0.5,
  max_range = 12
}

weaponTypes["shotgun-shell-buckshot"]= {
  type = "projectile",
  size = 4,
  ignore = not settings.startup["enable-shotgun-buck"].value,
  baseName = "shotgun-shell-buckshot",
  baseOrder = "b[shotgun]-e",
  base_item = "piercing-shotgun-shell",
  icon = "__base__/graphics/icons/piercing-shotgun-shell.png",
  energy_required = 0.5,
  warhead_count = 6*10,
  collide_anyway = true,
  appearance_fallbacks = {"shotgun-shell", "shotgun-shell-slug", "shotgun-shell-birdshot"},
  icons = {},
  lights = {},
  image_base_shift = {4, 2},
  image_warhead_shift = {-8, -8},
  ammo_category = "bullet",
  item = table.deepcopy(data.raw.ammo["piercing-shotgun-shell"]),
  projectile = table.deepcopy(data.raw.projectile["piercing-shotgun-pellet"]),
}
-- Set repeat_count on the area action (or the outer action as fallback).
do
  local buckshot_actions = as_array(weaponTypes["shotgun-shell-buckshot"].item.ammo_type.action)
  local area_act = find_area_action(buckshot_actions[shotgunActionIndex] or buckshot_actions[1])
  if area_act then
    area_act.repeat_count = 6
  elseif buckshot_actions[shotgunActionIndex or 1] then
    buckshot_actions[shotgunActionIndex or 1].repeat_count = 6
  end
end

weaponTypes["shotgun-shell-slug"]= {
  type = "projectile",
  size = 14,
  ignore = not settings.startup["enable-shotgun-slug"].value,
  baseName = "shotgun-shell-slug",
  baseOrder = "b[shotgun]-d",
  base_item = "piercing-shotgun-shell",
  icon = "__base__/graphics/icons/piercing-shotgun-shell.png",
  energy_required = 0.5,
  warhead_count = 10,
  collide_anyway = true,
  appearance_fallbacks = {"shotgun-shell", "shotgun-shell-buckshot", "shotgun-shell-birdshot"},
  icons = {},
  lights = {},
  image_base_shift = {4, 2},
  image_warhead_shift = {-8, -8},
  ammo_category = "bullet",
  item = table.deepcopy(data.raw.ammo["piercing-shotgun-shell"]),
  projectile = table.deepcopy(data.raw.projectile["piercing-shotgun-pellet"]),
}
-- Set repeat_count = 1 and direction_deviation = 0 on the slug.
do
  local slug_item = weaponTypes["shotgun-shell-slug"].item
  local slug_actions = as_array(slug_item.ammo_type.action)
  local target_action = slug_actions[shotgunActionIndex] or slug_actions[1]
  if target_action then
    local area_act = find_area_action(target_action)
    if area_act then
      area_act.repeat_count = 1
    else
      target_action.repeat_count = 1
    end
    -- Set direction_deviation = 0 on the projectile delivery (which may be
    -- nested inside the area action's action_delivery, or directly on the
    -- outer action_delivery).
    local proj_del = find_projectile_delivery(target_action)
    if proj_del then
      proj_del.direction_deviation = 0
    elseif target_action.action_delivery and type(target_action.action_delivery) == "table" then
      if target_action.action_delivery.type then
        target_action.action_delivery.direction_deviation = 0
      elseif target_action.action_delivery[1] then
        target_action.action_delivery[1].direction_deviation = 0
      end
    end
  end
end

weaponTypes["shotgun-shell"]= { -- DO NOT USE, ONLY HERE AS FALLBACK...
  type = "projectile",
  ignore = true,
  size = 3,
  baseName = "shotgun-shell",
  baseOrder = "b[shotgun]-d",
  base_item = "piercing-shotgun-shell",
  icon = "__base__/graphics/icons/piercing-shotgun-shell.png",
  energy_required = 0.5,
  warhead_count = 10,
  collide_anyway = true,
  appearance_fallbacks = {"shotgun-shell-slug", "shotgun-shell-buckshot", "shotgun-shell-birdshot"},
  icons = {},
  lights = {},
  image_base_shift = {4, 2},
  image_warhead_shift = {-8, -8},
  ammo_category = "bullet",
  item = table.deepcopy(data.raw.ammo["piercing-shotgun-shell"]),
  projectile = table.deepcopy(data.raw.projectile["piercing-shotgun-pellet"]),
}


weaponTypes["rounds-magazine"]= {
  type = "bullet",
  size = "tiny",
  ignore = not settings.startup["enable-magazine"].value,
  baseName = "rounds-magazine",
  baseOrder = "a[basic-clips]-d",
  base_item = "piercing-rounds-magazine",
  icon = "__base__/graphics/icons/piercing-rounds-magazine.png",
  energy_required = 0.5,
  icons = {},
  lights = {},
  image_base_shift = {4, 2},
  image_warhead_shift = {-8, -8},
  ammo_category = "bullet",
  item = table.deepcopy(data.raw.ammo["piercing-rounds-magazine"]),
}

if data.raw.projectile["p-r-bullet"] then
  weaponTypes["rounds-magazine"].type = "projectile"
  weaponTypes["rounds-magazine"].ammo_category = "projectile"
  weaponTypes["rounds-magazine"].projectile = table.deepcopy(data.raw.projectile["p-r-bullet"])
elseif data.raw.projectile["piercing-rounds-bullet"] then
  weaponTypes["rounds-magazine"].type = "projectile"
  weaponTypes["rounds-magazine"].ammo_category = "projectile"
  weaponTypes["rounds-magazine"].projectile = table.deepcopy(data.raw.projectile["piercing-rounds-bullet"])
elseif data.raw.projectile["piercing-bullet"] then
  weaponTypes["rounds-magazine"].type = "projectile"
  weaponTypes["rounds-magazine"].ammo_category = "projectile"
  weaponTypes["rounds-magazine"].projectile = table.deepcopy(data.raw.projectile["piercing-bullet"])
end

weaponTypes["cannon-shell"]= {
  type = "projectile",
  size = "small",
  ignore = not settings.startup["enable-cannon-shell"].value,
  baseName = "cannon-shell",
  baseOrder = "d[explosive-cannon-shell]-cz",
  base_item = "cannon-shell",
  icon = "__base__/graphics/icons/cannon-shell.png",
  energy_required = 1,
  icons = {},
  lights = {},
  range_modifier = 3,
  image_base_shift = {-4, 0},
  ammo_category = "bullet",
  item = table.deepcopy(data.raw.ammo["cannon-shell"]),
  projectile = table.deepcopy(data.raw.projectile["cannon-projectile"]),
}
weaponTypes["rocket"]= {-- DO NOT USE, ONLY HERE AS FALLBACK...
  type = "projectile",
  ignore = true,
  size = "small",
  baseName = "small-rocket",
  baseOrder = "d[rocket-launcher]-c",
  base_item = "rocket",
  icon = "__base__/graphics/icons/rocket.png",
  energy_required = 1,
  appearance_fallbacks = {"small-rocket", "big-rocket"},
  icons = {},
  lights = {},
  image_base_shift = {-4, 0},
  ammo_category = "rocket",
  item = table.deepcopy(data.raw.ammo["rocket"]),
  projectile = table.deepcopy(data.raw.projectile["rocket"]),
}

weaponTypes["small-rocket"]= {
  type = "projectile",
  size = "small",
  ignore = not settings.startup["enable-small-rocket"].value,
  baseName = "small-rocket",
  baseOrder = "d[rocket-launcher]-c",
  base_item = "rocket",
  icon = "__base__/graphics/icons/rocket.png",
  energy_required = 1,
  appearance_fallbacks = {"big-rocket", "rocket"},
  icons = {},
  lights = {},
  image_base_shift = {-4, 0},
  ammo_category = "rocket",
  item = table.deepcopy(data.raw.ammo["rocket"]),
  projectile = table.deepcopy(data.raw.projectile["rocket"]),
}
weaponTypes["big-rocket"]= {
  type = "projectile",
  size = "medium",
  ignore = not settings.startup["enable-big-rocket"].value,
  min_size = "tiny",
  baseName = "big-rocket",
  baseOrder = "d[rocket-launcher]-d",
  base_item = "rocket",
  icon = "__base__/graphics/icons/rocket.png",
  extra_ingredients = {{"processing-unit", 5}, {"rocket-fuel", 10}},
  energy_required = 12,
  range_modifier = 3,
  cooldown_modifier = 10,
  appearance_fallbacks = {"small-rocket", "rocket"},
  icons = {},
  lights = {},
  image_base_shift = {-4, 0},
  ammo_category = "rocket",
  item = table.deepcopy(data.raw.ammo["rocket"]),
  projectile = table.deepcopy(data.raw.projectile["rocket"]),
}
weaponTypes["artillery-shell"]= {
  type = "artillery",
  max_size = "large",
  min_size = "small",
  ignore = not settings.startup["enable-artillery-shell"].value,
  baseName = "artillery-shell",
  base_item = "artillery-shell",
  icon = "__base__/graphics/icons/artillery-shell.png",
  energy_required = 2,
  icons = {},
  lights = {},
  image_base_shift = {4, 2},
  image_warhead_shift = {-8, -8},
  ammo_category = "artillery-shell",
  item = table.deepcopy(data.raw.ammo["artillery-shell"]),
  projectile = table.deepcopy(data.raw["artillery-projectile"]["artillery-projectile"]),
}
weaponTypes["land-mine"]= {
  type = "land-mine",
  max_size = "huge",
  min_size = "tiny",
  ignore = not settings.startup["enable-land-mine"].value,
  baseName = "land-mine",
  base_item = "land-mine",
  icon = "__base__/graphics/icons/land-mine.png",
  energy_required = 0.5,
  icons = {},
  lights = {},
  ammo_category = "landmine",
  item = table.deepcopy(data.raw.item["land-mine"]),
  landmine = table.deepcopy(data.raw["land-mine"]["land-mine"]),
}
weaponTypes["capsule"]= {
  type = "capsule",
  max_size = "medium",
  ignore = not settings.startup["enable-capsule"].value,
  baseName = "capsule",
  base_item = "grenade",
  icon = "__base__/graphics/icons/grenade.png",
  energy_required = 0.5,
  icons = {},
  lights = {},
  ammo_category = "grenade",
  item = table.deepcopy(data.raw.capsule["grenade"]),
  projectile = table.deepcopy(data.raw["projectile"]["grenade"]),
}

weaponTypes["warhead-util-projectile"]= {
  type = "artillery",
  baseName = "warhead-util-projectile",
  base_item = "infinity-chest",
  icon = "__base__/graphics/icons/infinity-chest.png",
  energy_required = 3000,
  item = table.deepcopy(data.raw.ammo["artillery-shell"]),
  projectile = table.deepcopy(data.raw["artillery-projectile"]["artillery-projectile"]),
  image_base_shift = {4, 2},
  image_warhead_shift = {-8, -8},
  projectile_acceleration = 1,
  ammo_category = "artillery-shell"
}
weaponNoTech["warhead-util-projectile"] = true
