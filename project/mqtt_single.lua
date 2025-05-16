-- 自动低功耗, 轻休眠模式
-- Air780E支持uart唤醒和网络数据下发唤醒, 但需要断开USB,或者pm.power(pm.USB, false) 但这样也看不到日志了
-- pm.request(pm.LIGHT)

-- 创建mqtt模块
local mqtt_single = {}        -- 创建本地模块

--根据自己的服务器修改以下参数
local mqtt_host = "106.53.179.231"
local mqtt_port = 1883
local mqtt_isssl = false
local client_id = "AIR780EPM"
local user_name = "admin"
local password = "azsxdcfv97"

local pub_topic = "HA-AIR780EPM-01/01/state" -- .. (mcu.unique_id():toHex()) -- 后面这个是设备id
local sub_topic = "HA-AIR780EPM-02/1/set" -- .. (mcu.unique_id():toHex())
local status_topic = "HA-AIR780EPM-03/2/status" 
local command_topic = "HA-AIR780EPM-03/2/command" 
-- local topic2 = "/luatos/2"
-- local topic3 = "/luatos/3"

local mqttc = nil

-- 统一联网函数
function mqtt_single.connect()
    local device_id = mcu.unique_id():toHex()
    -----------------------------
    -- 统一联网函数, 可自行删减
    ----------------------------
    if wlan and wlan.connect then
        -- wifi 联网, ESP32系列均支持
        local ssid = "luatos1234"
        local password = "12341234"
        log.info("wifi", ssid, password)
        -- TODO 改成自动配网
        -- LED = gpio.setup(12, 0, gpio.PULLUP)
        wlan.init()
        wlan.setMode(wlan.STATION) -- 默认也是这个模式,不调用也可以
        device_id = wlan.getMac()
        wlan.connect(ssid, password, 1)
    elseif mobile then
        -- Air780E/Air600E系列
        --mobile.simid(2) -- 自动切换SIM卡
        -- LED = gpio.setup(27, 0, gpio.PULLUP)
        device_id = mobile.imei()
    elseif w5500 then
        -- w5500 以太网, 当前仅Air105支持
        w5500.init(spi.HSPI_0, 24000000, pin.PC14, pin.PC01, pin.PC00)
        w5500.config() --默认是DHCP模式
        w5500.bind(socket.ETH0)
        -- LED = gpio.setup(62, 0, gpio.PULLUP)
    elseif socket or mqtt then
        -- 适配的socket库也OK
        -- 没有其他操作, 单纯给个注释说明
    else
        -- 其他不认识的bsp, 循环提示一下吧
        while 1 do
            sys.wait(1000)
            log.info("bsp", "本bsp可能未适配网络层, 请查证")
        end
    end
    -- 默认都等到联网成功
    sys.waitUntil("IP_READY")
    sys.publish("net_ready", device_id)
end

-- 初始化mqtt连接
function mqtt_single.init()
    -- 等待联网
    local ret, device_id = sys.waitUntil("net_ready")
    -- 下面的是mqtt的参数均可自行修改
    -- client_id = device_id   -- 设备id   
    -- pub_topic = "/luatos/pub/" .. device_id  -- 上报主题
    -- sub_topic = "/luatos/sub/" .. device_id  -- 下发主题

    -- 打印一下上报(pub)和下发(sub)的topic名称
    -- 上报: 设备 ---> 服务器
    -- 下发: 设备 <--- 服务器
    -- 可使用mqtt.x等客户端进行调试
    log.info("mqtt", "pub", pub_topic)
    log.info("mqtt", "sub", sub_topic)

    -- 打印一下支持的加密套件, 通常来说, 固件已包含常见的99%的加密套件
    -- if crypto.cipher_suites then
    --     log.info("cipher", "suites", json.encode(crypto.cipher_suites()))
    -- end
    if mqtt == nil then
        while 1 do
            sys.wait(1000)
            log.info("bsp", "本bsp未适配mqtt库, 请查证")
        end
    end

    -------------------------------------
    -------- MQTT 演示代码 --------------
    -------------------------------------

    mqttc = mqtt.create(nil, mqtt_host, mqtt_port, mqtt_isssl) -- 创建mqtt客户端

    mqttc:auth(client_id,user_name,password) -- client_id必填,其余选填
    -- mqttc:keepalive(240) -- 默认值240s
    mqttc:autoreconn(true, 3000) -- 自动重连机制

    mqttc:on(function(mqtt_client, event, data, payload) -- 回调函数处理MQTT事件
        -- 用户自定义代码
        log.info("mqtt", "event", event, mqtt_client, data, payload)
        if event == "conack" then
            -- 联上了
            sys.publish("mqtt_conack")
            mqtt_client:subscribe(sub_topic)--单主题订阅
            mqtt_client:subscribe(command_topic)--订阅命令主题
            -- mqtt_client:subscribe({[topic1]=1,[topic2]=1,[topic3]=1})--多主题订阅
        elseif event == "recv" then
            log.info("mqtt", "downlink", "topic", data, "payload", payload)
            sys.publish("mqtt_payload", data, payload)
        elseif event == "sent" then
            -- log.info("mqtt", "sent", "pkgid", data)
        -- elseif event == "disconnect" then
            -- 非自动重连时,按需重启mqttc
            -- mqtt_client:connect()
        end
    end)

    -- mqttc自动处理重连, 除非自行关闭
    mqttc:connect()
	sys.waitUntil("mqtt_conack")
    while true do
        -- 演示等待其他task发送过来的上报信息
        local ret, topic, data, qos = sys.waitUntil("mqtt_pub", 300000)
        if ret then
            -- 提供关闭本while循环的途径, 不需要可以注释掉
            if topic == "close" then break end
            mqttc:publish(topic, data, qos)
        end
        -- 如果没有其他task上报, 可以写个空等待
        --sys.wait(60000000)
    end
    mqttc:close()
    mqttc = nil
