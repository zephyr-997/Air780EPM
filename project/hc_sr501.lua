-- 创建HC-SR501人体感应模块
local hc_sr501 = {}

-- 配置参数
local DEFAULT_INPUT_PIN = 16   -- 人体感应器信号输入引脚
local DEFAULT_LED_PIN = 27     -- LED输出引脚
local DEFAULT_DEBOUNCE = 50    -- 去抖时间(ms)

-- 私有变量
local _inputPin = DEFAULT_INPUT_PIN
local _ledPin = DEFAULT_LED_PIN
local _input = nil
local _led = nil
local _isInit = false

-- 私有函数：初始化引脚
local function _initPins()
    if _isInit then return true end
    
    -- 配置人体感应输入引脚
    _input = gpio.setup(_inputPin, nil)
    if not _input then
        log.error("hc_sr501", "初始化输入引脚失败", _inputPin)
        return false
    end
    
    -- 配置LED输出引脚
    _led = gpio.setup(_ledPin, 1)
    if not _led then
        log.error("hc_sr501", "初始化LED引脚失败", _ledPin)
        return false
    end
    
    -- 配置输入引脚去抖
    gpio.debounce(_inputPin, DEFAULT_DEBOUNCE)
    log.info("hc_sr501", "初始化完成", "输入引脚:", _inputPin, "输出引脚:", _ledPin)
    _isInit = true
    return true
end

-- 公开函数：初始化模块
function hc_sr501.init(inputPin, ledPin)
    _inputPin = inputPin or DEFAULT_INPUT_PIN
    _ledPin = ledPin or DEFAULT_LED_PIN
    _isInit = false  -- 重置初始化状态
    return _initPins()
end

-- 公开函数：设置LED状态
function hc_sr501.setLed(state)
    if not _isInit and not _initPins() then
        return false
    end
    
    _led(state and 1 or 0)
    log.debug("hc_sr501", "LED状态", state and "开" or "关")
    return true
end

-- 公开函数：读取传感器状态
function hc_sr501.read()
    if not _isInit and not _initPins() then
        return nil
    end
    
    local state = _input()
    log.debug("hc_sr501", "传感器状态", state)
    return state
end

-- 公开函数：启动监控任务
function hc_sr501.start()
    -- 确保初始化
    if not _isInit and not _initPins() then
        log.error("hc_sr501", "初始化失败，无法启动监控")
        return false
    end
    
    log.info("hc_sr501", "启动人体感应监控")
    
    -- 监控循环
    while true do
        local state = _input()
        _led(state)  -- 传感器检测到人体移动时LED亮
        
        if state == 1 then
            log.info("hc_sr501", "检测到人体移动")
        end
        
        sys.wait(500)
    end
end

-- 可选：设置不同的监控方式
function hc_sr501.startWithCallback(callback, interval)
    -- 确保初始化
    if not _isInit and not _initPins() then
        log.error("hc_sr501", "初始化失败，无法启动监控")
        return false
    end
    
    interval = interval or 500
    log.info("hc_sr501", "启动人体感应监控(回调模式)")
    
    -- 监控循环
    while true do
        local state = _input()
        _led(state)
        
        -- 执行回调
        if callback then
            callback(state)
        end
        
        sys.wait(interval)
    end
end

return hc_sr501
