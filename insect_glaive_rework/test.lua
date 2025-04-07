local Core = require("_CatLib")
local PlayerModule = require("_CatLib.game.player")
local mod = Core.NewMod("Insect Glaive Rework")
local Utils = require("insect_glaive_rework.utils")
local hunter = PlayerModule.GetCharacter();


local current_action = {
    index = 0,
    category = 0,
    layer = 0,
    motion_id = 0,
}
local native_sound_container = nil
local sound_container = nil
local manual_trigger_sound = Core.TypeMethod("soundlib.SoundContainer", "trigger(System.UInt32)")

local signal_queue = Utils.SignalQueue:new()
local sound_trigger_tracker = Utils.SignalQueue:new()

local wp10Handling = PlayerModule.GetWeaponHandling()

local baton_action = {
    -- 三灯急袭斩 Confirmed
    jixizhan_full = { index = 22, category = 2, layer = 0 },
    -- 无三灯只有红灯急袭斩 Confirmed
    jixizhan = { index = 21, category = 2, layer = 0 },
    -- 下戳 C
    air_thrust = { index = 50, category = 2, layer = 0, motion_id = 189 },
    -- 下戳落地柄击 C
    air_thrust_landing_hit = { index = 52, category = 2, layer = 0, motion_id = 189 },
    -- 空中印斩 C
    air_yinzhan = { index = 32, category = 2, layer = 0 },
    -- 印斩 C
    yinzhan = { index = 31, category = 2, layer = 0, motion_id = 35 },
    -- 飞圆 C
    feiyuan_zhan = { index = 11, category = 2, layer = 0, motion_id = 257 },
    -- 强化袈裟 C
    enhanced_jiasha_zhan = { index = 6, category = 2, layer = 0, motion_id = 31 },
    -- 强化横扫 C
    enhanced_hengsao_zhan = { index = 10, category = 2, layer = 0, motion_id = 0 },
    -- 强化二连斩 C
    enhanced_erlian_zhan = { index = 7, category = 2, layer = 0, motion_id = { 262 } },
    -- 强化二连斩 C
    feishenyueru_zhan = { index = 8, category = 2, layer = 0, motion_id = { 30 } },

    -- 3灯肌无力突刺 C
    jiwuli_tuci = { index = 16, category = 2, layer = 0 },
    -- 集中模式3灯肌无力突刺 C
    focus_mode_jiwuli_tuci = { index = 18, category = 2, layer = 0 },
    -- 强化突刺 C
    enhanced_tuci = { index = 20, category = 2, layer = 0 },
    
    -- 集中模式左移动连斩 C
    focus_mode_left_yidonglianzhan = { index = 22, category = 2, layer = 0, motion_id = 275 },
    -- 左移动连斩 C
    left_yidonglianzhan = { index = 19, category = 2, layer = 0, motion_id = 275 },
    -- 集中模式右移动连斩 C
    focus_mode_right_yidonglianzhan = { index = 20, category = 2, layer = 0, motion_id = 276 },
    -- 右移动连斩 C
    right_yidonglianzhan = { index = 20, category = 2, layer = 0, motion_id = 276 },
    -- 集中模式后移动连斩 C
    focus_mode_backward_yidonglianzhan = { index = 20, category = 2, layer = 0, motion_id = 277 },
    -- 后移动连斩 C
    backward_yidonglianzhan = { index = 20, category = 2, layer = 0, motion_id = 277 },


    -- 强化上捞 TBC
    enhanced_shanglao = { index = 5, category = 2, layer = 0 },
    -- 无三灯空中跳跃突进斩（屁动力斩） C
    [10] = { index = 47, category = 2, layer = 0, motionId = 346 },
    -- 进入集中模式举棍 C
    [11] = { index = 152, category = 1, layer = 0 },
    -- 地面集中模式弱点攻击 C
    [12] = { index = 23, category = 1, layer = 0, motionId = 460 },
    -- 空中集中模式弱点攻击 C
    [13] = { index = 25, category = 1, layer = 0, motionId = 466 },
    -- 空中集中模式弱点攻击成功后虫炮 C
    [14] = { index = 26, category = 1, layer = 0, motionId = 466 },
    -- Below only for reference
    -- 无3灯肌无力突刺 C
    [4] = { index = 15, category = 2, layer = 0 },
}


local function has_red_extraction()
    return wp10Handling:get_IsRed()
end

local function is_enhanced_movement_enabled()
    return has_red_extraction()
end

local function are_action_equal(action1, action2)
    -- print("Action1: " .. tostring(action1), "Action2: " .. tostring(action2))
    return action1.index == action2.index and action1.category == action2.category and action1.layer == action2.layer
end

local function is_about_to_perform_action(action)
    return are_action_equal(current_action, action)
end

local is_performing_action = is_about_to_perform_action

