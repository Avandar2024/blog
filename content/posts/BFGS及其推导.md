+++
title = "BFGS及其推导"
date = 2026-06-09
updated = 2026-06-10
generated_from = "./typ_content/posts/BFGS及其推导/main.typ"
+++

BFGS 是拟牛顿方法中最常用的一种。它的想法是：不用显式计算 Hessian
矩阵，也尽量保留牛顿法的二阶曲率信息。本文从牛顿法、拟牛顿条件、逆
Hessian 更新和正定性几个角度，把 BFGS 的公式一步一步推出。

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

如果改用逆 Hessian 近似 $H_{k + 1} \approx B_{k + 1}^{- 1}$，从

$$B_{k + 1}s_{k} = y_{k}$$

两边左乘 $B_{k + 1}^{- 1}$：

$$B_{k + 1}^{- 1}B_{k + 1}s_{k} = B_{k + 1}^{- 1}y_{k}$$

左边化简为 $s_{k}$，右边记为 $H_{k + 1}y_{k}$，得到

<span id="condition"></span>$$H_{k + 1}y_{k} = s_{k} \tag{condition}$$

## 假设和优化问题定义

显然，仅 [(condition)](#condition) 是无法唯一确定 $H_{k + 1}$
的。我们需要添加其他的假设来解出唯一的 $H_{k + 1}$。

为了减少下标，记

$$s = s_{k},\quad y = y_{k},\quad H = H_{k},\quad H^{+} = H_{k + 1}$$

则有如下的假设：

- 对称假设：

$$H^{+} = \left( H^{+} \right)^{T}$$

- $H$和$H^{+}$之间满足最小改变原则，因此用一个加权 Frobenius 范数衡量
  $H^{+} - H$ 的大小。权重矩阵 $W$ 要求对称正定：

$$W = W^{T},\quad W > 0$$

并且让 $W$ 在割线方向上把 $s$ 映到 $y$：

$$Ws = y$$

只要 $y^{T}s > 0$，这样的对称正定 $W$ 可以构造出来。

这样我们就可以得到如下的优化问题：

$$\begin{array}{r}
\min\limits_{H^{+}}\quad\frac{1}{2}\left\Vert {W^{\frac{1}{2}}\left( H^{+} - H \right)W^{\frac{1}{2}}} \right\Vert_{F}^{2}\quad \\\\[0.65em]
\text{s.t. }\quad H^{+} = \left( H^{+} \right)^{T},\quad H^{+}y = s
\end{array}$$

其中 $W$ 满足

$$W = W^{T},\quad W > 0,\quad Ws = y$$

## 逆形式的 BFGS 更新

逆形式的拟牛顿条件是

$$H^{+}y = s$$

假设旧矩阵 $H$ 对称正定。接下来直接求解上一节给出的约束优化问题。

令

$$A = W^{\frac{1}{2}}H^{+}W^{\frac{1}{2}},\quad M = W^{\frac{1}{2}}HW^{\frac{1}{2}},\quad u = W^{- \frac{1}{2}}y$$

由 $Ws = y$ 可得

$$u = W^{- \frac{1}{2}}y = W^{\frac{1}{2}}s$$

因为

$$H^{+} = W^{- \frac{1}{2}}AW^{- \frac{1}{2}}$$

所以目标函数变为

$$\frac{1}{2}\left\Vert {A - M} \right\Vert_{F}^{2}$$

约束 $H^{+}y = s$ 变为

$$W^{- \frac{1}{2}}AW^{- \frac{1}{2}}y = s$$

两边左乘 $W^{\frac{1}{2}}$：

$$AW^{- \frac{1}{2}}y = W^{\frac{1}{2}}s$$

用 $u = W^{- \frac{1}{2}}y = W^{\frac{1}{2}}s$ 化简：

$$Au = u$$

于是原问题等价地化为

$$\begin{array}{r}
\min\limits_{A}\quad\frac{1}{2}\left\Vert {A - M} \right\Vert_{F}^{2}\quad \\\\[0.65em]
\text{s.t. }\quad A = A^{T},\quad Au = u
\end{array}$$

写拉格朗日函数。由于 $A$ 要求对称，变化量 $dA$ 也只在对称矩阵中取：

$$L(A,\lambda) = \frac{1}{2}\operatorname{tr}((A - M)^{2}) - 2\lambda^{T(Au - u)}$$

由 Frobenius 范数平方的微分公式，对 $A$ 求一阶变分：

{% fold(title="def: Frobenius 范数") %}

对任意矩阵 $X \in {\mathbb{R}}^{m \times n}$，Frobenius 范数定义为

$$\left\Vert X \right\Vert_{F} = \sqrt{\sum_{i = 1}^{m}\sum_{j = 1}^{n}x_{ij}^{2}}$$

也可以写成迹的形式：

$$\left\Vert X \right\Vert_{F} = \sqrt{\operatorname{tr}(X^{T}X)}$$

{% end %}

{% fold(title="proof: Frobenius 范数平方的微分") %}

考虑

$$\varphi(X) = \frac{1}{2}\left\Vert X \right\Vert_{F}^{2}$$

其微分为

$$d\varphi = \operatorname{tr}(X^{T}dX)$$

证明如下：

由 Frobenius 范数的迹表示，

$$\varphi(X) = \frac{1}{2}\operatorname{tr}(X^{T}X)$$

对两边取微分：

$$d\varphi = \frac{1}{2}d\operatorname{tr}(X^{T}X)$$

从而

$$d\varphi = \frac{1}{2}\operatorname{tr}(dX^{T}X + X^{T}dX)$$

利用迹的转置不变性：

$$\operatorname{tr}(dX^{T}X) = \operatorname{tr}(\left( (X)^{T}dX \right)^{T}) = \operatorname{tr}((X)^{T}dX)$$

所以两项相同，得到

$$d\varphi = \operatorname{tr}((X)^{T}dX)$$

{% end %}

$$dL = \operatorname{tr}((A - M)dA) - 2\lambda^{T}dAu$$

把第二项写成迹：

$$\lambda^{T}dAu = \operatorname{tr}(\lambda^{T}dAu) = \operatorname{tr}(u\lambda^{T}dA)$$

所以

$$dL = \operatorname{tr}(\left( A - M - 2u\lambda^{T} \right)dA)$$

但 $dA$ 是对称的。只有矩阵的对称部分会影响这个内积，因此驻点条件是

$$A - M - \left( u\lambda^{T} + \lambda u^{T} \right) = 0$$

也就是

$$A = M + u\lambda^{T} + \lambda u^{T}$$

把约束 $Au = u$ 代入：

$$\left( M + u\lambda^{T} + \lambda u^{T} \right)u = u$$

展开：

$$Mu + u\left( \lambda^{T}u \right) + \lambda(u^{T}u) = u$$

记

$$\gamma = u^{T}u,\quad\delta = \lambda^{T}u,\quad\eta = u^{T}Mu$$

则

$$Mu + \delta u + \gamma\lambda = u$$

移项得到

$$\gamma\lambda = (1 - \delta)u - Mu$$

两边左乘 $u^{T}$：

$$\gamma u^{T}\lambda = (1 - \delta)u^{T}u - u^{T}Mu$$

代入 $u^{T}\lambda = \delta$、$u^{T}u = \gamma$ 和 $u^{T}Mu = \eta$：

$$\gamma\delta = (1 - \delta)\gamma - \eta$$

展开右边：

$$\gamma\delta = \gamma - \gamma\delta - \eta$$

两边同时加上 $\gamma\delta$：

$$2\gamma\delta = \gamma - \eta$$

由于 $\gamma > 0$，所以

$$\delta = \frac{\gamma - \eta}{2\gamma}$$

代回

$$\gamma\lambda = (1 - \delta)u - Mu$$

先计算 $1 - \delta$：

$$1 - \delta = 1 - \frac{\gamma - \eta}{2\gamma}$$

通分：

$$1 - \delta = \frac{2\gamma - \gamma + \eta}{2\gamma} = \frac{\gamma + \eta}{2\gamma}$$

因此

$$\gamma\lambda = \left( \frac{\gamma + \eta}{2\gamma} \right)u - Mu$$

两边除以 $\gamma$：

$$\lambda = \left( \frac{\gamma + \eta}{2\gamma^{2}} \right)u - \frac{Mu}{\gamma}$$

代回 $A = M + u\lambda^{T} + \lambda u^{T}$。先算 $u\lambda^{T}$：

$$u\lambda^{T} = \left( \frac{\gamma + \eta}{2\gamma^{2}} \right)uu^{T} - \frac{uu^{T}M}{\gamma}$$

再算 $\lambda u^{T}$：

$$\lambda u^{T} = \left( \frac{\gamma + \eta}{2\gamma^{2}} \right)uu^{T} - \frac{Muu^{T}}{\gamma}$$

两式相加：

$$u\lambda^{T} + \lambda u^{T} = \left( \frac{\gamma + \eta}{\gamma^{2}} \right)uu^{T} - \frac{uu^{T}M + Muu^{T}}{\gamma}$$

所以

$$A = M - \frac{Muu^{T} + uu^{T}M}{\gamma} + \left( \frac{\gamma + \eta}{\gamma^{2}} \right)uu^{T}$$

把最后一项写成更常用的形式：

$$\frac{\gamma + \eta}{\gamma^{2}} = \frac{1 + \frac{\eta}{\gamma}}{\gamma}$$

于是

$$A = M - \frac{Muu^{T} + uu^{T}M}{u^{T}u} + \left( 1 + \frac{u^{T}Mu}{u^{T}u} \right)\frac{uu^{T}}{u^{T}u}$$

现在回到 $H^{+}$：

$$H^{+} = W^{- \frac{1}{2}}AW^{- \frac{1}{2}}$$

由 $u = W^{- \frac{1}{2}}y = W^{\frac{1}{2}}s$ 可得

$$W^{- \frac{1}{2}}u = s$$

并且

$$u^{T}u = s^{T}Ws = s^{T}y = y^{T}s$$

还要化简 $Mu$：

$$Mu = W^{\frac{1}{2}}HW^{\frac{1}{2}}W^{- \frac{1}{2}}y = W^{\frac{1}{2}}Hy$$

所以

$$W^{- \frac{1}{2}}Mu = Hy$$

同理，

$$u^{T}MW^{- \frac{1}{2}} = y^{T}H$$

以及

$$u^{T}Mu = y^{T}Hy$$

代回展开式：

$$H^{+} = H - \frac{Hys^{T} + sy^{T}H}{y^{T}s} + \left( 1 + \frac{y^{T}Hy}{y^{T}s} \right)\frac{ss^{T}}{y^{T}s}$$

令

$$\rho = \frac{1}{y^{T}s}$$

则

$$H^{+} = H - \rho Hys^{T} - \rho sy^{T}H + \rho(1 + \rho y^{T}Hy)ss^{T}$$

这个展开式可以整理成更紧凑的乘积形式：

$$H^{+} = \left( I - \rho sy^{T} \right)H\left( I - \rho ys^{T} \right) + \rho ss^{T}$$

恢复下标：

$$H_{k + 1} = \left( I - \rho_{k}s_{k}y_{k}^{T} \right)H_{k\left( I - \rho_{k}y_{k}s_{k}^{T} \right)} + \rho_{k}s_{k}s_{k}^{T}$$

其中

$$\rho_{k} = \frac{1}{y_{k}^{T}s_{k}}$$

这就是直接由逆形式约束优化问题推出的 BFGS 更新。

## 验证对称性保持

记

$$V = I - \rho ys^{T}$$

则

$$V^{T} = I - \rho sy^{T}$$

逆形式更新可以写成

$$H^{+} = V^{T}HV + \rho ss^{T}$$

如果 $H$ 对称，则

$$\left( V^{T}HV \right)^{T} = V^{T}H^{T}V = V^{T}HV$$

而

$$\left( ss^{T} \right)^{T} = ss^{T}$$

所以 $H^{+}$ 仍然对称。

## 验证正定性保持

在 [(condition)](#condition) 中，左乘 $y^{T}$, 则显然
$$y^{T}s > 0$$是 $H^{+}$ 正定的充要条件。

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
的核心不是凭空构造一个公式，而是在满足逆拟牛顿条件的前提下，尽量保留已有的二阶近似，并保持对称和正定。逆
Hessian 更新

$$H_{k + 1} = \left( I - \rho_{k}s_{k}y_{k}^{T} \right)H_{k}\left( I - \rho_{k}y_{k}s_{k}^{T} \right) + \rho_{k}s_{k}s_{k}^{T}$$

可以直接用于计算搜索方向。只要线搜索保证 $y_{k}^{T}s_{k} > 0$，BFGS
就能在不显式计算 Hessian 的情况下稳定地利用二阶信息。
