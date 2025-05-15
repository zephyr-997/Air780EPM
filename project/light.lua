-- 创建light模块
local light = {}

-- 定义PWM通道
local PWM_ID0 = 0 -- PWM0对应GPIO1 --正常
local PWM_ID1 = 1 -- PWM1对应GPIO24 --正常
local PWM_ID2 = 2 -- PWM2对应GPIO25 --正常
local led_pin = 31  -- 定义LED引脚

-- 私有变量和函数
local function _setupPwm()
    gpio.setup(led_pin, 1) -- 设置GPIO31为输出模式
    log.info("light", "初始化PWM和LED引脚")
end

-- 启动PWM亮度控制任务
function light.startLightControl()
    -- 初始化设置
    _setupPwm()
    log.info("light", "启动PWM输出和亮度控制")
    
    -- 任务主循环
    while true do
        -- 开启pwm通道0，设置脉冲频率为1kHz，占空比为25%
        pwm.open(PWM_ID0, 1000, 250, 0, 1000) -- 25%占空比输出
        log.info("light", "PWM 25%")
        sys.wait(1000)
        
        -- 设置为100%占空比
        pwm.open(PWM_ID0, 1000, 1000, 0, 1000) -- 100%占空比输出
        log.info("light", "PWM 100%")
        sys.wait(1000)
        
        -- LED亮
        gpio.set(led_pin, 1)
        log.info("light", "LED亮")
        sys.wait(2000)
        
        -- LED灭
        gpio.set(led_pin, 0)
        log.info("light", "LED灭")
        sys.wait(2000)
    end
end

-- 设置特定占空比
function light.setBrightness(pwmId, brightness)
    -- brightness: 0-1000 (0%-100%)
    _setupPwm() -- 确保初始化
    pwm.open(pwmId, 1000, brightness, 0, 1000)
    log.info("light", "设置亮度", brightness/10, "%")
end

-- 打开LED
function light.turnOnLed()
    _setupPwm() -- 确保初始化
    gpio.set(led_pin, 1)
    log.info("light", "LED已打开")
end

-- 关闭LED
function light.turnOffLed()
    _setupPwm() -- 确保初始化
    gpio.set(led_pin, 0)
    log.info("light", "LED已关闭")
end

-- 返回模块
return light
