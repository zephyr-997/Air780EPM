-- MQ2烟雾传感器模块
-- 支持模拟量(AO)和数字量(DO)读取

local mq2 = {}

-- 传感器引脚配置
local AO_PIN = 0  -- 模拟输出引脚，连接到ADC0
local DO_PIN = 27 -- 数字输出引脚，连接到GPIO27

-- 传感器状态全局变量
_G.MQ2_GAS_VALUE = 0  -- 气体浓度值（模拟量，单位mV）
_G.MQ2_GAS_ALERT = false  -- 气体报警状态（数字量）
_G.MQ2_GAS_PPM = 0  -- 气体浓度值（PPM）

-- 参数配置
local SAMPLE_INTERVAL = 2000  -- 采样间隔(ms)
local GAS_THRESHOLD = 1000    -- 气体浓度报警阈值(mV)，可根据实际情况调整
local ALERT_DEBOUNCE = 3      -- 消抖次数，防止误报

-- 采样次数和结果存储
local sample_count = 0
local sample_results = {}
local alert_count = 0

-- 初始化MQ2传感器
function mq2.init()
    log.info("MQ2", "初始化MQ2传感器")
    
    -- 初始化模拟输入引脚
    -- 设置ADC量程为最大值(默认为3.6V)
    adc.setRange(adc.ADC_RANGE_MAX)  -- 需要在adc.open之前设置
    
    -- 打开ADC通道
    if not adc.open(AO_PIN) then
        log.error("MQ2", "ADC通道打开失败", AO_PIN)
        return false
    end
    
    -- 初始化数字输入引脚（如果使用）
    if DO_PIN then
        -- 配置为输入，带内部上拉
        gpio.setup(DO_PIN, function(val)
            -- 数字输出引脚为低电平时表示检测到气体超标
            _G.MQ2_GAS_ALERT = not val
            if not val then
                log.warn("MQ2", "气体报警信号触发")
                -- 这里可以添加报警处理逻辑
            end
        end, gpio.PULLUP)
    end
    
    log.info("MQ2", "MQ2传感器初始化完成")
    return true
end

-- 读取MQ2传感器模拟值
function mq2.readAnalog()
    -- 检查ADC是否已初始化
    if AO_PIN == nil then
        log.error("MQ2", "传感器未初始化")
        return nil
    end
    
    -- 读取ADC值
    local value = adc.get(AO_PIN)
    if not value then
        log.error("MQ2", "ADC读取失败")
        return nil
    end
    
    -- 更新全局变量
    _G.MQ2_GAS_VALUE = value
    
    -- 转换为PPM值并更新全局变量
    mq2.convertToPPM(value)
    
    -- 根据模拟量判断是否超过阈值
    if value > GAS_THRESHOLD then
        alert_count = alert_count + 1
        if alert_count >= ALERT_DEBOUNCE then
            _G.MQ2_GAS_ALERT = true
            log.warn("MQ2", "气体浓度超过阈值", value, "mV", "约", _G.MQ2_GAS_PPM, "PPM")
        end
    else
        alert_count = 0
        _G.MQ2_GAS_ALERT = false
    end
    
    return value
end

-- 读取MQ2传感器数字值
function mq2.readDigital()
    -- 检查数字引脚是否已初始化
    if DO_PIN == nil then
        log.error("MQ2", "数字引脚未初始化")
        return nil
    end
    
    -- 读取数字引脚状态
    -- 低电平表示检测到气体（根据传感器模块设计可能有所不同）
    local value = gpio.get(DO_PIN)
    _G.MQ2_GAS_ALERT = not value
    
    return not value
end

-- 获取多次采样的平均值，滤波处理
function mq2.readAverage(count)
    count = count or 5  -- 默认采样5次
    
    -- 初始化采样数组
    sample_results = {}
    sample_count = 0
    
    -- 多次采样
    for i = 1, count do
        local value = mq2.readAnalog()
        if value then
            sample_count = sample_count + 1
            sample_results[sample_count] = value
        end
        sys.wait(50)  -- 采样间隔50ms
    end
    
    -- 计算平均值
    if sample_count > 0 then
        local sum = 0
        for i = 1, sample_count do
            sum = sum + sample_results[i]
        end
        local avg = sum / sample_count
        _G.MQ2_GAS_VALUE = avg
        
        -- 更新PPM值
        mq2.convertToPPM(avg)
        
        return avg
    else
        return nil
    end
end

-- 转换模拟量为PPM值（需要根据传感器特性和校准值调整）
function mq2.convertToPPM(value)
    -- 此处需要根据传感器的特性曲线进行转换
    -- 以下公式仅为示例，实际使用时需要校准
    if not value then return nil end
    
    -- 假设线性关系：PPM = k * ADC值 + b
    -- 这里使用简化版本，实际中需要进行传感器校准
    local k = 10  -- 比例系数
    local b = 100  -- 偏移量
    
    local ppm = k * (value / 1000) + b
    local ppm_value = math.floor(ppm)
    
    -- 更新全局变量
    _G.MQ2_GAS_PPM = ppm_value
    
    return ppm_value
end

-- 判断是否存在危险气体
function mq2.isAlert()
    return _G.MQ2_GAS_ALERT
end

-- 获取当前气体浓度值
function mq2.getGasValue()
    return _G.MQ2_GAS_VALUE
end

-- 获取当前气体浓度PPM值
function mq2.getGasPPM()
    return _G.MQ2_GAS_PPM
end

-- 测试MQ2传感器功能
function mq2.test()
    log.info("MQ2", "开始测试MQ2传感器")
    
    -- 初始化传感器
    if not mq2.init() then
        log.error("MQ2", "初始化失败")
        return false
    end
    
    -- 等待传感器预热（MQ2需要预热才能稳定工作）
    log.info("MQ2", "等待传感器预热...（约10秒）")
    sys.wait(10000)  -- 预热10秒
    
    -- 测试模拟量读取
    log.info("MQ2", "测试模拟量读取")
    local value = mq2.readAverage(5)
    if value then
        log.info("MQ2", "模拟量读取成功", value, "mV")
        local ppm = mq2.convertToPPM(value)
        log.info("MQ2", "估算气体浓度", ppm, "PPM")
    else
        log.error("MQ2", "模拟量读取失败")
    end
    
    -- 测试数字量读取（如果使用）
    if DO_PIN then
        log.info("MQ2", "测试数字量读取")
        local alert = mq2.readDigital()
        log.info("MQ2", "数字量读取结果", "报警状态:", alert)
    end
    
    log.info("MQ2", "MQ2传感器测试完成")
    return true
end

-- 启动连续监测（在任务中调用）
function mq2.startMonitor()
    log.info("MQ2", "启动MQ2传感器监测")
    
    -- 初始化传感器
    if not mq2.init() then
        log.error("MQ2", "初始化失败，无法启动监测")
        return false
    end
    
    -- 等待传感器预热
    log.info("MQ2", "传感器预热中...")
    sys.wait(30000)  -- 预热30秒
    log.info("MQ2", "传感器预热完成，开始监测")
    
    -- 持续监测
    while true do
        -- 读取传感器数据
        local value = mq2.readAverage(3)
        if value then
            log.info("MQ2", "气体浓度", value, "mV", "报警状态:", _G.MQ2_GAS_ALERT)
        else
            log.error("MQ2", "读取失败")
            -- 尝试重新初始化
            mq2.init()
        end
        
        -- 等待下一次采样
        sys.wait(SAMPLE_INTERVAL)
    end
end

return mq2 