local function performing_enhanced_action()
    if (
        are_action_equal(current_action, baton_action.feiyuan_zhan)
        or are_action_equal(current_action, baton_action.enhanced_hengsao_zhan)
        or are_action_equal(current_action, baton_action.enhanced_jiasha_zhan)
        or are_action_equal(current_action, baton_action.enhanced_jiasha_zhan)
        or are_action_equal(current_action, baton_action.enhanced_tuci)
        or are_action_equal(current_action, baton_action.enhanced_shanglao)
        or are_action_equal(current_action, baton_action.jixizhan_full)
        or are_action_equal(current_action, baton_action.jixizhan)
        or are_action_equal(current_action, baton_action.enhanced_erlian_zhan)

        or (
            are_action_equal(current_action, baton_action.feishenyueru_zhan)
            and is_enhanced_movement_enabled()
        )

        or are_action_equal(current_action, baton_action.air_thrust)
        or are_action_equal(current_action, baton_action.focus_mode_backward_yidonglianzhan)
        or are_action_equal(current_action, baton_action.focus_mode_left_yidonglianzhan
        or are_action_equal(current_action, baton_action.focus_mode_right_yidonglianzhan)

    )
    ) then
        return true
    else
        return false
    end
end

local cWp10BatonAttackBase = nil
sdk.hook(sdk.find_type_definition("app.Wp10Action.cWp10BatonAttackBase"):get_method("doEnter"),
    function(args)
        print("app.Wp10Action.cWp10BatonAttackBase:doEnter")

        local this = sdk.to_managed_object(args[2])
        cWp10BatonAttackBase = this

        print("Performing attack: " .. this:get_type_definition():get_full_name())
        local sent_action_in_trigger_signal = Utils.deepcopy(current_action)
        -- local sent_action_in_trigger_signal = {
        --     index = current_action.index,
        --     category = current_action.category,
        --     layer = current_action.layer,
        --     motion_id = current_action.motion_id
        -- }
        -- local sent_action_in_trigger_tracker_signal = Utils.deepcopy(current_action)
        -- if is_about_to_perform_action(baton_action.feiyuan_zhan) then
        local sent_signal_count = 10
        local cnt = 0
        if performing_enhanced_action() then
            signal_queue:empty_queue()
            while cnt <= 20 do
                signal_queue:push(manual_trigger_sound, native_sound_container, 403135317, sent_action_in_trigger_signal)
                cnt = cnt + 1
            end
            -- signal_queue:push(manual_trigger_sound, native_sound_container, 403135317, sent_action_in_signal)

            -- sound_trigger_tracker:push(manual_trigger_sound, sent_action_in_trigger_tracker_signal, false)
            sound_trigger_tracker:empty_queue()
            sound_trigger_tracker:push(manual_trigger_sound, false)

        end 
        -- local Wp10Action = sdk.get_managed_singleton("app.Wp10Action")
        -- if Wp10Action then 
        --     print("Class name of 'Wp10Action': " .. Wp10Action:get_type_definition():get_full_name())
        -- end
        -- local Wp10AttackBase = sdk.get_managed_singleton("app.Wp10Action.cWp10BatonAttackBase")
        -- print("Class name of 'Wp10AttackBase': " .. Wp10AttackBase:get_type_definition():get_full_name())
    end
, function (retval)
    -- start_attack = false
    return retval
end)

local is_wem24_triggered_for_current_action = false
mod.HookFunc("soundlib.SoundContainer", "trigger(soundlib.SoundManager.RequestInfo)", function(args)
    local request_info = sdk.to_managed_object(args[3])
    local trigger_id = request_info:get_TriggerId()
    local event_id = request_info:get_EventId()

    if not sound_container then
        sound_container = sdk.to_managed_object(args[2])
    end
    if not native_sound_container then
        native_sound_container = args[2]
    end

    if trigger_id == 3644861634 then
        print('Trigger succeeded')
        is_wem24_triggered_for_current_action = true
        print(sound_trigger_tracker:size())
        sound_trigger_tracker:pop()
    end
    
    if performing_enhanced_action()  then 
        local signal = signal_queue:pop()
        if signal then
            local action_from_signal = signal['args'][3]
            if action_from_signal then 
                print('Signal action: ' .. tostring(action_from_signal.index) .. ' ' .. tostring(action_from_signal.category) .. ' ' .. tostring(action_from_signal.layer))
                if are_action_equal(current_action, action_from_signal) then
                        -- print('Expected 1 singals, actually received: ' .. signal_queue:size())
                        --     --     -- print(signal)
                        --     --     -- local cb = signal['cb']
                        --     --     -- local args = signal['args']
                    print('Triggering sound based on signal [trigger(soundlib.SoundManager.RequestInfo)] Inner')
                    local max_attempts = 15
                    local cnt = 0
                    -- manual_trigger_sound:call(args[2], 3644861634)
                    while not is_wem24_triggered_for_current_action and not sound_trigger_tracker:is_empty() do
                        if cnt > 0 then
                            print('Previous trigger failed, retrying... (attempt #' .. tostring(cnt) .. ')')
                        end
                        manual_trigger_sound:call(args[2], 3644861634)
                        cnt = cnt + 1
                        if cnt >= max_attempts then
                            break
                        end
                    end
                end
            else
                print(' !!!!!!!!!!!!!!!!!!!!! Signal action is nil !!!!!!!!!!!!!!!!!!!!!')
            end
        end
    end
end, function (retval)
    if is_wem24_triggered_for_current_action then
        is_wem24_triggered_for_current_action = false
    end
end)
