-- LuaTools需要PROJECT和VERSION这两个信息
PROJECT = "project"
VERSION = "100.000.001"

PRODUCT_KEY = "ay35N95Ww6ZhSExga9MeQTr7L3VHNNhR"-- 到 iot.openluat.com 创建项目,获取正确的项目key(刚刚剪切板里的校验码就填这里)

log.info("main", PROJECT, VERSION)

-- sys库是标配
_G.sys = require("sys")
--[[特别注意, 使用mqtt库需要下列语句]]
_G.sysplus = require("sysplus")

-- 引入libfota2模块
libfota2 = require "libfota2"
-- 引入light模块
local light = require("light")
-- 引入ds18b20模块
local ds18b20 = require("ds18b20")
-- 引入hc_sr501模块
local hc_sr501 = require("hc_sr501")
-- 引入mqtt模块
local mqtt_single = require("mqtt_single")
-- 引入dht11模块
local dht11 = require("dht11")
-- 引入mq2模块
local mq2 = require("mq2")
-- 设置IO电平为3.3V
-- pm.ioVol(3, 3300)  -- 参数1为3表示设置VDD_EXT电压，参数2为3300表示设置为3.3V (单位: mV)
pm.ioVol(pm.IOVOL_ALL_GPIO, 3300)--所有IO电平开到3V，适配camera等多种外设

-- 温湿度全局变量
_G.DHT11_TEMP = 0  -- 温度全局变量
_G.DHT11_HUMI = 0  -- 湿度全局变量

--添加硬狗防止程序卡死，如果任务执行时间过长或者阻塞，会导致喂狗超时
if wdt then
    wdt.init(9000)--初始化watchdog设置为9s
    sys.timerLoopStart(wdt.feed, 3000)--3s喂一次狗
end
-- 以上是标配---------------------------------------------

-- 初始化各模块
log.info("main", "初始化传感器模块")

-- 继电器初始化
sys.taskInit(function()
    sys.wait(100)  -- 等待100ms，避免与其他初始化冲突
    -- 初始化继电器并设置为安全状态
    light.relaySet(false, 30)  -- 继电器1初始关闭
    light.relaySet(false, 31)  -- 继电器2初始关闭
    light.relaySet(false, 32)  -- 电机初始关闭
    log.info("main", "继电器初始化完成")
end)

-- PWM初始化
sys.taskInit(function()
    sys.wait(200)  -- 等待200ms，避免与其他初始化冲突
    -- 初始化PWM0和PWM1，设置初始占空比为0
    light.pwmOpen(0, 0)  -- PWM0初始关闭
    light.pwmOpen(1, 0)  -- PWM1初始关闭
    light.pwmOpen(2, 0)  -- PWM2初始关闭
    log.info("main", "PWM初始化完成")
end)

-- 创建任务：DS18B20温度监测
-- sys.taskInit(function()
--     -- 延迟1秒启动，避免与其他任务初始化冲突
--     sys.wait(1000)
--     log.info("main", "启动DS18B20温度监测任务")
--     if onewire then
--         ds18b20.test_ds18b20()  -- 这个函数内部已有循环，不需要外部再包一层
--     else
--         log.info("no onewire")
--     end
-- end)

-- 创建任务：DHT11湿度监测
-- sys.taskInit(function()
--     -- 延迟1.5秒启动，避免与其他任务初始化冲突
--     sys.wait(1500)
--     log.info("main", "启动DHT11湿度监测任务")
    
--     -- 初始化DHT11
--     if not dht11.init() then
--         log.error("main", "DHT11初始化失败")
--         return
--     end
    
--     -- 开始周期性读取湿度数据
--     while true do
--         -- 读取DHT11数据（不使用CRC校验以提高成功率）
--         local humidity, temperature = dht11.read()
        
--         if humidity then
--             log.info("main", "DHT11湿度读取成功", "湿度:", humidity, "%")
--             -- 只更新湿度全局变量
--             _G.DHT11_HUMI = humidity
--         else
--             log.warn("main", "DHT11湿度读取失败")
--             -- 读取失败时尝试重新初始化
--             dht11.init()
--         end
        
--         -- 等待10秒再次读取，与MQTT发送间隔保持一致
--         sys.wait(10000)
--     end
-- end)

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

-- 创建任务：MQ2气体检测
sys.taskInit(function()
    -- 延迟2.5秒启动，避免与其他任务初始化冲突
    sys.wait(2500)
    log.info("main", "启动MQ2气体检测任务")
    
    -- 初始化MQ2传感器
    if not mq2.init() then
        log.error("main", "MQ2传感器初始化失败")
        return
    end
    
    -- 传感器预热
    log.info("main", "MQ2传感器预热中...")
    sys.wait(30000)  -- 预热30秒，确保稳定工作
    log.info("main", "MQ2传感器预热完成")
    
    -- 开始气体浓度周期性监测
    while true do
        -- 读取气体浓度(取3次平均值)
        local gas_value = mq2.readAverage(3)
        
        if gas_value then
            -- 气体浓度估算
            local gas_ppm = mq2.convertToPPM(gas_value)
            local alert_status = mq2.isAlert()
            
            -- 日志记录
            if alert_status then
                log.warn("main", "气体浓度异常", gas_value, "mV", "约", gas_ppm, "PPM")
            else
                log.info("main", "气体浓度正常", gas_value, "mV", "约", gas_ppm, "PPM")
            end
            
            -- 这里可以添加报警处理逻辑
            if alert_status then
                -- 例如: 触发蜂鸣器报警
                -- buzzer.beep(3)
                
                -- 例如: 控制排气扇
                -- light.relaySet(true, 30)  -- 打开继电器控制排气扇
            end
        else
            log.error("main", "MQ2读取失败，尝试重新初始化")
            -- 读取失败时尝试重新初始化
            mq2.init()
        end
        
        -- 等待一段时间再次检测
        sys.wait(5000)  -- 5秒检测一次
    end
end)

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
    log.info("main", "版本号:", VERSION)
end, 3000)



-- 获取升级结果的函数
-- 升级结果的回调函数
-- 功能:获取fota的回调函数
-- 参数:
-- result:number类型
--   0表示成功
--   1表示连接失败
--   2表示url错误
--   3表示服务器断开
--   4表示接收报文错误
--   5表示使用iot平台VERSION需要使用 xxx.yyy.zzz形式
local function fota_cb(ret)
    log.info("fota", ret)
    if ret == 0 then
        log.info("升级包下载成功,重启模块")
        rtos.reboot()
    elseif ret == 1 then
        log.info("连接失败", "请检查url拼写或服务器配置(是否为内网)")
    elseif ret == 2 then
        log.info("url错误", "检查url拼写")
    elseif ret == 3 then
        log.info("服务器断开", "检查服务器白名单配置")
    elseif ret == 4 then
        log.info("接收报文错误", "检查模块固件或升级包内文件是否正常")
    elseif ret == 5 then
        log.info("版本号书写错误", "iot平台版本号需要使用xxx.yyy.zzz形式")
    else
        log.info("不是上面几种情况 ret为",ret)
    end
end

-- 自动更新 此代码演示为四小时检查一次 可更改时间
-- sys.timerLoopStart(libfota2.request, 4 * 3600000, fota_cb, ota_opts)
-- sys.timerLoopStart(libfota2.request, 60000, fota_cb, ota_opts)
-- 用户代码已结束---------------------------------------------
-- 结尾总是这一句
sys.run()
-- sys.run()之后后面不要加任何语句!!!!!

