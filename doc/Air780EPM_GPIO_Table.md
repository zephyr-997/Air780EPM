| | | | | | | | | | | | | | | | | | |
|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|
| | | | | | | | | | | | | | | | | | |
| |GPIO分类|Air780EPM 模组管脚名|Air780EHM 模组管脚名|Air780EHV 模组管脚名|Air780EHG 模组管脚名|模组 管脚号|Powerup default|Alt Func0|Alt Func1|Alt Func2|Alt Func3|Alt Func4|Alt Func5|Alt Func6|Alt Func7|LuatOS推荐复用管脚|Notes|
| | |GPIO16|GPIO16|GPIO16|GPIO16|97|I&PU| | | | |GPIO16| | | |GPIO16| |
| | |GPIO17|GPIO17|GPIO17|GPIO17|100|I&PU| | | | |GPIO17| | | |GPIO17| |
| |普通GPIO 低功耗模式下电平无法保持  PSM+模式下电平无法保持|I2C1_SCL|I2C1_SCL|I2C1_SCL|I2C1_SCL|67|I&PU| | |I2C0_SCL|I2C1_SCL|GPIO18|PWM0| | |I2C1_SCL| |
| | |I2C1_SDA|I2C1_SDA|I2C1_SDA|I2C1_SDA|66|I&PU| | |I2C0_SDA|I2C1_SDA|GPIO19|PWM1| | |I2C1_SDA| |
| | |USB_BOOT|USB_BOOT|USB_BOOT|USB_BOOT|82|I&PD| | | | | | | | |USB_BOOT|USB下载使能,固定功能|
| | |PWM0|PWM0|PWM0|PWM0|22 |NI&NP|GPIO1| | | | |PWM0| | |PWM0| |
| | |ONEWIRE|ONEWIRE|ONEWIRE|ONEWIRE|23|NI&NP|GPIO2| | | |ONEWIRE(默认)|PWM1| | |OneWire| |
| | |CAM_MCLK|CAM_MCLK|CAM_MCLK|CAM_MCLK|54|NI&NP|GPIO3|CAM_MCLK| | |ONEWIRE|PWM2| | |CAM_MCLK| |
| | |CAM_BCLK|CAM_BCLK|CAM_BCLK|CAM_BCLK|80|NI&NP|GPIO4|CAM_BCLK|I2C1_SDA| |USIM2_RST| | | |CAM_BCLK|PIN80与PIN63(USIM2_RST)不能同时使用，实为同一主芯片管脚|
| | |CAM_CS|CAM_CS|CAM_CS|CAM_CS|81|NI&NP|GPIO5|CAM_CS|I2C1_SCL| |USIM2_CLK| | | |CAM_CS (电路设计时需上拉,不然影响低功耗表现)|PIN81与PIN62(USIM2_CLK)不能同时使用，实为同一主芯片管脚|
| | |CAM_RX0|CAM_RX0|CAM_RX0|CAM_RX0|55|NI&NP|GPIO6|CAM_RX0|UART2_RXD| |USIM2_DAT| | | |CAM_RX0|PIN55与PIN64(USIM2_DAT)不能同时使用，实为同一主芯片管脚|
| | |CAM_RX1|CAM_RX1|CAM_RX1|CAM_RX1|56|NI&NP|GPIO7|CAM_RX1|UART2_TXD| |ONEWIRE| | | |CAM_RX1| |
| | |USIM2_RST|USIM2_RST|USIM2_RST|USIM2_RST|63|NI&NP| | | | |USIM2_RST| | | | |PIN63与PIN80(CAM_BCLK)不能同时使用，实为同一主芯片管脚|
| | |USIM2_CLK|USIM2_CLK|USIM2_CLK|USIM2_CLK|62|NI&NP| | | | |USIM2_CLK| | | | |PIN62与PIN81(CAM_CS)不能同时使用，实为同一主芯片管脚|
| | |USIM2_DAT|USIM2_DAT|USIM2_DAT|USIM2_DAT|64|NI&NP| | | | |USIM2_DAT| | | | |PIN64与PIN55(CAM_RX0)不能同时使用，实为同一主芯片管脚|
| | |SPI0_CS|SPI0_CS|SPI0_CS|SPI0_CS|83|NI&NP|GPIO8|SPI0_CS|I2C1_SDA| | | | | |SPI0_CS| |
| | |SPI0_MOSI|SPI0_MOSI|SPI0_MOSI|SPI0_MOSI|85|NI&NP|GPIO9|SPI0_MOSI|I2C1_SCL| | | | | |SPI0_MOSI| |
| | |SPI0_MISO|SPI0_MISO|SPI0_MISO|SPI0_MISO|84|NI&NP|GPIO10|SPI0_MISO| |UART2_RXD| | | | |SPI0_MISO| |
| | |SPI0_CLK|SPI0_CLK|SPI0_CLK|SPI0_CLK|86|NI&NP|GPIO11|SPI0_CLK| |UART2_TXD| | | | |SPI0_SCLK| |
| | |UART2_RXD|UART2_RXD|UART2_RXD|悬空|28|NI&NP|GPIO12|SPI1_CS| |UART2_RXD| | | |CAN_RXD|UART2_RXD| |
| | |UART2_TXD|UART2_TXD|UART2_TXD|悬空|29|NI&NP|GPIO13|SPI1_MOSI| |UART2_TXD| | | |CAN_TXD|UART2_TXD| |
| | |UART3_RXD|UART3_RXD|悬空|UART3_RXD|58|NI&NP|GPIO14|SPI1_MISO|I2C0_SDA|UART3_RXD| |PWM0| | |UART3_RXD| |
| | |UART3_TXD|UART3_TXD|悬空|UART3_TXD|57|NI&NP|GPIO15|SPI1_CLK|I2C0_SCL|UART3_TXD| |PWM1| | |UART3_TXD| |
| | |DBG_RXD|DBG_RXD|DBG_RXD|DBG_RXD|38|NI&NP| |DBG_RXD| | | | | | |DBG_RXD| |
| | |DBG_TXD|DBG_TXD|DBG_TXD|DBG_TXD|39|NI&NP| |DBG_TXD| | | | | | |DBG_TXD| |
| | |UART1_RXD|UART1_RXD|UART1_RXD|UART1_RXD|17|NI&NP|GPIO18|UART1_RXD| | | | | | |UART1_RXD| |
| | |UART1_TXD|UART1_TXD|UART1_TXD|UART1_TXD|18|NI&NP|GPIO19|UART1_TXD| | | | | | |UART1_TXD| |
| | |GPIO29|GPIO29|悬空|GPIO29|30|NI&NP|GPIO29| | | | |PWM0| | |GPIO29| |
| | |GPIO30|GPIO30|悬空|GPIO30|31|NI&NP|GPIO30| | | | |PWM1| | |GPIO30| |
| | |GPIO31|GPIO31|悬空|GPIO31|32|NI&NP|GPIO31| | | | |PWM2| | |PWM2| |
| | |GPIO32|GPIO32|悬空|GPIO32|33|NI&NP|GPIO32| | | | | | | |GPIO32| |
| | |PWM4|PWM4|悬空|PWM4|26|NI&NP|GPIO33| | | | |PWM4| | |PWM4| |
| | |LCD_CLK|LCD_CLK|LCD_CLK|LCD_CLK|53|NI&NP|GPIO34|LCD_CLK|I2C0_SDA|UART3_RXD| | | | |LCD_CLK| |
| | |LCD_CS|LCD_CS|LCD_CS|LCD_CS|52|NI&NP|GPIO35|LCD_CS|I2C0_SCL|UART3_TXD| | | | |LCD_CS| |
| | |LCD_RST|LCD_RST|LCD_RST|LCD_RST|49|NI&NP|GPIO36|LCD_RST|I2C1_SCL| | | | | |LCD_RST (电路设计时需上拉,不然影响低功耗表现)|电路设计时需上拉,不然影响低功耗表现|
| | |LCD_SDA|LCD_SDA|LCD_SDA|LCD_SDA|50|NI&NP|GPIO37|LCD_SDA|I2C1_SDA| | | | | |LCD_SDA| |
| | |LCD_RS|LCD_RS|LCD_RS|LCD_RS|51|NI&NP|GPIO38| |LCD_RS| | | | | |LCD_RS| |
| |AONGPIO 低功耗模式下电平可以保持  PSM+模式下电平可以保持|GPIO20|GPIO20|悬空|GPIO20|102|NI&NP|GPIO20| | | | | | | |GPIO20|WAKEUP3|
| | |GPIO21|GPIO21|GPIO21|悬空|107|NI&NP|GPIO21| | | | |PWM4| | |GPIO21|WAKEUP4|
| | |GPIO22|GPIO22|GPIO22|GPIO22|19|NI&NP|GPIO22| | | | | | | |GPIO22|WAKEUP5|
| | |GPIO23|GPIO23|GPIO23|GPIO23|99|NI&NP|GPIO23| | | | |PWM0| | |GPIO23|开机默认高电平输出,可作为高电平上拉使用,不用可修改|
| | |PWM1|PWM1|PWM1|PWM1|20|NI&NP|GPIO24| | | | |PWM1| | |PWM1| |
| | |CAN_RXD|CAN_RXD|CAN_RXD|CAN_RXD|106|NI&NP|GPIO25| | | | |PWM2| |CAN_RXD|CAN_RXD| |
| | |CAN_TXD|CAN_TXD|CAN_TXD|CAN_TXD|25|NI&NP|GPIO26| | | | | | |CAN_TXD|CAN_TXD| |
| | |GPIO27|GPIO27|GPIO27|GPIO27|16|NI&NP|GPIO27| | | | |PWM4| | |GPIO27| |
| | |GPIO28|CAN_STB|CAN_STB|CAN_STB|78|NI&NP|GPIO28| | | |ONEWIRE| | |CAN_RXD|GPIO28|默认用做CAN_STB信号|
| |WAKEUP 低功耗和PSM+模式下均可以作为中断使用|WAKEUP0|WAKEUP0|WAKEUP0|WAKEUP0|101| |WAKEUP0| | | | | | | |WAKEUP0| |
| | |VBUS|VBUS|VBUS|VBUS|61| |VBUS| | | | | | | |VBUS| |
| | |USIM_DET|USIM_DET|USIM_DET|USIM_DET|79| |USIM_DET| | | | | | | |USIM_DET| |
| | |悬空|悬空|WAKEUP6|WAKEUP6|75| |WAKEUP6| | | | | | | |WAKEUP6| |
| | |PWR_KEY|PWR_KEY|PWR_KEY|PWR_KEY|7| |PWR_KEY| | | | | | | |PWR_KEY| |
| | |Air780EPM/EHM/EHV/EHG| | | | |LCD 接口参考| |Camera|CAN接口|485接口|以太网接口| | | | | |
| | |管脚号| | | |管脚名|3-wire SPI| |SPI|CAN|推荐使用UART1  配合UART转485芯片  具体见Air780EPM参考设计|推荐使用SPI0 (PIN83/84/85/86)  详见Air780EPM参考设计| | | | | |
| | |53| | | |LCD_CLK|LCD_CLK| | | | | | | | | | |
| | |52| | | |LCD_CS|LCD_CS| | | | | | | | | | |
| | |49| | | |LCD_RST|LCD_RST| | | | | | | | | | |
| | |50| | | |LCD_SDA|LCD_SDA| | | | | | | | | | |
| | |51| | | |LCD_RST|LCD_RS| | | | | | | | | | |
| | |80| | | |CAM_BCLK| | |CAM_BCLK| | | | | | | | |
| | |81| | | |CAM_CS| | |CAM_CS| | | | | | | | |
| | |55| | | |CAM_RX0| | |CAM_RX0| | | | | | | | |
| | |56| | | |CAM_RX1| | |CAM_RX1| | | | | | | | |
| | |54| | | |CAM_MCLK| | |CAM_MCLK| | | | | | | | |
| | |106| | | |CAN_RXD| | | |CAN_RXD| | | | | | | |
| | |25| | | |CAN_TXD| | | |CAN_TXD| | | | | | | |
| | |78| | | |CAN_STB| | | |GPIO28| | | | | | | |
| |注意事项：| | | | | | | | | | | | | | | | |
| |1|Air780EPM的所有IO，出厂默认电平3.0V；当模组管脚PIN100:GPIO17，有时也会写作PIN100:IO_Volt_Set，被拉低时，IO电平则切换为1.8V； 无论PIN100:GPIO17(有时也会写作PIN100:IO_Volt_Set)是否被拉低，或者PIN100是否有参与，IO电平都可以通过LuatOS软件设置为1.8V/2.8V/3.0V/3.3V(API PM库配置pm.ioVol(id, val)函数)； PIN100:GPIO17本质上就是一个在Powerup时(开机启动状态)默认为I&PU(输入&上拉，电平为高)的GPIO输入，如果不用做IO_Volt_Set检测电平用，可以当做一个普通GPIO使用(可以多一路GPIO使用)；| | | | | | | | | | | | | | | |
| |2|Air780EPM的GPIO，输入功能时，外部高电平电压必须大于0.7*VDD_EXT，外部低电平电压必须小于0.2*VDD_EXT；做输出功能时，对外输出高电平时电压不小于0.8*VDD_EXT，输出低电平时电压不大于0.15*VDD_EXT；Air780EPM的VDD_EXT出厂默认3.0V，跟IO出厂电平一致；则：输入时高需大于0.7*3.0V，低需小于0.2*3.0V；输出时高不能小于0.8*3.0V，低不能大于0.15*3.0V；| | | | | | | | | | | | | | | |
| |3|模组共有三种功耗模式：常规、低功耗和PSM+；其中，低功耗模式和PSM+模式也常被称之为休眠模式，二者区别是低功耗模式可以保持长连接，PSM+模式不能保持长连接但可以快速唤醒、快速驻网；| | | | | | | | | | | | | | | |
| |4|GPIO共有三种类型：普通GPIO、AONGPIO和WAKEUP；普通GPIO在模组低功耗模式和PSM+模式下无法保持电平，也无法接收中断并唤醒，AONGPIO可以保持电平； WAKEUP只能作为输入中断，无法设置为输出，可以在低功耗模式和PSM+模式下接收中断并唤醒；AONGPIO也常被写作为AGPIO、AON_GPIO，以下均以AONGPIO的写法进行描述；| | | | | | | | | | | | | | | |
| |5|AONGPIO在模组低功耗模式和PSM+模式下可以电平保持，可以保持高，也可以保持低；| | | | | | | | | | | | | | | |
| |6|AONGPIO输出驱动能力单管脚<=5mA, 但是所有AONGPIO驱动电流总和也不能超过5mA；| | | | | | | | | | | | | | | |
| |7|AONGPIO电压一致性没有普通IO电压一致性高，普通IO电压偏差在0.05V以内，AGPIO在0.15V以内；| | | | | | | | | | | | | | | |
| |8|普通GPIO输出驱动能力单管脚<=10mA, 但是所有普通驱动电流总和不能超过200mA；| | | | | | | | | | | | | | | |
| |9|WAKEUP固定电平1.8V，由于内部分压，实测电平电压值在1.1V左右，是正常现象；WAKEUP管脚内部上下拉非常弱，驱动能力<30uA；| | | | | | | | | | | | | | | |
| |10|PWRKEY在开机前是开机功能，开机后和WAKEUP一样的功能和特性；| | | | | | | | | | | | | | | |
| |11|模组在低功耗模式或PSM+模式下只能通过WAKEUP，PWRKEY,MAIN_UART唤醒，AONGPIO虽然在低功耗模式/PSM+模式下不掉电，但是无法触发中断；| | | | | | | | | | | | | | | |
| |12|普通GPIO在低功耗模式和PSM+模式下均会处于掉电状态，并且随着系统间歇性唤醒与基站交互而频繁产生高脉冲；| | | | | | | | | | | | | | | |
| |13|普通GPIO/AONGPIO在做输入/中断时，都可以配置/取消内部上下拉，如果内部上下拉不满足条件，可以取消内部上下拉，然后外部加上下拉；| | | | | | | | | | | | | | | |
| |14|GPIO20/GPIO21/GPIO22同时具备AONGPIO和WAKEUP的属性，优点是可以休眠保持和唤醒，缺点是设置为输出时驱动能力<30uA；当GPIO20/GPIO21/GPIO22作为WAKEUP使用时，分别为WAKEUP3/WAKEUP4/WAKEUP5；GPIO20/GPIO21/GPIO22配置成中断模式时，需要在软件上选择是配置为普通IO中断还是WAKEUP中断；| | | | | | | | | | | | | | | |
| |15|所有普通IO中断、AONGPIO中断和WAKEUP中断都支持双边沿中断，不同的是，普通IO和WAKEUP支持软件配置内部上下拉，AONGPIO没有内部上下拉；| | | | | | | | | | | | | | | |
| |16|PIN62与PIN81,PIN63与PIN80,PIN64与PIN55不能同时使用,同一硬件通道,复用为不同软件该功能;| | | | | | | | | | | | | | | |
| |17|I&PU，Input&Pull_Up;     I&PD,Input&Pull_Down;     NI&NP,非输入输出,没有上下拉，若需确定的状态，需要在电路设计时外加上拉或下拉;| | | | | | | | | | | | | | | |
| | | | | | | | | | | | | | | | | | |
| | | | | | | | | | | | | | | | | | |
| | | | | | | | | | | | | | | | | | |
| | | | | | | | | | | | |·| | | | | |