end

-- 这里演示在另一个task里上报数据, 会定时上报数据,不需要就注释掉
function mqtt_single.publish()
    sys.wait(1000) 
	local data = 0
	local qos = 1 -- QOS0不带puback, QOS1是带puback的
    if not _G.DS18B20_TEMP then
        _G.DS18B20_TEMP = 0
    end
    while true do
        sys.wait(10000) -- 10s发送一次数据
        data = _G.DS18B20_TEMP -- 获取温度数据
        data = string.format("%.2f", data) -- 保留两位小数
        if mqttc and mqttc:ready() then
            -- local pkgid = mqttc:publish(pub_topic, data .. os.date(), qos) -- 带时间戳
            local pkgid = mqttc:publish(pub_topic, data, qos) -- 不带时间戳
            -- local pkgid = mqttc:publish(topic2, data, qos)
            -- local pkgid = mqttc:publish(topic3, data, qos)
            log.info("mqtt", "已发送温度数据", data, "°C")
        else
            log.info("mqtt", "mqtt未连接")
        end
    end
end


-- 打印内存信息
function mqtt_single.meminfo()
    while true do
        sys.wait(3000)
        log.info("lua", rtos.meminfo())
        log.info("sys", rtos.meminfo("sys"))
    end
end

-- 删除原有的订阅处理函数并替换为新的
sys.subscribe("mqtt_payload", function(topic, payload)
    -- 在这里处理接收到的MQTT消息
    log.info("mqtt", "收到消息", topic, payload)
    
    -- 处理新的命令主题消息
    if topic == command_topic then
        -- 尝试解析JSON格式的payload
        local success, data = pcall(json.decode, payload)
        if success and data then
            -- 获取light模块
            local light = require("light")
            local status_data = {} -- 创建状态数据表
            
            -- 处理状态命令
            if data.state then
                if data.state == "ON" then
                    -- 如果同时有亮度值，设置PWM亮度
                    if data.brightness and type(data.brightness) == "number" then
                        -- 亮度值范围已是0-100，直接使用
                        light.pwmOpen(0, data.brightness)
                        log.info("mqtt", "通过MQTT命令打开PWM，亮度为", data.brightness, "%")
                        -- 设置状态数据
                        status_data.state = "ON"
                        status_data.brightness = data.brightness
                    else
                        -- 如果只有开灯命令没有亮度，则设为100%
                        light.pwmOpen(0, 100)
                        log.info("mqtt", "通过MQTT命令打开PWM，亮度为100%")
                        -- 设置状态数据
                        status_data.state = "ON"
                        status_data.brightness = 100
                    end
                elseif data.state == "OFF" then
                    -- 获取当前亮度，保存上次的亮度值
                    local pwm_status = light.pwmGetStatus(0)
                    local saved_brightness = pwm_status.duty
                    
                    -- 使用设置占空比为0的方式代替关闭PWM
                    local close_result = light.pwmSetDuty(0, 0)
                    log.info("mqtt", "通过MQTT命令将PWM占空比设为0", close_result and "成功" or "失败")
                    
                    -- 无论设置是否成功，都设置状态数据为OFF
                    status_data.state = "OFF"
                    status_data.brightness = saved_brightness
                end
            elseif data.brightness and type(data.brightness) == "number" then
                -- 只有亮度值没有状态命令，调整占空比
                light.pwmSetDuty(0, data.brightness)
                log.info("mqtt", "仅设置PWM亮度为", data.brightness, "%")
                
                -- PWM设置亮度意味着已开启，状态为ON
                status_data.state = "ON"
                status_data.brightness = data.brightness
            end
            
            -- 发布状态消息到status_topic
            if mqttc and mqttc:ready() and next(status_data) ~= nil then
                local status_json = json.encode(status_data)
                mqttc:publish(status_topic, status_json, 1)
                log.info("mqtt", "发送状态反馈", status_json)
            end
        else
            log.warn("mqtt", "JSON解析失败", payload)
        end
    -- 检查原有的主题消息
    elseif topic == sub_topic then
        -- 尝试解析JSON格式的payload
        local success, data = pcall(json.decode, payload)
        if success and data then
            -- JSON解析成功
            local light = require("light")
            local status_data = {} -- 创建状态数据表
            
            if data.cmd == "led_on" then
                -- 打开PWM，100%亮度
                light.pwmOpen(0, 100)
                log.info("mqtt", "通过MQTT命令打开PWM，亮度为100%")
                
                -- 设置状态数据
                status_data.state = "ON"
                status_data.brightness = 100
            elseif data.cmd == "led_off" then
                -- 获取当前亮度，保存上次的亮度值
                local pwm_status = light.pwmGetStatus(0)
                local saved_brightness = pwm_status.duty
                
                -- 使用设置占空比为0的方式代替关闭PWM
                local close_result = light.pwmSetDuty(0, 0)
                log.info("mqtt", "通过MQTT命令将PWM占空比设为0", close_result and "成功" or "失败")
                
                -- 无论设置是否成功，都设置状态数据为OFF
                status_data.state = "OFF"
                status_data.brightness = saved_brightness
            elseif data.brightness and type(data.brightness) == "number" then
                -- 设置亮度，直接使用0-100范围值
                light.pwmSetDuty(0, data.brightness)
                log.info("mqtt", "设置PWM亮度为", data.brightness, "%")
                
                -- 设置状态数据
                status_data.state = "ON"
                status_data.brightness = data.brightness
            end
            
            -- 发送状态反馈
            if mqttc and mqttc:ready() and next(status_data) ~= nil then
                local status_json = json.encode(status_data)
                mqttc:publish(status_topic, status_json, 1)
                log.info("mqtt", "发送状态反馈", status_json)
            end
        else
            -- 非JSON格式，尝试直接匹配内容
            local light = require("light")
            local status_data = {} -- 创建状态数据表
            
            if payload == "ON" then
                light.pwmOpen(0, 100)
                log.info("mqtt", "通过MQTT命令打开PWM，亮度为100%")
                
                -- 设置状态数据
                status_data.state = "ON"
                status_data.brightness = 100
            elseif payload == "OFF" then
                -- 获取当前亮度，保存上次的亮度值
                local pwm_status = light.pwmGetStatus(0)
                local saved_brightness = pwm_status.duty
                
                -- 使用设置占空比为0的方式代替关闭PWM
                local close_result = light.pwmSetDuty(0, 0)
                log.info("mqtt", "通过MQTT命令将PWM占空比设为0", close_result and "成功" or "失败")
                
                -- 无论设置是否成功，都设置状态数据为OFF
                status_data.state = "OFF"
                status_data.brightness = saved_brightness
            end
            
            -- 发送状态反馈
            if mqttc and mqttc:ready() and next(status_data) ~= nil then
                local status_json = json.encode(status_data)
                mqttc:publish(status_topic, status_json, 1)
                log.info("mqtt", "发送状态反馈", status_json)
            end
        end
    end
end)

-- 添加一个状态主动上报函数
function mqtt_single.reportStatus()
    sys.wait(5000) -- 等待初始化完成
    
    while true do
        -- 检查MQTT连接是否就绪
        if mqttc and mqttc:ready() then
            -- 获取当前PWM状态
            local light = require("light")
            local pwm_status = light.pwmGetStatus(0)
            local status_data = {}
            
            -- 判断PWM是否活跃 - 通过pwm状态简单判断
            -- 这里使用duty值是否为0来粗略判断
            local is_active = pwm_status.duty > 0
            
            -- 设置状态数据
            status_data.state = is_active and "ON" or "OFF"
            status_data.brightness = pwm_status.duty
            
            -- 发布状态
            local status_json = json.encode(status_data)
            mqttc:publish(status_topic, status_json, 1)
            log.info("mqtt", "定时上报状态", status_json)
        end
        
        sys.wait(60000) -- 每分钟上报一次状态
    end
end

return mqtt_single
