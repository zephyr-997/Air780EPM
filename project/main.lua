-- LuaTools需要PROJECT和VERSION这两个信息
PROJECT = "project"
VERSION = "100.000.000"

-- PRODUCT_KEY = "t1Hm7tc3xk9Jw4QpDd9A9dMLXD2NSdMW" -- 到 iot.openluat.com 创建项目,获取正确的项目key(刚刚剪切板里的校验码就填这里)

log.info("main", PROJECT, VERSION)

-- sys库是标配
_G.sys = require("sys")
--[[特别注意, 使用mqtt库需要下列语句]]
_G.sysplus = require("sysplus")

-- 引入light模块
local light = require("light")
-- 引入ds18b20模块
local ds18b20 = require("ds18b20")
-- 引入hc_sr501模块
local hc_sr501 = require("hc_sr501")
-- 引入mqtt模块
local mqtt_single = require("mqtt_single")
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
-- sys.taskInit(function()
--     -- 延迟2秒启动，避免与其他任务初始化冲突
--     sys.wait(2000)
--     -- 初始化人体感应器
--     if hc_sr501.init() then
--         log.info("main", "启动人体感应监测任务")
--         hc_sr501.start()  -- 这个函数内部已有循环，不需要外部再包一层
--     else
--         log.error("main", "人体感应器初始化失败")
--     end
-- end)



-- 创建任务：mqtt初始化和连接
sys.taskInit(function()
    log.info("main", "启动网络连接任务")
    mqtt_single.connect()  -- 先连接网络
    
    log.info("main", "启动mqtt初始化任务")
    mqtt_single.init()
end)

-- 分别创建MQTT发布和监控任务
sys.taskInit(function()
    -- 等待MQTT连接成功
    local ret = sys.waitUntil("mqtt_conack")
    if ret then
        log.info("main", "启动mqtt发布任务")
        mqtt_single.publish()
    else
        log.error("main", "MQTT连接失败")
    end
end)

-- 创建PWM状态定期上报任务
sys.taskInit(function()
    -- 等待MQTT连接成功
    local ret = sys.waitUntil("mqtt_conack")
    if ret then
        log.info("main", "启动PWM状态上报任务")
        mqtt_single.reportStatus()
    else
        log.error("main", "MQTT连接失败")
    end
end)

-- 打印内存信息，调试时使用
-- sys.taskInit(function()
--     -- 等待MQTT连接成功
--     local ret = sys.waitUntil("mqtt_conack")
--     if ret then
--         log.info("main", "启动mqtt内存信息任务")
--         mqtt_single.meminfo()
--     else
--         log.error("main", "MQTT连接失败")
--     end
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

