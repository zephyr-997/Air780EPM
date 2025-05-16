-- 创建light模块
local light = {}

-- 定义PWM通道
local PWM_ID0 = 0 -- PWM0对应GPIO1 
local PWM_ID1 = 1 -- PWM1对应GPIO24 
local PWM_ID2 = 2 -- PWM2对应GPIO25 

-- 继电器引脚
local relay0201_pin = 30  -- 定义继电器引脚
local relay0202_pin = 31  -- 定义继电器引脚

-- PWM相关私有变量
local _pwm_initialized = false
local _current_duty = {}  -- 每个通道的当前占空比（0-100范围）
local _pwm_freq = 50000  -- PWM频率，默认1kHz

-- 继电器相关私有变量
local _relay_initialized = false

-- 内部函数：将0-100范围的占空比转换为0-1000范围
local function _convertDutyToPwm(duty)
    -- 确保占空比在0-100范围内
    if duty < 0 then duty = 0 end
    if duty > 100 then duty = 100 end
    
    -- 转换为0-1000范围
    return math.floor(duty * 10)
end

-- 内部函数：非阻塞延时（代替sys.wait）
local function _shortDelay(ms)
    local start = mcu.ticks()
    while mcu.ticks() - start < ms do end
end

-- PWM初始化函数
local function _initPwm()
    if not _pwm_initialized then
        log.info("light", "初始化PWM模块")
        _pwm_initialized = true
    end
end

-- 继电器初始化函数
local function _initRelay(pin)
    if not _relay_initialized then
        -- 设置继电器引脚为输出模式
        gpio.setup(relay0201_pin, 0, gpio.PULLUP)
        gpio.setup(relay0202_pin, 0, gpio.PULLUP)
        log.info("light", "初始化继电器引脚")
        _relay_initialized = true
    end
end

-- ================ GPIO测试功能 ================
--[[
-- GPIO测试函数
-- 用于测试GPIO30和GPIO31（继电器控制引脚）是否正常工作
function light.gpioTest()
    log.info("GPIO测试", "开始测试GPIO30和GPIO31")
    
    -- 设置测试参数
    local pins = {30, 31}  -- 测试的引脚列表
    local test_cycles = 5  -- 测试循环次数
    local delay_ms = 500   -- 每次状态变化的延迟时间（毫秒）
    local results = {}     -- 测试结果存储
    
    -- 初始化引脚
    for _, pin in ipairs(pins) do
        -- 设置为输出模式，上拉
        gpio.setup(pin, 0, gpio.PULLUP)
        gpio.set(pin, 0)  -- 初始状态设为低电平
        results[pin] = {success = 0, fail = 0}
        log.info("GPIO测试", "初始化引脚", pin)
    end
    
    -- 执行测试循环
    for cycle = 1, test_cycles do
        log.info("GPIO测试", "测试循环", cycle, "/", test_cycles)
        
        -- 依次测试每个引脚
        for _, pin in ipairs(pins) do
            -- 设置高电平并验证
            gpio.set(pin, 1)
            _shortDelay(delay_ms / 2)  -- 等待短暂时间确保稳定
            local high_result = gpio.get(pin)
            
            if high_result == 1 then
                results[pin].success = results[pin].success + 1
                log.info("GPIO测试", "引脚", pin, "高电平测试成功")
            else
                results[pin].fail = results[pin].fail + 1
                log.error("GPIO测试", "引脚", pin, "高电平测试失败")
            end
            
            _shortDelay(delay_ms)  -- 延时观察
            
            -- 设置低电平并验证
            gpio.set(pin, 0)
            _shortDelay(delay_ms / 2)  -- 等待短暂时间确保稳定
            local low_result = gpio.get(pin)
            
            if low_result == 0 then
                results[pin].success = results[pin].success + 1
                log.info("GPIO测试", "引脚", pin, "低电平测试成功")
            else
                results[pin].fail = results[pin].fail + 1
                log.error("GPIO测试", "引脚", pin, "低电平测试失败")
            end
            
            _shortDelay(delay_ms)  -- 延时观察
        end
    end
    
    -- 输出测试结果总结
    log.info("GPIO测试", "测试完成，结果汇总：")
    for _, pin in ipairs(pins) do
        local success_rate = (results[pin].success / (results[pin].success + results[pin].fail)) * 100
        log.info("GPIO测试", "引脚", pin, "成功率:", string.format("%.1f%%", success_rate), 
                 "成功:", results[pin].success, "失败:", results[pin].fail)
        
        -- 最终判断
        if results[pin].fail == 0 then
            log.info("GPIO测试", "引脚", pin, "测试通过")
        else
            log.warn("GPIO测试", "引脚", pin, "测试未完全通过，请检查硬件连接")
        end
    end
    
    -- 测试完成后，重置引脚状态
    for _, pin in ipairs(pins) do
        gpio.set(pin, 0)
    end
    
    return results
end
]]
-- ================ PWM控制API ================

