#set math.equation(numbering: "1.")

#let fold(title, body) = [
{% fold(title="#title") %}

#body

{% end %}
]

BFGS 是拟牛顿方法中最常用的一种。它的想法是：不用显式计算 Hessian 矩阵，也尽量保留牛顿法的二阶曲率信息。本文从牛顿法、拟牛顿条件、逆 Hessian 更新和正定性几个角度，把 BFGS 的公式一步一步推出。

== 从牛顿法开始

考虑无约束优化问题

$ min_x f(x) $

设当前点为 $x_k$，梯度为

$ g_k = nabla f(x_k) $

在 $x_k$ 附近令步长方向为 $p$，对 $f(x_k + p)$ 做二阶 Taylor 展开：

$ f(x_k + p) approx f(x_k) + g_k^T p + 1/2 p^T G_k p $

其中

$ G_k = nabla^2 f(x_k) $

是 Hessian 矩阵。为了最小化这个二次近似模型，对 $p$ 求梯度。常数项 $f(x_k)$ 对 $p$ 的梯度为 $0$，线性项 $g_k^T p$ 的梯度为 $g_k$，二次项 $1/2 p^T G_k p$ 在 $G_k$ 对称时的梯度为 $G_k p$。所以

$ nabla_p (f(x_k) + g_k^T p + 1/2 p^T G_k p) = g_k + G_k p $

令梯度为零：

$ g_k + G_k p = 0 $

两边同时减去 $g_k$：

$ G_k p = -g_k $

如果 $G_k$ 可逆，两边左乘 $G_k^(-1)$：


$ p = -G_k^(-1) g_k $

这就是牛顿方向。难点在于 $G_k$ 往往很贵，求逆更贵，所以拟牛顿法用 $B_k$ 近似 $G_k$，或用 $H_k$ 近似 $G_k^(-1)$。

== 拟牛顿条件

一次迭代后定义

$ s_k = x_(k+1) - x_k $

和

$ y_k = g_(k+1) - g_k $

如果 Hessian 在 $x_k$ 到 $x_(k+1)$ 之间变化不大，一阶 Taylor 展开给出

$ g_(k+1) approx g_k + G_(k+1)(x_(k+1) - x_k) $

把 $s_k = x_(k+1)-x_k$ 代入：

$ g_(k+1) approx g_k + G_(k+1) s_k $

再把 $g_(k+1) = g_k + y_k$ 代入：

$ g_k + y_k approx g_k + G_(k+1) s_k $

两边同时减去 $g_k$：

$ y_k approx G_(k+1) s_k $

拟牛顿法要求新的 Hessian 近似 $B_(k+1)$ 精确满足这个关系：

$ B_(k+1) s_k = y_k $


如果改用逆 Hessian 近似 $H_(k+1) approx B_(k+1)^(-1)$，从

$ B_(k+1) s_k = y_k $

两边左乘 $B_(k+1)^(-1)$：

$ B_(k+1)^(-1) B_(k+1) s_k = B_(k+1)^(-1) y_k $

左边化简为 $s_k$，右边记为 $H_(k+1)y_k$，得到

$ H_(k+1) y_k = s_k $ <condition>


== 假设和优化问题定义

显然，仅 @condition 是无法唯一确定 $H_(k+1)$ 的。我们需要添加其他的假设来解出唯一的 $H_(k+1)$。

为了减少下标，记

$ s = s_k, quad y = y_k, quad H = H_k, quad H^+ = H_(k+1) $

则有如下的假设：

- 对称假设：

$ H^+ = (H^+)^T $

- $H$和$H^+$之间满足最小改变原则，因此用一个加权 Frobenius 范数衡量 $H^+ - H$ 的大小。权重矩阵 $W$ 要求对称正定：

$ W = W^T, quad W > 0 $

并且让 $W$ 在割线方向上把 $s$ 映到 $y$：

$ W s = y $

只要 $y^T s > 0$，这样的对称正定 $W$ 可以构造出来。

这样我们就可以得到如下的优化问题：

$ min_(H^+) quad 1/2 norm(W^(1/2)(H^+ - H)W^(1/2))_F^2 quad \
"s.t." quad H^+ = (H^+)^T, quad H^+ y = s $

其中 $W$ 满足

$ W = W^T, quad W > 0, quad W s = y $

== 逆形式的 BFGS 更新

逆形式的拟牛顿条件是

$ H^+ y = s $

假设旧矩阵 $H$ 对称正定。接下来直接求解上一节给出的约束优化问题。

令

$ A = W^(1/2) H^+ W^(1/2), quad M = W^(1/2) H W^(1/2), quad u = W^(-1/2)y $

由 $W s = y$ 可得

$ u = W^(-1/2)y = W^(1/2)s $

因为

$ H^+ = W^(-1/2) A W^(-1/2) $

所以目标函数变为

$ 1/2 norm(A - M)_F^2 $

约束 $H^+ y = s$ 变为

$ W^(-1/2) A W^(-1/2)y = s $

两边左乘 $W^(1/2)$：

$ A W^(-1/2)y = W^(1/2)s $

用 $u = W^(-1/2)y = W^(1/2)s$ 化简：

$ A u = u $

于是原问题等价地化为

$ min_A quad 1/2 norm(A - M)_F^2 quad \
"s.t." quad A = A^T, quad A u = u $



#include "lagrange-update.typ"

== 验证对称性保持

记

$ V = I - rho y s^T $

则

$ V^T = I - rho s y^T $

逆形式更新可以写成

$ H^+ = V^T H V + rho s s^T $

如果 $H$ 对称，则

$ (V^T H V)^T = V^T H^T V = V^T H V $

而

$ (s s^T)^T = s s^T $

所以 $H^+$ 仍然对称。

== 验证正定性保持

在 @condition 中，左乘 $y^T$, 则显然 
$ y^T s > 0 $是 $H^+$ 正定的充要条件。


== 算法流程

BFGS 的一次迭代如下：

+ 给定 $x_k$、$g_k$ 和正定矩阵 $H_k$。
+ 计算搜索方向：

  $ p_k = -H_k g_k $

+ 用线搜索选择步长 $alpha_k$，并更新：

  $ x_(k+1) = x_k + alpha_k p_k $

+ 计算

  $ s_k = x_(k+1) - x_k $

  $ y_k = g_(k+1) - g_k $

+ 若 $y_k^T s_k > 0$，令

  $ rho_k = 1/(y_k^T s_k) $

  并更新

  $ H_(k+1) = (I - rho_k s_k y_k^T) H_k (I - rho_k y_k s_k^T) + rho_k s_k s_k^T $

+ 若 $y_k^T s_k <= 0$ 或过小，应跳过本次更新、重新线搜索，或重置 $H_k$。

== 小结

BFGS 的核心不是凭空构造一个公式，而是在满足逆拟牛顿条件的前提下，尽量保留已有的二阶近似，并保持对称和正定。逆 Hessian 更新

$ H_(k+1) = (I - rho_k s_k y_k^T) H_k (I - rho_k y_k s_k^T) + rho_k s_k s_k^T $

可以直接用于计算搜索方向。只要线搜索保证 $y_k^T s_k > 0$，BFGS 就能在不显式计算 Hessian 的情况下稳定地利用二阶信息。
