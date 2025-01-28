-- main.lua
local DisplayWidget = require("displaywidget")
local DataStorage = require("datastorage")
local Font = require("ui/font")
local FontList = require("fontlist")
local LuaSettings = require("frontend/luasettings")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local cre -- 延迟加载字体引擎
local _ = require("gettext")
local T = require("ffi/util").template
local json = require("json") -- 新增JSON解析库

-- 配置常量
local JSON_FILE_PATH = "/mnt/onboard/.adds/koreader/plugins/philosopher.koplugin/data.json" -- 哲学名言数据路径

local DtDisplay = WidgetContainer:extend {
    name = "dtdisplay",
    config_file = "dtdisplay_config.lua",
    local_storage = nil,
    is_doc_only = false,
    -- 新增哲学板块默认配置
    philosopher_defaults = {
        font_name = "./fonts/noto/NotoSans-Regular.ttf",
        font_size = 20,
        enabled = true
    }
}

-- 初始化配置存储
function DtDisplay:initLuaSettings()
    self.local_storage = LuaSettings:open(
        ("%s/%s"):format(DataStorage:getSettingsDir(), self.config_file)
    )
    
    -- 初始化默认配置（首次运行时）
    if next(self.local_storage.data) == nil then
        self.local_storage:reset({
            date_widget = {
                font_name = "./fonts/noto/NotoSans-Regular.ttf",
                font_size = 25,
            },
            time_widget = {
                font_name = "./fonts/noto/NotoSans-Regular.ttf",
                font_size = 119,
            },
            status_widget = {
                font_name = "./fonts/noto/NotoSans-Regular.ttf",
                font_size = 24,
            },
            philosopher_widget = self.philosopher_defaults -- 添加哲学板块配置
        })
        self.local_storage:flush()
    end
end

function DtDisplay:init()
    self:initLuaSettings()
    self.settings = self.local_storage.data
    self.ui.menu:registerToMainMenu(self)
end

-- 构建主菜单项
function DtDisplay:addToMainMenu(menu_items)
    menu_items.dtdisplay = {
        text = _("Time & Day"),
        sorting_hint = "more_tools",
        sub_item_table = {
            {
                text = _("Launch"),
                separator = true,
                callback = function()
                    UIManager:show(DisplayWidget:new { 
                        props = self.settings,
                        json_path = JSON_FILE_PATH -- 传递JSON路径
                    })
                end,
            },
            -- 原有日期、时间、状态行字体设置...
            -- 新增哲学板块字体设置菜单
            {
                text = _("Philosopher font"),
                sub_item_table = self:getFontMenuList({
                    font_callback = function(font_name)
                        self:setPhilosopherFont(font_name)
                    end,
                    font_size_callback = function(font_size)
                        self:setPhilosopherFontSize(font_size)
                    end,
                    font_size_func = function()
                        return self.settings.philosopher_widget.font_size
                    end,
                    checked_func = function(font)
                        return font == self.settings.philosopher_widget.font_name
                    end
                }),
            }
        },
    }
end

-- 字体菜单生成器（保持原有实现，新增哲学相关方法）
function DtDisplay:getFontMenuList(args)
    -- 原有字体菜单生成逻辑...
end

-- 新增哲学板块字体设置方法
function DtDisplay:setPhilosopherFont(font)
    self.settings.philosopher_widget.font_name = font
    self.local_storage:reset(self.settings)
    self.local_storage:flush()
    UIManager:setDirty("all", "ui")
end

function DtDisplay:setPhilosopherFontSize(font_size)
    self.settings.philosopher_widget.font_size = font_size
    self.local_storage:reset(self.settings)
    self.local_storage:flush()
    UIManager:setDirty("all", "ui")
end

return DtDisplay
