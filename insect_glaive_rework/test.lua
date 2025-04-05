local Core = require("_CatLib")
local mod = Core.NewMod("Insect Glaive Rework")

local current_action = {
    index = 0,
    category = 0,
    layer = 0,
    motion_id = 0,
}
local native_sound_container = nil
local sound_container = nil
local manual_trigger_sound = Core.TypeMethod("soundlib.SoundContainer", "trigger(System.UInt32)")
local awake_sound_container = Core.TypeMethod("soundlib.SoundContainer", "awake()")

-- Same behavior with hook on onLoad(), update(), etc. 
mod.HookFunc("soundlib.SoundContainer", "trigger(soundlib.SoundManager.RequestInfo)", function(args)
    if not sound_container then
        sound_container = sdk.to_managed_object(args[2])
    end
    if not native_sound_container then
        native_sound_container = args[2]
    end

    -- Trigger ok
    if current_action.index == 10 and current_action.category == 2 and current_action.layer == 0 then
        manual_trigger_sound:call(args[2], 3987485258)
        manual_trigger_sound:call(native_sound_container, 2385074400)
        sound_container.trigger(2385074400)

    end
end)

sdk.hook(
    sdk.find_type_definition("app.HunterCharacter"):get_method(
        "changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)"
),
    function (args)
        current_action.index = sdk.get_native_field(args[4], ActionType, "_Index")
        current_action.category = sdk.get_native_field(args[4], ActionType, "_Category")
        current_action.layer = sdk.to_int64(args[3])

        if current_action.index == 10 and current_action.category == 2 and current_action.layer == 0 then
            if sound_container and manual_trigger_sound and native_sound_container then
                -- Crash when calling awake
                -- No effect without awake
                sound_container.awake()
                sound_container.trigger(2385074400)

                awake_sound_container:call(native_sound_container)
                manual_trigger_sound:call(native_sound_container, 2385074400)
            end
        end
    end
)
