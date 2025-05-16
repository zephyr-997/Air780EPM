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

local pub0101_topic = "HA-AIR780EPM-01/01/state" -- .. (mcu.unique_id():toHex()) -- 后面这个是设备id
local pub0102_topic = "HA-AIR780EPM-01/02/state" -- DHT11温湿度数据上报主题
local relay0201_topic = "HA-AIR780EPM-02/1/set" 
local relay0202_topic = "HA-AIR780EPM-02/2/set" 
local status0301_topic = "HA-AIR780EPM-03/1/status" 
local command0301_topic = "HA-AIR780EPM-03/1/command" 
local status0302_topic = "HA-AIR780EPM-03/2/status" 
local command0302_topic = "HA-AIR780EPM-03/2/command" 
local status0303_topic = "HA-AIR780EPM-03/3/status" 
local command0303_topic = "HA-AIR780EPM-03/3/command"

local mqttc = nil
-- 将mqttc作为模块属性公开出去
mqtt_single.mqttc = nil

-- 定义继电器引脚常量，与light.lua保持一致
local RELAY_PIN_1 = 30  -- 继电器1引脚
local RELAY_PIN_2 = 31  -- 继电器2引脚

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
    -- pub0101_topic = "/luatos/pub/" .. device_id  -- 上报主题
    -- relay0201_topic = "/luatos/sub/" .. device_id  -- 下发主题

    -- 打印一下上报(pub)和下发(sub)的topic名称
    -- 上报: 设备 ---> 服务器
    -- 下发: 设备 <--- 服务器
    -- 可使用mqtt.x等客户端进行调试
    log.info("mqtt", "pub", pub0101_topic)
    log.info("mqtt", "pub", pub0102_topic, "(DHT11温湿度)")
    log.info("mqtt", "sub", relay0201_topic)
    log.info("mqtt", "sub", relay0202_topic)
    log.info("mqtt", "sub/pub", command0301_topic, status0301_topic)
    log.info("mqtt", "sub/pub", command0302_topic, status0302_topic)
    log.info("mqtt", "sub/pub", command0303_topic, status0303_topic)

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
    mqtt_single.mqttc = mqttc -- 同步更新公开变量

    mqttc:auth(client_id,user_name,password) -- client_id必填,其余选填
    -- mqttc:keepalive(240) -- 默认值240s
    mqttc:autoreconn(true, 3000) -- 自动重连机制

    mqttc:on(function(mqtt_client, event, data, payload) -- 回调函数处理MQTT事件
        -- 用户自定义代码
        log.info("mqtt", "event", event, mqtt_client, data, payload)
        if event == "conack" then
            -- 联上了
            sys.publish("mqtt_conack")
            mqtt_client:subscribe(relay0201_topic)--订阅继电器1主题
            mqtt_client:subscribe(relay0202_topic)--订阅继电器2主题
            mqtt_client:subscribe(command0301_topic)--订阅PWM1命令主题
            mqtt_client:subscribe(command0302_topic)--订阅PWM0命令主题
            mqtt_client:subscribe(command0303_topic)--订阅PWM2命令主题
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
    mqtt_single.mqttc = nil -- 同步更新公开变量
end

-- 这里演示在另一个task里上报数据, 会定时上报数据,不需要就注释掉
function mqtt_single.publish()
    sys.wait(1000) 
    local data = 0
    local qos = 1 -- QOS0不带puback, QOS1是带puback的
    if not _G.DS18B20_TEMP then
        _G.DS18B20_TEMP = 0
    end
    if not _G.DHT11_TEMP then
        _G.DHT11_TEMP = 0
    end
    if not _G.DHT11_HUMI then
        _G.DHT11_HUMI = 0
    end
    while true do
        sys.wait(10000) -- 10s发送一次数据
        
        -- 发送DS18B20温度数据
        data = _G.DS18B20_TEMP -- 获取温度数据
        data = string.format("%.2f", data) -- 保留两位小数
        if mqttc and mqttc:ready() then
            -- local pkgid = mqttc:publish(pub0101_topic, data .. os.date(), qos) -- 带时间戳
            local pkgid = mqttc:publish(pub0101_topic, data, qos) -- 不带时间戳
            log.info("mqtt", "已发送DS18B20温度数据", data, "°C")
        else
            log.info("mqtt", "mqtt未连接")
        end
        
        -- 发送DHT11湿度数据
        if _G.DHT11_HUMI > 0 then
            -- 直接发送湿度数值
            local humidity_str = tostring(_G.DHT11_HUMI)
            if mqttc and mqttc:ready() then
                mqttc:publish(pub0102_topic, humidity_str, qos)
                log.info("mqtt", "已发送DHT11湿度数据", "湿度:", _G.DHT11_HUMI, "%")
            end
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
    if topic == command0301_topic then
        -- 尝试解析JSON格式的payload
        local success, data = pcall(json.decode, payload)
        if success and data then
            -- 获取light模块
            local light = require("light")
            local status_data = {} -- 创建状态数据表
            
            -- 处理PWM控制命令
            if data.state then
                if data.state == "ON" then
                    -- 如果同时有亮度值，设置PWM亮度
                    if data.brightness and type(data.brightness) == "number" then
                        -- 亮度值范围已是0-100，直接使用
                        light.pwmOpen(1, data.brightness)
                        log.info("mqtt", "通过MQTT命令打开PWM1，亮度为", data.brightness, "%")
                        -- 设置状态数据
                        status_data.state = "ON"
                        status_data.brightness = data.brightness
                    else
                        -- 如果只有开灯命令没有亮度，则设为100%
                        light.pwmOpen(1, 100)
                        log.info("mqtt", "通过MQTT命令打开PWM1，亮度为100%")
                        -- 设置状态数据
                        status_data.state = "ON"
                        status_data.brightness = 100
                    end
                elseif data.state == "OFF" then
                    -- 获取当前亮度，保存上次的亮度值
                    local pwm_status = light.pwmGetStatus(1)
                    local saved_brightness = pwm_status.duty
                    
                    -- 使用设置占空比为0的方式代替关闭PWM
                    local close_result = light.pwmSetDuty(1, 0)
                    log.info("mqtt", "通过MQTT命令将PWM1占空比设为0", close_result and "成功" or "失败")
                    
                    -- 无论设置是否成功，都设置状态数据为OFF
                    status_data.state = "OFF"
                    status_data.brightness = saved_brightness
                end
            elseif data.brightness and type(data.brightness) == "number" then
                -- 只有亮度值没有状态命令，调整占空比
                light.pwmSetDuty(1, data.brightness)
                log.info("mqtt", "仅设置PWM1亮度为", data.brightness, "%")
                
                -- PWM设置亮度意味着已开启，状态为ON
                status_data.state = "ON"
                status_data.brightness = data.brightness
            end
            
            -- 发布状态消息到status0301_topic
            if mqttc and mqttc:ready() and next(status_data) ~= nil then
                local status_json = json.encode(status_data)
                mqttc:publish(status0301_topic, status_json, 1)
                log.info("mqtt", "发送PWM1状态反馈", status_json)
            end
        else
            log.warn("mqtt", "JSON解析失败", payload)
        end
    elseif topic == command0302_topic then
        -- 尝试解析JSON格式的payload
        local success, data = pcall(json.decode, payload)
        if success and data then
            -- 获取light模块
            local light = require("light")
            local status_data = {} -- 创建状态数据表
            
            -- 处理PWM控制命令
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
            
            -- 发布状态消息到status0302_topic
            if mqttc and mqttc:ready() and next(status_data) ~= nil then
                local status_json = json.encode(status_data)
                mqttc:publish(status0302_topic, status_json, 1)
                log.info("mqtt", "发送状态反馈", status_json)
            end
        else
            log.warn("mqtt", "JSON解析失败", payload)
        end
    elseif topic == command0303_topic then
        -- 尝试解析JSON格式的payload
        local success, data = pcall(json.decode, payload)
        if success and data then
            -- 获取light模块
            local light = require("light")
            local status_data = {} -- 创建状态数据表
            
            -- 处理PWM控制命令
            if data.state then
                if data.state == "ON" then
                    -- 如果同时有亮度值，设置PWM亮度
                    if data.brightness and type(data.brightness) == "number" then
                        -- 亮度值范围已是0-100，直接使用
                        light.pwmOpen(2, data.brightness)
                        log.info("mqtt", "通过MQTT命令打开PWM2，亮度为", data.brightness, "%")
                        -- 设置状态数据
                        status_data.state = "ON"
                        status_data.brightness = data.brightness
                    else
                        -- 如果只有开灯命令没有亮度，则设为100%
                        light.pwmOpen(2, 100)
                        log.info("mqtt", "通过MQTT命令打开PWM2，亮度为100%")
                        -- 设置状态数据
                        status_data.state = "ON"
                        status_data.brightness = 100
                    end
                elseif data.state == "OFF" then
                    -- 获取当前亮度，保存上次的亮度值
                    local pwm_status = light.pwmGetStatus(2)
                    local saved_brightness = pwm_status.duty
                    
                    -- 使用设置占空比为0的方式代替关闭PWM
                    local close_result = light.pwmSetDuty(2, 0)
                    log.info("mqtt", "通过MQTT命令将PWM2占空比设为0", close_result and "成功" or "失败")
                    
                    -- 无论设置是否成功，都设置状态数据为OFF
                    status_data.state = "OFF"
                    status_data.brightness = saved_brightness
                end
            elseif data.brightness and type(data.brightness) == "number" then
                -- 只有亮度值没有状态命令，调整占空比
                light.pwmSetDuty(2, data.brightness)
                log.info("mqtt", "仅设置PWM2亮度为", data.brightness, "%")
                
                -- PWM设置亮度意味着已开启，状态为ON
                status_data.state = "ON"
                status_data.brightness = data.brightness
            end
            
            -- 发布状态消息到status0303_topic
            if mqttc and mqttc:ready() and next(status_data) ~= nil then
                local status_json = json.encode(status_data)
                mqttc:publish(status0303_topic, status_json, 1)
                log.info("mqtt", "发送PWM2状态反馈", status_json)
            end
        else
            log.warn("mqtt", "JSON解析失败", payload)
        end
    -- 检查原有的主题消息
    elseif topic == relay0201_topic then
        -- 直接处理非JSON格式的继电器控制命令
        local light = require("light")
        local status_data = {} -- 创建状态数据表
        
        if payload == "ON" then
            -- 开启继电器1
            light.relaySet(true, RELAY_PIN_1)
            log.info("mqtt", "通过MQTT命令开启继电器1")
            
            -- 添加继电器状态到反馈数据
            status_data.relay1 = true
            
        elseif payload == "OFF" then
            -- 关闭继电器1
            light.relaySet(false, RELAY_PIN_1)
            log.info("mqtt", "通过MQTT命令关闭继电器1")
            
            -- 添加继电器状态到反馈数据
            status_data.relay1 = false
        end
        
        -- 发送状态反馈
        if mqttc and mqttc:ready() and next(status_data) ~= nil then
            local status_json = json.encode(status_data)
            mqttc:publish(status0302_topic, status_json, 1)
            log.info("mqtt", "发送状态反馈", status_json)
        end
    elseif topic == relay0202_topic then
        -- 直接处理非JSON格式的继电器2控制命令
        local light = require("light")
        local status_data = {} -- 创建状态数据表
        
        if payload == "ON" then
            -- 开启继电器2
            light.relaySet(true, RELAY_PIN_2)
            log.info("mqtt", "通过MQTT命令开启继电器2")
            
            -- 添加继电器状态到反馈数据
            status_data.relay2 = true
            
        elseif payload == "OFF" then
            -- 关闭继电器2
            light.relaySet(false, RELAY_PIN_2)
            log.info("mqtt", "通过MQTT命令关闭继电器2")
            
            -- 添加继电器状态到反馈数据
            status_data.relay2 = false
        end
        
        -- 发送状态反馈
        if mqttc and mqttc:ready() and next(status_data) ~= nil then
            local status_json = json.encode(status_data)
            mqttc:publish(status0302_topic, status_json, 1)
            log.info("mqtt", "发送状态反馈", status_json)
        end
    end
end)

