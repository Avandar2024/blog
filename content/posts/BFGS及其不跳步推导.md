+++
title = "BFGS及其不跳步推导"
date = 2026-06-08
+++

# BFGS 及其不跳步推导

BFGS 是拟牛顿方法中最常用的一种。它的想法是：不用显式计算 Hessian
矩阵，也尽量保留牛顿法的二阶曲率信息。本文从牛顿法、拟牛顿条件、正定性和逆
Hessian 更新几个角度，把 BFGS 的公式一步一步推出。

## 从牛顿法开始

考虑无约束优化问题

$$\min\limits_{x}f(x)$$

设当前点为 $x_{k}$，梯度为

$$g_{k} = \nabla f\left( x_{k} \right)$$

在 $x_{k}$ 附近令步长方向为 $p$，对 $f\left( x_{k} + p \right)$ 做二阶
Taylor 展开：

$$f\left( x_{k} + p \right) \approx f\left( x_{k} \right) + g_{k}^{T}p + \frac{1}{2}p^{T}G_{k}p$$

其中

$$G_{k} = \nabla^{2}f\left( x_{k} \right)$$

是 Hessian 矩阵。为了最小化这个二次近似模型，对 $p$ 求梯度。常数项
$f\left( x_{k} \right)$ 对 $p$ 的梯度为 $0$，线性项 $g_{k}^{T}p$
的梯度为 $g_{k}$，二次项 $\frac{1}{2}p^{T}G_{k}p$ 在 $G_{k}$
对称时的梯度为 $G_{k}p$。所以

$$\nabla_{p}\left( f\left( x_{k} \right) + g_{k}^{T}p + \frac{1}{2}p^{T}G_{k}p \right) = g_{k} + G_{k}p$$

令梯度为零：

$$g_{k} + G_{k}p = 0$$

两边同时减去 $g_{k}$：

$$G_{k}p = - g_{k}$$

如果 $G_{k}$ 可逆，两边左乘 $G_{k}^{- 1}$：

$$G_{k}^{- 1}G_{k}p = - G_{k}^{- 1}g_{k}$$

因为 $G_{k}^{- 1}G_{k} = I$，所以

$$p = - G_{k}^{- 1}g_{k}$$

这就是牛顿方向。难点在于 $G_{k}$ 往往很贵，求逆更贵，所以拟牛顿法用
$B_{k}$ 近似 $G_{k}$，或用 $H_{k}$ 近似 $G_{k}^{- 1}$。

## 拟牛顿条件

一次迭代后定义

$$s_{k} = x_{k + 1} - x_{k}$$

和

$$y_{k} = g_{k + 1} - g_{k}$$

如果 Hessian 在 $x_{k}$ 到 $x_{k + 1}$ 之间变化不大，一阶 Taylor
展开给出

$$g_{k + 1} \approx g_{k} + G_{k + 1}\left( x_{k + 1} - x_{k} \right)$$

把 $s_{k} = x_{k + 1} - x_{k}$ 代入：

$$g_{k + 1} \approx g_{k} + G_{k + 1}s_{k}$$

再把 $g_{k + 1} = g_{k} + y_{k}$ 代入：

$$g_{k} + y_{k} \approx g_{k} + G_{k + 1}s_{k}$$

两边同时减去 $g_{k}$：

$$y_{k} \approx G_{k + 1}s_{k}$$

拟牛顿法要求新的 Hessian 近似 $B_{k + 1}$ 精确满足这个关系：

$$B_{k + 1}s_{k} = y_{k}$$

这叫割线条件，也叫拟牛顿条件。

如果改用逆 Hessian 近似 $H_{k + 1} \approx B_{k + 1}^{- 1}$，从

$$B_{k + 1}s_{k} = y_{k}$$

两边左乘 $B_{k + 1}^{- 1}$：

$$B_{k + 1}^{- 1}B_{k + 1}s_{k} = B_{k + 1}^{- 1}y_{k}$$

左边化简为 $s_{k}$，右边记为 $H_{k + 1}y_{k}$，得到

$$H_{k + 1}y_{k} = s_{k}$$

这就是逆形式的拟牛顿条件。

## Hessian 形式的 BFGS 更新

BFGS 对 Hessian 近似的更新为

$$B_{k + 1} = B_{k} - \frac{B_{k}s_{k}s_{k}^{T}B_{k}}{s_{k}^{T}B_{k}s_{k}} + \frac{y_{k}y_{k}^{T}}{y_{k}^{T}s_{k}}$$

下面验证它满足拟牛顿条件。为了减少下标，记

$$s = s_{k},\quad y = y_{k},\quad B = B_{k}$$

并写

$$B^{+} = B - \frac{Bss^{T}B}{s^{T}Bs} + \frac{yy^{T}}{y^{T}s}$$

计算 $B^{+}s$：

$$B^{+}s = \left( B - \frac{Bss^{T}B}{s^{T}Bs} + \frac{yy^{T}}{y^{T}s} \right)s$$

把乘法分配到三项：

$$B^{+}s = Bs - \frac{\left( Bss^{T}B \right)s}{s^{T}Bs} + \frac{\left( yy^{T} \right)s}{y^{T}s}$$

