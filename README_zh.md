# 基于FPGA的PID电机控制器

[English](README.md) | [中文](README_zh.md)

## 项目概述

本项目在 FPGA 上实现了一个 PID (比例-积分-微分) 控制器，用于精确调节电机速度。它被设计为自主机器人车的子系统，通过保持四个车轮的一致速度，确保车辆平稳和精确的移动。

## 主要特性

- 用于电机速度调节的闭环 PID 控制系统
- 可配置的 PID 参数
- FPGA 实现，实现高速实时控制
- 支持四个独立电机
- 生成 PWM 信号进行电机控制
- 通过 UART 通信接收电机的目标转速 (RPM) 值
- 支持刹车，同时避免在转向时车轮锁死
- 实时读取电机编码器的转速、计算地面摩擦系数

## 硬件要求

- FPGA 开发板：矽速科技 (Sipeed) FPGA
    - 我使用的是 Tang Primer 25k，其他型号也应该可以使用
- 电机驱动 PCB（自定义设计，不包含在本仓库中）
- 电机驱动 IC：AT8236（4个）
    - [AT8236中文数据手册](https://www.lcsc.com/datasheet/lcsc_datasheet_2109242230_ZHONGKEWEI-AT8236_C2827823.pdf)
    - 如果使用其他驱动器，可能需要修改设计
- 带编码器的直流电机（4个）

## 软件要求

- 高云 (Gowin) EDA (用于综合和实现)
- MATLAB (用于PID系数仿真和调优)

## 项目结构

该项目由几个Verilog模块和实用工具组成:

### Verilog Modules

1. `top.v`: 集成所有子模块的顶层模块。

2. `pid_input_processor.v`: 处理 PID 控制器的输入。

3. `pid_output_processor.v`: 将 PID 输出转换为 PWM 信号以控制电机。

4. `rpm_reader.v`: 读取和处理编码器信号以计算电机实时转速。

5. `uart_recv.v`: 通过 UART 接收指令和目标转速值。

6. `uart_controller.v`: 将接收到的 UART 数据解码为控制信号。

7. `uart_send.v`: 通过 UART 发送数据 (用于调试或监控)。

8. `uart_driver.v`: 处理 UART 通信以发送地面摩擦系数数据。

9. `signed_divider.v`: 执行有符号除法运算。

### 实用工具

`tools/` 目录包含辅助开发和测试的实用脚本：

1. `fixedPointToDecimal.m` (MATLAB): 将定点数转换为十进制表示。

2. `pid_sim.m` (MATLAB): 使用给定参数模拟 PID 控制器。

3. `uart_cmd_gen.cpp` (C++): 生成用于设置电机目标转速值的 UART 命令。

## PID 控制器

核心 PID 控制器使用高云的 PID Controller 3p3z IP 实现。它使用三零三极数字离散时间系统，经过优化以最小化稳态误差、波动和超调。PID 默认计算频率设置为 1.2 kHz，以避免潜在的振铃效应。

## 使用方法

1. 克隆仓库：
    ```bash
    git clone https://github.com/RT216/fpga-pid_motor
    ```
2. 在高云 Gowin EDA 中打开项目。
3. 综合并实现设计。
4. 综合并实现设计。
5. 将 FPGA 连接到电机驱动 PCB 和电机。
6. 使用 UART 向系统发送目标 RPM 值。
    - 将 4 个电机的 RPM 均设定为 0 即为刹车指令。仅将其中某几个电机速度设定为 0 不会导致这些电机锁死。

### UART 协议

UART 接收器使用简单的命令格式：
1. 设置目标转速命令：`0x91`
2. 高 5 位: `{3'b[通道号], 5'b[rpm高位]}`
3. 低 8 位: `8'b[rpm低位]`
4. 返回命令: `0xFF`

### 工具

`tools/` 目录包含几个辅助开发和测试的实用脚本:

1. `fixedPointToDecimal.m` (MATLAB)

    这个脚本特别适用于解释 PID 控制器参数，这些参数在 Verilog 代码中配置为定点数。它有助于轻松读取和理解这些参数的实际值。

2. `pid_sim.m` (MATLAB)
	
    在 FPG A实现之前使用此脚本测试和调整 PID 参数。它提供了一种快速可视化系统响应和稳定性的方法。

3.	`uart_cmd_gen.cpp` (C++)
	
    编译并运行此程序，快速生成正确的 UART 命令，用于为每个电机设置所需的 RPM 值。它根据 FPGA 实现使用的协议格式化命令。

## 致谢
本项目使用了 Gowin PID Controller 3p3z IP。更多信息，请参考：
- Gowin PID Controller 3p3z IP 用户指南, 高云半导体有限公司, 版本 1.0, 2023年2月22日. [在线]. 可用: [https://www.gowinsemi.com.cn/enrollment_view.aspx?Id=915](https://www.gowinsemi.com.cn/enrollment_view.aspx?Id=915)