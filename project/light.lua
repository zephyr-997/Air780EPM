-- 创建light模块
local light = {}

-- 定义PWM通道
local PWM_ID0 = 0 -- PWM0对应GPIO1 
local PWM_ID1 = 1 -- PWM1对应GPIO24 
local PWM_ID2 = 2 -- PWM2对应GPIO25 

-- 继电器引脚
local relay_pin = 31  -- 定义继电器引脚

-- PWM相关私有变量
local _pwm_initialized = false
local _current_duty = {}  -- 每个通道的当前占空比（0-100范围）
local _pwm_freq = 1000  -- PWM频率，默认1kHz

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
local function _initRelay()
    if not _relay_initialized then
        -- 设置继电器引脚为输出模式
        gpio.setup(relay_pin, 0, gpio.PULLUP)
        log.info("light", "初始化继电器引脚")
        _relay_initialized = true
    end
end

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

-- 设置继电器状态
function light.relaySet(state)
    _initRelay()  -- 确保初始化
    
    gpio.set(relay_pin, state and 1 or 0)
    log.info("light", "继电器状态已设置为", state and "开启" or "关闭")
    return true
end

-- 获取继电器状态
function light.relayGet()
    _initRelay()  -- 确保初始化
    
    local state = gpio.get(relay_pin)
    return state == 1
end

-- 切换继电器状态
function light.relayToggle()
    _initRelay()  -- 确保初始化
    
    local current = gpio.get(relay_pin)
    gpio.set(relay_pin, current == 1 and 0 or 1)
    log.info("light", "继电器状态已切换为", current == 0 and "开启" or "关闭")
    return true
end

-- MQTT和其他模块便捷控制接口，以下是模版，使用的时light.control({}) 来控制，使用时建议更改为 light.pwmSetDuty(0, 0) 来关闭PWM （因为light.pwmClose(0) 依旧失败）
--[[
light.control({
    pwm_enable = true,     -- 打开PWM
    pwm_id = 0,            -- 使用PWM0通道
    duty = 70,             -- 设置70%占空比
    relay = true           -- 同时打开继电器
}) ]]
function light.control(params)
    if type(params) ~= "table" then
        log.warn("light", "参数必须是表格")
        return false
    end
    
    -- 处理继电器控制
    if params.relay ~= nil then
        light.relaySet(params.relay)
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