第二项中，矩阵乘法从右向左看：

$$\left( Bss^{T}B \right)s = Bss^{T}Bs$$

其中 $s^{T}Bs$ 是一个标量，因此

$$Bss^{T}Bs = Bs\left( s^{T}Bs \right)$$

所以

$$\frac{\left( Bss^{T}B \right)s}{s^{T}Bs} = \frac{Bs\left( s^{T}Bs \right)}{s^{T}Bs} = Bs$$

第三项同理：

$$\left( yy^{T} \right)s = y\left( y^{T}s \right)$$

于是

$$\frac{\left( yy^{T} \right)s}{y^{T}s} = \frac{y\left( y^{T}s \right)}{y^{T}s} = y$$

代回原式：

$$B^{+}s = Bs - Bs + y$$

前两项抵消：

$$B^{+}s = y$$

因此 BFGS 更新满足 $B_{k + 1}s_{k} = y_{k}$。

## 为什么更新保持对称

假设 $B$ 对称，即 $B^{T} = B$。第一项 $B$ 对称。第二项的分子为
$Bss^{T}B$，它的转置是

$$\left( Bss^{T}B \right)^{T} = B^{T}\left( s^{T} \right)^{T}s^{T}B^{T}$$

因为 $\left( s^{T} \right)^{T} = s$ 且 $B^{T} = B$，所以

$$\left( Bss^{T}B \right)^{T} = Bss^{T}B$$

分母 $s^{T}Bs$ 是标量，转置后不变，因此第二项对称。第三项满足

$$\left( yy^{T} \right)^{T} = yy^{T}$$

所以 $B^{+}$ 仍然对称。

## 正定性的完整证明

设 $B$ 正定，且曲率条件成立：

$$y^{T}s > 0$$

任取非零向量 $z$，计算二次型：

$$z^{T}B^{+}z = z^{T}\left( B - \frac{Bss^{T}B}{s^{T}Bs} + \frac{yy^{T}}{y^{T}s} \right)z$$

分配乘法：

$$z^{T}B^{+}z = z^{T}Bz - z^{T}\frac{Bss^{T}B}{s^{T}Bs}z + z^{T}\frac{yy^{T}}{y^{T}s}z$$

把标量分母提出：

$$z^{T}B^{+}z = z^{T}Bz - \frac{z^{T}Bss^{T}Bz}{s^{T}Bs} + \frac{z^{T}yy^{T}z}{y^{T}s}$$

第二项分子中，$z^{T}Bs$ 是标量，$s^{T}Bz$ 也是标量。因为 $B$ 对称，

$$s^{T}Bz = \left( z^{T}Bs \right)^{T} = z^{T}Bs$$

所以

$$z^{T}Bss^{T}Bz = \left( z^{T}Bs \right)\left( s^{T}Bz \right) = \left( z^{T}Bs \right)^{2}$$

第三项分子为

$$z^{T}yy^{T}z = \left( y^{T}z \right)^{2}$$

于是

$$z^{T}B^{+}z = z^{T}Bz - \frac{\left( z^{T}Bs \right)^{2}}{s^{T}Bs} + \frac{\left( y^{T}z \right)^{2}}{y^{T}s}$$

因为 $B$ 正定，可以定义内积

$$\langle z,s\rangle_{B} = z^{T}Bs$$

Cauchy-Schwarz 不等式给出

$$\left( z^{T}Bs \right)^{2} \leq \left( z^{T}Bz \right)\left( s^{T}Bs \right)$$

由于 $s^{T}Bs > 0$，两边除以它：

$$\frac{\left( z^{T}Bs \right)^{2}}{s^{T}Bs} \leq z^{T}Bz$$

因此

$$z^{T}Bz - \frac{\left( z^{T}Bs \right)^{2}}{s^{T}Bs} \geq 0$$

又因为 $y^{T}s > 0$，

$$\frac{\left( y^{T}z \right)^{2}}{y^{T}s} \geq 0$$

所以

$$z^{T}B^{+}z \geq 0$$

还要证明严格大于零。若
$z^{T}B^{+}z = 0$，上面两个非负项必须同时为零。第一部分为零意味着
Cauchy-Schwarz 取等号，所以 $z$ 与 $s$ 线性相关，存在标量 $\alpha$ 使

$$z = \alpha s$$

第二部分为零意味着

$$y^{T}z = 0$$

代入 $z = \alpha s$：

$$y^{T}(\alpha s) = 0$$

把标量提出：

$$\alpha y^{T}s = 0$$

由于 $y^{T}s > 0$，只能有

$$\alpha = 0$$

于是

$$z = 0$$

这和我们任取非零 $z$ 矛盾。因此对所有非零 $z$，

$$z^{T}B^{+}z > 0$$

所以 $B^{+}$ 正定。

## 逆 Hessian 形式

实际计算方向时，更常用 $H_{k} \approx B_{k}^{- 1}$，因为可以直接写

$$p_{k} = - H_{k}g_{k}$$

BFGS 的逆更新为

