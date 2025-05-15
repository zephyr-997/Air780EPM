-- LuaTools需要PROJECT和VERSION这两个信息
PROJECT = "project"
VERSION = "1.0.0"

log.info("main", PROJECT, VERSION)

-- sys库是标配
_G.sys = require("sys")

-- 引入light模块
local light = require("light")
-- 引入ds18b20模块
local ds18b20 = require("ds18b20")
-- 引入hc_sr501模块
local hc_sr501 = require("hc_sr501")
-- 设置IO电平为3.3V
-- pm.ioVol(3, 3300)  -- 参数1为3表示设置VDD_EXT电压，参数2为3300表示设置为3.3V (单位: mV)
pm.ioVol(pm.IOVOL_ALL_GPIO, 3300)--所有IO电平开到3V，适配camera等多种外设

--添加硬狗防止程序卡死，如果任务执行时间过长或者阻塞，会导致喂狗超时
if wdt then
    wdt.init(9000)--初始化watchdog设置为9s
    sys.timerLoopStart(wdt.feed, 3000)--3s喂一次狗
end
-- 以上是标配---------------------------------------------

-- 初始化各模块
log.info("main", "初始化传感器模块")

-- 创建任务：控制灯光PWM输出
sys.taskInit(function()
    log.info("main", "启动灯光控制任务")
    light.startLightControl()  -- 这个函数内部已有循环，不需要外部再包一层
end)

-- 创建任务：DS18B20温度监测
sys.taskInit(function()
    -- 延迟1秒启动，避免与其他任务初始化冲突
    sys.wait(1000)
    log.info("main", "启动DS18B20温度监测任务")
    if onewire then
        ds18b20.test_ds18b20()  -- 这个函数内部已有循环，不需要外部再包一层
    else
        log.info("no onewire")
    end
end)

-- 创建任务：人体感应监测
sys.taskInit(function()
    -- 延迟2秒启动，避免与其他任务初始化冲突
    sys.wait(2000)
    -- 初始化人体感应器
    if hc_sr501.init() then
        log.info("main", "启动人体感应监测任务")
        hc_sr501.start()  -- 这个函数内部已有循环，不需要外部再包一层
    else
        log.error("main", "人体感应器初始化失败")
    end
end)

-- 订阅温度数据
-- sys.subscribe("TEMPERATURE_DATA", function(temp)
--     log.info("main", "收到温度数据:", temp, "℃")
--     -- 这里可以添加对温度数据的处理逻辑
-- end)

-- 发布系统启动完成消息
sys.timerStart(function()
    sys.publish("SYSTEM_READY", true)
    log.info("main", "系统启动完成")
end, 3000)

-- 用户代码已结束---------------------------------------------
-- 结尾总是这一句
sys.run()
-- sys.run()之后后面不要加任何语句!!!!!

