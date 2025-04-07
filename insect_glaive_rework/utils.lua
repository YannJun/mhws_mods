local sdk = sdk
local Core = require("_CatLib")
local PlayerModule = require("_CatLib.game.player")

-- app.Wp10_Export.table_3f4222d1_c481_e0e3_e609_0075af231a13 地面翻滚
-- app.Wp10_Export.table_3b395e28_343a_4dee_3e4c_96c73ab6e836 上捞？
-- app.Wp10_Export.table_408e9d28_58f6_e73a_1dd1_1614a6f59514 空中回避
-- app.Wp10_Export.table_20641528_9e20_1435_0ec8_55a0c62400fc 电风扇？
-- app.Wp10_Export.table_20641528_9e20_1435_0ec8_55a0c62400fc 空中攻击
-- app.Wp10_Export.table_cacd937e_a1aa_29a5_81ff_58ba90f7517e 地面移动
-- app.Wp10_Export.table_4758b18f_b61f_1bed_3ad1_d66e7e746883 地面（拔刀）待机？跟下面什么区别？
-- app.Wp10_Export.table_0b363fec_3adf_834f_5deb_724dfe5053ee 地面待机
-- app.Wp10_Export.table_dca14e16_fa0d_4740_b396_0a7b7bb32b81 always
-- app.Wp10_Export.table_4b8f3f5b_545a_5227_1459_201866ba4cc2 地面移动transition到地面待机
-- app.Wp10_Export.table_3f4222d1_c481_e0e3_e609_0075af231a13 地面翻滚 前滚?
-- app.Wp10_Export.table_6e213f5c_2219_ddb6_e948_0eb86da86f62 地面翻滚 左滚?
-- app.Wp10_Export.table_3b395e28_343a_4dee_3e4c_96c73ab6e836 地面翻滚 右滚?
-- app.Wp10_Export.table_1eeaff6f_1a38_4a4f_b185_1ebfcbfa5515 地面翻滚 后滚?
-- app.Wp10_Export.table_3f4222d1_c481_e0e3_e609_0075af231a13 地面翻滚transition到继续移动?

-- app.Wp10_Export.table_89935cf4_70c4_9247_e539_05c62677527a 蓄力攻击
-- app.Wp10_Export.table_1b083206_ef21_5712_8dcc_3c7089611271 急袭突刺地面段

-- app.Wp10_Export.table_fdc831e9_0152_308f_acd9_64514e5c9253 起跳+空中状态?
local _M = {}

---@class Signal
---@field task_func fun (...)
---@field args any[]

---@class SignalQueue @发送到主线程执行的任务
local SignalQueue = {}
SignalQueue.__index = SignalQueue

function SignalQueue:new()
    local instance = setmetatable({}, SignalQueue)
    return instance
end

function SignalQueue:push(task_func, ...)
    table.insert(self, {
        task_func = task_func,
        args = {...}
    })
end

---@return Signal
function SignalQueue:pop()
    return table.remove(self, 1)
end

function SignalQueue:is_empty()
    return #self == 0
end

function SignalQueue:empty_queue()
    while not self:is_empty() do
        self:pop()
    end
end

---@return integer
function SignalQueue:size()
    return #self
end

_M.SignalQueue = SignalQueue

