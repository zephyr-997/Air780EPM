-- LuaTools需要PROJECT和VERSION这两个信息
PROJECT = "project"
VERSION = "1.0.0"

log.info("main", PROJECT, VERSION)

-- sys库是标配
_G.sys = require("sys")

-- 引入light模块
local light = require("light")

-- 设置IO电平为3.3V
pm.ioVol(3, 3300)  -- 参数1为3表示设置VDD_EXT电压，参数2为3300表示设置为3.3V (单位: mV)

--添加硬狗防止程序卡死，如果任务执行时间过长或者阻塞，会导致喂狗超时
if wdt then
    wdt.init(9000)--初始化watchdog设置为9s
    sys.timerLoopStart(wdt.feed, 3000)--3s喂一次狗
end
-- 以上是标配---------------------------------------------

-- 启动亮度控制任务
light.startLightControl()

-- 用户代码已结束---------------------------------------------
-- 结尾总是这一句
sys.run()
-- sys.run()之后后面不要加任何语句!!!!!

