-- dht11.lua
-- DHT11温湿度传感器驱动模块
-- 使用官方API sensor.dht1x实现，更加可靠

local dht11 = {}

-- 定义DHT11数据引脚
local DHT11_PIN = 32  -- 默认使用GPIO32

-- 记录上次读取时间，防止读取过于频繁
local last_read_time = 0

-- 是否校验CRC
local CHECK_CRC = false  -- 默认不校验CRC，提高成功率

-- 初始化DHT11
function dht11.init(pin)
    -- 如果传入了pin参数则使用传入的值，否则使用默认值
    DHT11_PIN = pin or DHT11_PIN
    
    -- 设置为输出模式，初始状态为高电平
    gpio.setup(DHT11_PIN, 1, gpio.PULLUP)
    log.info("DHT11", "初始化完成", "引脚:", DHT11_PIN)
    
    -- 延时让DHT11稳定
    sys.wait(1000)
    return true
end

-- 读取DHT11数据 - 使用官方API
function dht11.read()
    -- 检查传感器是否就绪
    if DHT11_PIN == nil then
        log.error("DHT11", "未初始化")
        return nil, nil
    end
    
    -- 检查读取间隔，DHT11至少需要1秒的间隔
    local current_time = os.time()
    if current_time - last_read_time < 2 then
        sys.wait((2 - (current_time - last_read_time)) * 1000)
    end
    last_read_time = os.time()
    
    -- 使用官方API读取数据
    local humidity, temperature, result = sensor.dht1x(DHT11_PIN, CHECK_CRC)
    
    -- 将数据从0.01单位转换为整数
    if result then
        humidity = math.floor(humidity / 100 + 0.5)  -- 四舍五入取整
        temperature = temperature / 100
        log.info("DHT11", "读取成功", "湿度:", humidity, "%", "温度:", temperature, "°C")
    else
        log.warn("DHT11", "读取失败")
        return nil, nil
    end
    
    return humidity, temperature
end

-- 连续读取多次并返回有效的平均值，提高可靠性
function dht11.readStable(retries)
    retries = retries or 3
    local sum_humi, sum_temp = 0, 0
    local valid_count = 0
    
    for i = 1, retries do
        local humidity, temperature = dht11.read()
        if humidity and temperature then
            sum_humi = sum_humi + humidity
            sum_temp = sum_temp + temperature
            valid_count = valid_count + 1
        end
        sys.wait(2000)  -- 确保有足够的间隔
    end
    
    if valid_count > 0 then
        local avg_humi = math.floor(sum_humi / valid_count + 0.5)
        local avg_temp = math.floor(sum_temp / valid_count + 0.5)
        return avg_humi, avg_temp
    else
        log.error("DHT11", "多次读取均失败")
        return nil, nil
    end
end

-- 获取格式化的数据，便于显示和使用
function dht11.getFormatted()
    local humidity, temperature = dht11.read()
    if humidity and temperature then
        return {
            humidity = humidity,
            temperature = temperature,
            humidity_str = string.format("%d%%", humidity),
            temperature_str = string.format("%d°C", temperature)
        }
    else
        return nil
    end
end

-- 测试DHT11功能
function dht11.test()
    log.info("DHT11", "开始测试DHT11传感器")
    
    -- 初始化DHT11
    if not dht11.init() then
        log.error("DHT11", "测试失败，初始化错误")
        return false
    end
    
    -- 尝试不同的CRC设置
    log.info("DHT11", "尝试不同的CRC设置进行测试")
    
    -- 原始设置下读取
    CHECK_CRC = false
    log.info("DHT11", "不校验CRC模式")
    local success_no_crc = 0
    
    for i = 1, 3 do
        log.info("DHT11", "第"..i.."次测试(无CRC)")
        local humidity, temperature = dht11.read()
        
        if humidity and temperature then
            log.info("DHT11", "测试成功", "湿度:", humidity, "%", "温度:", temperature, "°C")
            success_no_crc = success_no_crc + 1
        else
            log.warn("DHT11", "测试失败")
        end
        
        -- 间隔2秒进行下一次测试
        sys.wait(2000)
    end
    
    -- 开启CRC校验下读取
    CHECK_CRC = true
    log.info("DHT11", "校验CRC模式")
    local success_crc = 0
    
    for i = 1, 2 do
        log.info("DHT11", "第"..i.."次测试(有CRC)")
        local humidity, temperature = dht11.read()
        
        if humidity and temperature then
            log.info("DHT11", "测试成功", "湿度:", humidity, "%", "温度:", temperature, "°C")
            success_crc = success_crc + 1
        else
            log.warn("DHT11", "测试失败")
        end
        
        -- 间隔2秒进行下一次测试
        sys.wait(2000)
    end
    
    -- 恢复默认设置
    CHECK_CRC = false
    
    -- 计算总成功率
    local total_tests = 5
    local total_success = success_no_crc + success_crc
    local success_rate = (total_success / total_tests) * 100
    
    log.info("DHT11", "测试完成", 
             "成功率:", success_rate, "%",
             "无CRC成功:", success_no_crc, "/3",
             "有CRC成功:", success_crc, "/2")
    
    return total_success > 0
end

-- 设置是否校验CRC
function dht11.setCRC(check)
    CHECK_CRC = check
    log.info("DHT11", "CRC校验模式", CHECK_CRC and "开启" or "关闭")
end

return dht11 