-- 更新状态上报函数，同时上报PWM和继电器状态
function mqtt_single.reportStatus()
    sys.wait(5000) -- 等待初始化完成
    
    while true do
        -- 检查MQTT连接是否就绪
        if mqttc and mqttc:ready() then
            -- 获取light模块
            local light = require("light")
            
            -- 获取PWM0状态并上报
            local pwm0_status = light.pwmGetStatus(0)
            local status0_data = {}
            
            -- 判断PWM0是否活跃
            local is_active0 = pwm0_status.duty > 0
            
            -- 设置PWM0状态数据
            status0_data.state = is_active0 and "ON" or "OFF"
            status0_data.brightness = pwm0_status.duty
            
            -- 添加继电器1和继电器2状态
            status0_data.relay1 = light.relayGet(RELAY_PIN_1)
            status0_data.relay2 = light.relayGet(RELAY_PIN_2)
            
            -- 发布PWM0状态
            local status0_json = json.encode(status0_data)
            mqttc:publish(status0302_topic, status0_json, 1)
            log.info("mqtt", "定时上报PWM0状态", status0_json)
            
            -- 获取PWM1状态并上报
            local pwm1_status = light.pwmGetStatus(1)
            local status1_data = {}
            
            -- 判断PWM1是否活跃
            local is_active1 = pwm1_status.duty > 0
            
            -- 设置PWM1状态数据
            status1_data.state = is_active1 and "ON" or "OFF"
            status1_data.brightness = pwm1_status.duty
            
            -- 发布PWM1状态
            local status1_json = json.encode(status1_data)
            mqttc:publish(status0301_topic, status1_json, 1)
            log.info("mqtt", "定时上报PWM1状态", status1_json)
            
            -- 获取PWM2状态并上报
            local pwm2_status = light.pwmGetStatus(2)
            local status2_data = {}
            
            -- 判断PWM2是否活跃
            local is_active2 = pwm2_status.duty > 0
            
            -- 设置PWM2状态数据
            status2_data.state = is_active2 and "ON" or "OFF"
            status2_data.brightness = pwm2_status.duty
            
            -- 发布PWM2状态
            local status2_json = json.encode(status2_data)
            mqttc:publish(status0303_topic, status2_json, 1)
            log.info("mqtt", "定时上报PWM2状态", status2_json)
            
            -- 上报DHT11湿度数据
            if _G.DHT11_HUMI > 0 then
                -- 直接发送湿度数值
                local humidity_str = tostring(_G.DHT11_HUMI)
                mqttc:publish(pub0102_topic, humidity_str, 1)
                log.info("mqtt", "定时上报DHT11湿度数据", "湿度:", _G.DHT11_HUMI, "%")
            end
        end
        
        sys.wait(60000) -- 每分钟上报一次状态
    end
end

return mqtt_single
