-- displaywidget.lua
local Blitbuffer = require("ffi/blitbuffer")
local Date = os.date
local Datetime = require("frontend/datetime")
local Device = require("device")
local Font = require("ui/font")
local FrameContainer = require('ui/widget/container/framecontainer')
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local InputContainer = require("ui/widget/container/inputcontainer")
local NetworkMgr = require("ui/network/manager")
local Screen = Device.screen
local TextBoxWidget = require("ui/widget/textboxwidget")
local UIManager = require("ui/uimanager")
local VerticalGroup = require("ui/widget/verticalgroup")
local T = require("ffi/util").template
local _ = require("gettext")
local json = require("json")

local DisplayWidget = InputContainer:extend {
    name = "displaywidget",
    props = {}, -- 来自main.lua的配置
    json_path = "", -- 哲学名言JSON路径
    philosopher_text = "", -- 当前显示的哲学句子
    philosopher_schedule = nil, -- 刷新定时器
}

-- 安全获取JSON数据
local function getPhilosopherQuote(json_path)
    local file = io.open(json_path, "r")
    if not file then return _("No quotes found") end
    
    local content = file:read("*a")
    file:close()
    
    -- 安全解析JSON
    local ok, data = pcall(json.decode, content)
    if not ok or type(data) ~= "table" then 
        return _("Invalid quotes format") 
    end
    
    if #data == 0 then
        return _("Empty quotes library")
    end
    
    -- 随机选择条目
    math.randomseed(os.time())
    local entry = data[math.random(#data)]
    
    -- 构建显示文本
    local text = entry.hitokoto or ""
    if entry.from or entry.from_who then
        text = text .. "\n"
        if entry.from_who then
            text = text .. "—— " .. entry.from_who
        end
        if entry.from then
            text = text .. (entry.from_who and ", " or "—— ") .. entry.from
        end
    end
    return text
end

function DisplayWidget:init()
    -- 初始化时间
    self.now = os.time()
    
    -- 初始化哲学名言
    self:refreshPhilosopherText()
    
    -- 设置自动刷新（每分钟更新时间，每小时更新名言）
    self.time_schedule = function()
        self:refreshTime()
        return UIManager:scheduleIn(60 - tonumber(Date("%S")), self.time_schedule)
    end
    self.philosopher_schedule = function()
        self:refreshPhilosopherText()
        return UIManager:scheduleIn(3600, self.philosopher_schedule) -- 每小时刷新
    end
    
    -- 启动定时器
    self.time_schedule()
    self.philosopher_schedule()
    
    -- 手势设置
    self.ges_events.TapClose = {
        GestureRange:new {
            ges = "tap",
            range = Geom:new {
                x = 0, y = 0,
                w = Screen:getWidth(),
                h = Screen:getHeight(),
            }
        }
    }
    
    -- 渲染UI
    self[1] = self:render()
    UIManager:setDirty("all", "flashpartial")
end

-- 刷新哲学文本（带错误处理）
function DisplayWidget:refreshPhilosopherText()
    local ok, text = pcall(getPhilosopherQuote, self.json_path)
    self.philosopher_text = ok and text or _("Quotes update failed")
    self:update()
end

-- 刷新时间
function DisplayWidget:refreshTime()
    self.now = os.time()
    self:update()
end

-- 渲染哲学板块
function DisplayWidget:renderPhilosopherWidget()
    return TextBoxWidget:new {
        text = self.philosopher_text,
        face = Font:getFace(
            self.props.philosopher_widget.font_name,
            self.props.philosopher_widget.font_size
        ),
        width = Screen:getWidth(),
        alignment = "center",
        padding_h = 20, -- 左右边距
        max_lines = 3,  -- 最大行数
        line_height = 1.2 -- 行间距
    }
end

-- 完整渲染流程
function DisplayWidget:render()
    local screen_size = Screen:getSize()
    
    -- 创建各组件
    local time_widget = self:renderTimeWidget()
    local date_widget = self:renderDateWidget()
    local status_widget = self:renderStatusWidget()
    local philosopher_widget = self:renderPhilosopherWidget()
    
    -- 计算垂直布局
    local total_height = date_widget:getSize().h 
        + time_widget:getSize().h
        + philosopher_widget:getSize().h
        + status_widget:getSize().h
        
    local spacer_height = (screen_size.h - total_height) / 3
    
    local vertical_group = VerticalGroup:new {
        FrameContainer:new { -- 顶部留白
            height = spacer_height,
            bordersize = 0
        },
        date_widget,
        time_widget,
        philosopher_widget, -- 哲学板块
        status_widget,
        FrameContainer:new { -- 底部留白
            height = spacer_height,
            bordersize = 0
        },
    }
    
    return FrameContainer:new {
        background = Blitbuffer.COLOUR_WHITE,
        width = screen_size.w,
        height = screen_size.h,
        vertical_group
    }
end

-- 其他方法保持原有实现（update、getStatusText等）...

return DisplayWidget