function _M.deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[_M.deepcopy(orig_key)] = _M.deepcopy(orig_value)
        end
        setmetatable(copy, _M.deepcopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- function deepcopy(orig)
--     local orig_type = type(orig)
--     local copy
--     if orig_type == 'table' then
--         copy = {}
--         for key, value in pairs(orig) do
--             copy[key] = deepcopy(value)
--         end
--     else
--         copy = orig -- Copy primitive values directly
--     end
--     return copy
-- end

---timer function to fine tune animations that don't have sufficient seperation in their motion/action IDs
function _M.delta_time()
	local elapsedSecond = sdk.find_type_definition("via.Application"):get_method("get_ElapsedSecond")
	
	return elapsedSecond:call(nil)
end

local function calcLeftVector(quat)
    local rightVec = Vector3f.new(0, 0, 0)
 
    rightVec.x = 1 - 2 * (quat.y * quat.y + quat.z * quat.z)
    rightVec.y = 2 * (quat.x * quat.y + quat.w * quat.z)
    rightVec.z = 2 * (quat.x * quat.z - quat.w * quat.y)
 
    return rightVec
end

---vector math by Witchmo im fr too dum for this
local function calcForwardVector(quat)
    local forwardVec = Vector3f.new(0, 0, 0)
    
    forwardVec.x = 2 * (quat.x * quat.z + quat.w * quat.y)
    forwardVec.y = 2 * (quat.y * quat.z - quat.w * quat.x)
    forwardVec.z = 1 - 2 * (quat.x * quat.x + quat.y * quat.y)

    return forwardVec
end

function _M.GetPadManager()
    return SDK.GetSingleton("ace.PadManager"):get_MainPad()
end

function _M.GetSoundContainer()
    return SDK.GetSingleton("soundlib.SoundContainer")
end

---apply motion to player character; by Witchmo as well :>
function _M.increase_movement_distance(playerObject, moveCoefficient, direction)
	local rotation = playerObject:call("get_Rot")
	local moveVec = direction == "left" and calcLeftVector(rotation) or calcForwardVector(rotation)
		
	moveVec.x = moveVec.x * moveCoefficient * _M.delta_time()
	moveVec.z = moveVec.z * moveCoefficient * _M.delta_time()
		
	local position = playerObject:call("get_Pos")
	position.x = position.x + moveVec.x
	position.z = position.z + moveVec.z
		
	playerObject:call("set_Pos", Vector3f.new(position.x, position.y, position.z))
end


function _M.generate_enum(typename)
    local t = sdk.find_type_definition(typename)
    if not t then return {} end

    local fields = t:get_fields()
    local enum = {}

    for i, field in ipairs(fields) do
        if field:is_static() then
            local name = field:get_name()
            local raw_value = field:get_data(nil)

            -- log.info(name .. " = " .. tostring(raw_value))
            print(name .. " = " .. tostring(raw_value))

            enum[name] = raw_value
        end
    end

    return enum
end

function _M.print_object(object)
	if not object then return end
    local typeDef = object:get_type_definition()
    if typeDef then
        local fields = typeDef:get_fields()
        for _, field in ipairs(fields) do
        if pcall(function() return field:get_name() end) then
            print("Field Name: " .. field:get_name())
            print("Field Type: " .. tostring(field:get_type()))
        else
            print("Skipping field: Unable to retrieve name or type.")
        end
        end

        local methods = typeDef:get_methods()
        for _, method in ipairs(methods) do
        if pcall(function() return method:get_name() end) then
            print("Method Name: " .. method:get_name())
            -- print("Method Signature: " .. tostring(method:get_signature()))
        else
            print("Skipping method: Unable to retrieve name or signature.")
        end
        end
    else
        print("Error: 'object:get_type_definition()' returned nil.")
    end
end

-- Trigger sound
local ManualTriggerFn = Core.TypeMethod("soundlib.SoundContainer", "trigger(System.UInt32)")
-- ManualTriggerFn:call(raw_call_params[1], raw_call_params[2])



-- -- Notes below

-- -- 共斗出粉尘
-- function kinsectCoopAttackDust(args)
--     if not gameConfig.coopDust then return end;
--     local managed = sdk.to_managed_object(args[2]);
--     if not managed._Wp10:get_Hunter():get_IsMaster() then return end;

--     local hitInfo = sdk.to_managed_object(args[3]);
--     if not managed then return end;

--     if math.random(1, 100) <= 15 then
--         managed._Wp10:createDust(managed:get_DustType(), hitInfo:get_Position(), hitInfo:getNearJoint():get_Rotation())
--     end

--     return sdk.PreHookResult.CALL_ORIGINAL
-- end
-- sdk.hook(sdk.find_type_definition("app.Wp10Insect"):get_method("evAttackPostProcess(app.HitInfo)"), kinsectCoopAttackDust,
-- nil);

-- -- Hook directly to changeActionRequest to change action without hooking the whole manage or each tick
-- sdk.hook(
-- sdk.find_type_definition("app.HunterCharacter"):get_method(
-- "changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)"), modifyR2DescendingThrust, nil);

-- localPlayer = sdk.get_managed_singleton("app.PlayerManager"):getMasterPlayer():get_Character();

-- -- bool for JiXiZhan release enabler?
-- managed.IsOnceReleaseCharge = true;

-- actionParameter = managed:get_field("_ActionParam");

-- -- Charge lv damanage rate?
-- actionParameter._ChargeAttackRate = 1;

-- -- 灯buff hook
-- sdk.hook(sdk.find_type_definition("app.cHunterSkill"):get_method("checkSkillEarPlug"), preCheckRockSteadySkill,
-- 	postCheckRockSteadySkill);
-- sdk.hook(sdk.find_type_definition("app.cHunterSkill"):get_method("checkSkillWind"), preCheckRockSteadySkill,
-- postCheckRockSteadySkill);
-- sdk.hook(sdk.find_type_definition("app.cHunterSkill"):get_method("checkSkillResistQuake"), preCheckRockSteadySkill,
-- 	postCheckRockSteadySkill);


-- -- Call an action without Catlib
-- managed:call("changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)", layer, actionId, false);
-- return sdk.PreHookResult.SKIP_ORIGINAL;

return _M
