
-- LuaTools需要PROJECT和VERSION这两个信息
PROJECT = "iotclouddemo"
VERSION = "1.0.0"

-- sys库是标配
_G.sys = require("sys")
--[[特别注意, 使用mqtt库需要下列语句]]
_G.sysplus = require("sysplus")

local iotcloud = require("iotcloud")

-- 统一联网函数
sys.taskInit(function()
    local device_id = mcu.unique_id():toHex()
    if mobile then
        -- LED = gpio.setup(27, 0, gpio.PULLUP)
        device_id = mobile.imei()
    end
    -- 默认都等到联网成功
    sys.waitUntil("IP_READY")
    sys.publish("net_ready", device_id)
end)

sys.taskInit(function()
    -- 等待联网
    local ret, device_id = sys.waitUntil("net_ready")

    -- -- 华为云
    -- -- 动态注册(免预注册)
    -- iotcloudc = iotcloud.new(iotcloud.HUAWEI,{produt_id = "670c7b2dfc8d5a4ea71c6a79",
    --                                             project_id = "c086a58ebd714bfcb1a0fea2f0edde36",
    --                                             endpoint = "9098a2ff3c.st1",
    --                                             iam_username="hao",
    --                                             iam_password="Wsh1322764769",
    --                                             iam_domain="hao15738882476"})
    -- 密钥校验 (预注册)
    iotcloudc = iotcloud.new(iotcloud.HUAWEI,{produt_id = "670c7b2dfc8d5a4ea71c6a79",endpoint = "5341624af8.st1",device_name = "869329069169988",device_secret = "XXX"})

    if iotcloudc then
        iotcloudc:connect()
    end
end)

sys.subscribe("iotcloud", function(cloudc,event,data,payload)
    -- 注意，此处不是协程内，复杂操作发消息给协程内进行处理
    if event == iotcloud.CONNECT then -- 云平台联上了
        print("iotcloud","CONNECT", "云平台连接成功")
        -- iotcloudc:subscribe("/huawei/down/869329069169988") -- 可以自由定阅主题等
        -- iotcloudc:subscribe("$oc/devices/869329069169988/user/869329069169988")
    elseif event == iotcloud.RECEIVE then
        print("iotcloud","topic", data, "payload", payload)
        -- local test_value = json.decode(payload).content.switch
        -- print("test value:", test_value)

        -- if test_value == 1 then
        --     LED(1)
        -- elseif test_value == 0 then
        --     LED(0)
        -- end
        -- 用户处理代码
    elseif event ==  iotcloud.OTA then
        if data then
            rtos.reboot()
        end
    elseif event == iotcloud.DISCONNECT then -- 云平台断开了
        -- 用户处理代码
        print("iotcloud","DISCONNECT", "云平台连接断开")
    end
end)

-- -- 每隔2秒发布一次qos为1的消息到云平台
-- sys.taskInit(function()
--     while 1 do
--         sys.wait(2000)
--         if iotcloudc then
--             iotcloudc:publish("$oc/devices/869329069169988/user/869329069169988", "hello world!", 1) -- 上传数据
--         end
--     end
-- end)




-- 用户代码已结束---------------------------------------------
-- 结尾总是这一句
sys.run()
-- sys.run()之后后面不要加任何语句!!!!!