-- 打开PWM并设置占空比
-- duty: 0-100（占空比百分比）
function light.pwmOpen(pwmId, duty)
    _initPwm()  -- 确保初始化
    
    -- 参数检查
    pwmId = pwmId or PWM_ID0
    duty = duty or 50  -- 默认50%占空比
    
    -- 确保占空比在合法范围内
    if duty < 0 then duty = 0 end
    if duty > 100 then duty = 100 end
    
    -- 记录当前设置（存储0-100范围的值）
    _current_duty[pwmId] = duty
    
    -- 转换为PWM需要的0-1000范围
    local pwm_duty = _convertDutyToPwm(duty)
    
    -- 打开PWM
    local result = pwm.open(pwmId, _pwm_freq, pwm_duty, 0, 1000)
    if result then
        log.info("light", "PWM已打开", "通道:", pwmId, "占空比:", duty, "%")
        return true
    else
        log.error("light", "PWM打开失败", "通道:", pwmId)
        return false
    end
end

-- 关闭PWM - 优化版（依旧失败） -- 解决办法：用 pwm.setDuty 来将PWM设置为0的方式才能稳定成功
function light.pwmClose(pwmId)
    pwmId = pwmId or PWM_ID0
    
    -- 检查是否已经关闭
    if _current_duty[pwmId] == nil or _current_duty[pwmId] == 0 then
        log.info("light", "PWM已经处于关闭状态", "通道:", pwmId)
        _current_duty[pwmId] = 0  -- 确保状态一致
        return true
    end
    
    -- 如果当前亮度高于30%，先降低到30%再关闭，以减轻硬件负载
    if _current_duty[pwmId] > 30 then
        local transition_duty = 30
        log.info("light", "PWM关闭前降低亮度", "通道:", pwmId, "降至:", transition_duty, "%")
        light.pwmSetDuty(pwmId, transition_duty)
        _shortDelay(20)  -- 短暂延时但不阻塞
    end
    
    -- 尝试关闭，最多重试3次
    local max_retries = 3
    local result = false
    
    -- 先更新状态，确保状态一致性
    local original_duty = _current_duty[pwmId]
    _current_duty[pwmId] = 0
    
    for i = 1, max_retries do
        result = pwm.close(pwmId)
        if result then
            log.info("light", "PWM已关闭", "通道:", pwmId, i > 1 and "（第"..i.."次尝试）" or "")
            return true
        else
            log.warn("light", "PWM关闭尝试失败", "通道:", pwmId, "尝试:", i, "/", max_retries)
            _shortDelay(10 * i)  -- 递增延时，但不阻塞
        end
    end
    
    -- 如果所有尝试都失败，记录错误但维持已关闭的状态
    log.error("light", "PWM关闭失败，超过最大重试次数", "通道:", pwmId)
    
    -- 尝试用打开PWM占空比为0的方式来"关闭"PWM输出
    if pwm.open(pwmId, _pwm_freq, 0, 0, 1000) then
        log.info("light", "使用占空比为0的方式关闭PWM", "通道:", pwmId)
        return true
    end
    
    return false
