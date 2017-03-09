--[[ 

original example code by John R Ellis from
https://feedback.photoshop.com/photoshop_family/topics/lightroom-sdk-photo-applydeveloppreset-doesnt-update-develop-display-when-gpu-enabled

modified by Jarno Heikkinen to illustrate LR6.9 ToneCurvePV2012 issue and to show LrDevelopController workaround
https://feedback.photoshop.com/photoshop_family/topics/lightroom-6-9-sdk-lrdevelopcontroller-no-longer-works-with-tonecurvepv2012-settings

]]

local LrApplicationView = import 'LrApplicationView'
local LrDevelopController = import 'LrDevelopController'
local LrApplication = import 'LrApplication'
local LrDialogs = import 'LrDialogs'
local LrTasks = import 'LrTasks'
local LrView = import 'LrView'
local catalog = LrApplication.activeCatalog ()
local f = LrView.osFactory()

-- this is LR3.0+ compatible. on LR6, it does not properly update the full window
-- if GPU is enabled.  smaller preview window is updated though.  main window gets
-- updated e.g. if you click any button, even if the button would not do anything.
local function applyPreset (preset) 
    LrTasks.startAsyncTask (function ()
        catalog:withWriteAccessDo ("Apply Settings", function ()
            catalog:getTargetPhoto ():applyDevelopPreset (preset)
		end, {timeout = 15})
	end)
end

-- this is LR6 way.  has same GPU update problem.
-- on LR6.9 this no longer sets ToneCurvePV2012/Red/Green/Blue
local function applyPreset2 (preset) 
	local settings = preset:getSetting()
	for k, v in pairs(settings) do
		LrDevelopController.setValue(k, v)
    end
end    

-- LR6 way with GPU update hack, setting Exposure value to other value
-- and changing it back seems to help with update.
-- on LR6.9 this no longer sets ToneCurvePV2012/Red/Green/Blue
local function applyPreset3 (preset) 
	LrDevelopController.setValue("Exposure2012", -5) -- HACK to force screen to update
	local settings = preset:getSetting()
	for k, v in pairs(settings) do
		LrDevelopController.setValue(k, v)
    end
end


LrApplicationView.switchToModule('develop')

LrTasks.startAsyncTask (function ()
    local folders = LrApplication.developPresetFolders ()
    
    local folder = folders[1]
    
    for _,v in ipairs(folders) do
    	if v:getName()=="Lightroom Color Presets" then -- note expects english language
    		folder=v
    		break
    	end
    end
    
    local zeroed = LrApplication.developPresetByUuid("9D8914D2-A5FF-4966-8AAD-230802B52EF4")
    local preset1 = folder:getDevelopPresets ()[1] -- Aged Photo
    local preset2 = folder:getDevelopPresets ()[2] -- Bleach Bypass (RGB curves)
    
    LrDialogs.presentModalDialog {
    	title = "Preset Bug", 
    	contents = f:column { spacing = f:control_spacing (),
    	        
			f:row {spacing = f:control_spacing (),
				f:static_text { title = "applyDevelopPreset" },
				f:push_button {title = preset1:getName (), 
					action = function () applyPreset (preset1) end},
				f:push_button {title = preset2:getName (), 
					action = function () applyPreset (preset2) end}
			},
			
			f:row {spacing = f:control_spacing (),
				f:static_text { title = "LrDevelopController" },
				f:push_button {title = preset1:getName (), 
					action = function () applyPreset2 (preset1) end},
				f:push_button {title = preset2:getName (), 
					action = function () applyPreset2 (preset2) end}
			},
		
			f:row {spacing = f:control_spacing (),
				f:static_text { title = "LrDC+workaround" },
				f:push_button {title = preset1:getName (), 
					action = function () applyPreset3 (preset1) end},
				f:push_button {title = preset2:getName (), 
					action = function () applyPreset3 (preset2) end}
			},
		
			f:row {spacing = f:control_spacing (),
				f:static_text { title = "GPU workaround" },
				f:push_button {title = "Button that does nothing", 
					action = function () 
						--...and magically the pending rendering of main window is updated if in GPU mode
					end},
			},
		}
	}
	
    end)
