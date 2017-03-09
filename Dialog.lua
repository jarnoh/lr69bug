local LrApplication = import 'LrApplication'
local LrDialogs = import 'LrDialogs'
local LrTasks = import 'LrTasks'
local LrView = import 'LrView'
local catalog = LrApplication.activeCatalog ()
local f = LrView.osFactory()
local function applyPreset (preset) 
    LrTasks.startAsyncTask (function ()
        catalog:withWriteAccessDo ("Apply Settings", function ()
            catalog:getTargetPhoto ():applyDevelopPreset (preset)
            end, {timeout = 15})
        end)
    end
LrTasks.startAsyncTask (function ()
    local folders = LrApplication.developPresetFolders ()
    local preset1 = folders [1]:getDevelopPresets ()[1]
    local preset2 = folders [1]:getDevelopPresets ()[2]
    LrDialogs.presentModalDialog {title = "Preset Bug", contents = 
        f:column {spacing = f:control_spacing (),
            f:push_button {title = preset1:getName (), 
                action = function () applyPreset (preset1) end},
            f:push_button {title = preset2:getName (), 
                action = function () applyPreset (preset2) end}}}
    end)