end

-- 设置PWM占空比
-- duty: 0-100（占空比百分比）
function light.pwmSetDuty(pwmId, duty)
    -- 参数检查
    pwmId = pwmId or PWM_ID0
    
    -- 确保占空比在合法范围内
    if duty < 0 then duty = 0 end
    if duty > 100 then duty = 100 end
    
    -- 记录当前设置（存储0-100范围的值）
    _current_duty[pwmId] = duty
    
    -- 转换为PWM需要的0-1000范围
    local pwm_duty = _convertDutyToPwm(duty)
    
    -- 调整占空比
    local result = pwm.setDuty(pwmId, pwm_duty, 0, 1000)
    if result then
        log.info("light", "PWM占空比已设置", "通道:", pwmId, "占空比:", duty, "%")
        return true
    else
        log.error("light", "PWM占空比设置失败", "通道:", pwmId)
        -- 尝试重新打开PWM
        return light.pwmOpen(pwmId, duty)
    end
end

-- 获取PWM当前状态
function light.pwmGetStatus(pwmId)
    pwmId = pwmId or PWM_ID0
    return {
        duty = _current_duty[pwmId] or 0,  -- 返回0-100范围的占空比
        freq = _pwm_freq
    }
end

-- ================ 继电器控制API ================

-- 设置继电器状态，pin可选，默认使用relay0201_pin
function light.relaySet(state, pin)
    _initRelay()  -- 确保初始化
    
    -- 使用传入的pin或默认值
    pin = pin or relay0201_pin
    
    gpio.set(pin, state and 1 or 0)
    log.info("light", "继电器状态已设置为", state and "开启" or "关闭", "引脚:", pin)
    return true
end

-- 获取继电器状态，pin可选，默认使用relay0201_pin
function light.relayGet(pin)
    _initRelay()  -- 确保初始化
    
    -- 使用传入的pin或默认值
    pin = pin or relay0201_pin
    
    local state = gpio.get(pin)
    return state == 1
end

-- 切换继电器状态，pin可选，默认使用relay0201_pin
function light.relayToggle(pin)
    _initRelay()  -- 确保初始化
    
    -- 使用传入的pin或默认值
    pin = pin or relay0201_pin
    
    local current = gpio.get(pin)
    gpio.set(pin, current == 1 and 0 or 1)
    log.info("light", "继电器状态已切换为", current == 0 and "开启" or "关闭", "引脚:", pin)
    return true
end

-- MQTT和其他模块便捷控制接口，更新以支持指定继电器
--[[
light.control({
    pwm_enable = true,     -- 打开PWM
    pwm_id = 0,            -- 使用PWM0通道
    duty = 70,             -- 设置70%占空比
    relay = true,          -- 同时打开继电器
    relay_pin = 30         -- 使用指定的继电器引脚
}) ]]
function light.control(params)
    if type(params) ~= "table" then
        log.warn("light", "参数必须是表格")
        return false
    end
    
    -- 处理继电器控制
    if params.relay ~= nil then
        light.relaySet(params.relay, params.relay_pin)
    end
    
    -- 处理PWM控制
    if params.pwm_enable == true then
        -- 打开PWM
        local duty = params.duty or (_current_duty[params.pwm_id or PWM_ID0] or 50)  -- 默认50%
        local pwmId = params.pwm_id or PWM_ID0
        light.pwmOpen(pwmId, duty)
    elseif params.pwm_enable == false then
        -- 关闭PWM
        local pwmId = params.pwm_id or PWM_ID0
        light.pwmSetDuty(pwmId, 0)
    elseif params.duty ~= nil then
        -- 只调整占空比，不改变开关状态
        local pwmId = params.pwm_id or PWM_ID0
        light.pwmSetDuty(pwmId, params.duty)
    end
    
    return true
end

-- 返回模块
return light