$$H_{k + 1} = \left( I - \rho s_{k}y_{k}^{T} \right)H_{k}\left( I - \rho y_{k}s_{k}^{T} \right) + \rho s_{k}s_{k}^{T}$$

其中

$$\rho = \frac{1}{y_{k}^{T}s_{k}}$$

仍省略下标，定义

$$H^{+} = \left( I - \rho sy^{T} \right)H\left( I - \rho ys^{T} \right) + \rho ss^{T}$$

验证它满足逆拟牛顿条件 $H^{+}y = s$。先代入 $y$：

$$H^{+}y = \left( I - \rho sy^{T} \right)H\left( I - \rho ys^{T} \right)y + \rho ss^{T}y$$

先算最右边括号：

$$\left( I - \rho ys^{T} \right)y = y - \rho ys^{T}y$$

因为 $s^{T}y = y^{T}s$，且 $\rho = \frac{1}{y^{T}s}$，所以

$$\rho s^{T}y = 1$$

于是

$$y - \rho ys^{T}y = y - y = 0$$

第一大项变成

$$\left( I - \rho sy^{T} \right)H0 = 0$$

再算第二项：

$$\rho ss^{T}y = \rho s\left( s^{T}y \right)$$

代入 $\rho = \frac{1}{y^{T}s}$：

$$\rho s\left( s^{T}y \right) = \left( \frac{1}{y^{T}s} \right)s\left( y^{T}s \right) = s$$

因此

$$H^{+}y = s$$

逆拟牛顿条件成立。

## 逆形式的展开

从紧凑形式开始：

$$H^{+} = \left( I - \rho sy^{T} \right)H\left( I - \rho ys^{T} \right) + \rho ss^{T}$$

先展开右乘：

$$H\left( I - \rho ys^{T} \right) = H - \rho Hys^{T}$$

再左乘：

$$\left( I - \rho sy^{T} \right)\left( H - \rho Hys^{T} \right)$$

分成两部分：

$$= I\left( H - \rho Hys^{T} \right) - \rho sy^{T}\left( H - \rho Hys^{T} \right)$$

继续展开：

$$= H - \rho Hys^{T} - \rho sy^{T}H + \rho^{2}sy^{T}Hys^{T}$$

加上最后一项：

$$H^{+} = H - \rho Hys^{T} - \rho sy^{T}H + \rho^{2}sy^{T}Hys^{T} + \rho ss^{T}$$

其中 $y^{T}Hy$ 是标量，所以

$$\rho^{2}sy^{T}Hys^{T} = \rho^{2}\left( y^{T}Hy \right)ss^{T}$$

合并两个 $ss^{T}$ 项：

$$H^{+} = H - \rho Hys^{T} - \rho sy^{T}H + \left( \rho + \rho^{2}y^{T}Hy \right)ss^{T}$$

提取 $\rho$：

$$\rho + \rho^{2}y^{T}Hy = \rho(1 + \rho y^{T}Hy)$$

因此展开形式为

$$H^{+} = H - \rho Hys^{T} - \rho sy^{T}H + \rho(1 + \rho y^{T}Hy)ss^{T}$$

## 算法流程

BFGS 的一次迭代如下：

1.  给定 $x_{k}$、$g_{k}$ 和正定矩阵 $H_{k}$。

2.  计算搜索方向：

    $$p_{k} = - H_{k}g_{k}$$

3.  用线搜索选择步长 $\alpha_{k}$，并更新：

    $$x_{k + 1} = x_{k} + \alpha_{k}p_{k}$$

4.  计算

    $$s_{k} = x_{k + 1} - x_{k}$$

    $$y_{k} = g_{k + 1} - g_{k}$$

5.  若 $y_{k}^{T}s_{k} > 0$，令

    $$\rho_{k} = \frac{1}{y_{k}^{T}s_{k}}$$

    并更新

    $$H_{k + 1} = \left( I - \rho_{k}s_{k}y_{k}^{T} \right)H_{k}\left( I - \rho_{k}y_{k}s_{k}^{T} \right) + \rho_{k}s_{k}s_{k}^{T}$$

6.  若 $y_{k}^{T}s_{k} \leq 0$
    或过小，应跳过本次更新、重新线搜索，或重置 $H_{k}$。

## 小结

BFGS
的核心不是凭空构造一个公式，而是在满足拟牛顿条件的前提下，尽量保留已有的二阶近似，并保持对称和正定。Hessian
形式

$$B_{k + 1} = B_{k} - \frac{B_{k}s_{k}s_{k}^{T}B_{k}}{s_{k}^{T}B_{k}s_{k}} + \frac{y_{k}y_{k}^{T}}{y_{k}^{T}s_{k}}$$

说明它如何修正曲率；逆 Hessian 形式

$$H_{k + 1} = \left( I - \rho_{k}s_{k}y_{k}^{T} \right)H_{k}\left( I - \rho_{k}y_{k}s_{k}^{T} \right) + \rho_{k}s_{k}s_{k}^{T}$$

则直接用于计算搜索方向。只要线搜索保证 $y_{k}^{T}s_{k} > 0$，BFGS
就能在不显式计算 Hessian 的情况下稳定地利用二阶信息。
