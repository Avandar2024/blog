#set math.equation(numbering: "1.")

= BFGS 及其不跳步推导

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

$ G_k^(-1) G_k p = -G_k^(-1) g_k $

因为 $G_k^(-1)G_k = I$，所以

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

这叫割线条件，也叫拟牛顿条件。

如果改用逆 Hessian 近似 $H_(k+1) approx B_(k+1)^(-1)$，从

$ B_(k+1) s_k = y_k $

两边左乘 $B_(k+1)^(-1)$：

$ B_(k+1)^(-1) B_(k+1) s_k = B_(k+1)^(-1) y_k $

左边化简为 $s_k$，右边记为 $H_(k+1)y_k$，得到

$ H_(k+1) y_k = s_k $ <condition>

这就是逆形式的拟牛顿条件。

== 假设和优化问题定义

显然，仅 @condition 是无法确定 $H_(k+1)$ 的。我们需要添加其他的假设来解出唯一的 $H_(k+1)$。

为了减少下标，记

$ s = s_k, quad y = y_k, quad H = H_k, quad H^+ = H_(k+1) $

- 对称假设：

$ H^+ = (H^+)^T $

- 为了让更新保持正定，需要曲率条件：

$ y^T s > 0 $

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

写拉格朗日函数。由于 $A$ 要求对称，变化量 $d A$ 也只在对称矩阵中取：

$ L(A, lambda) = 1/2 tr((A - M)^2) - 2 lambda^T(A u - u) $

由 Frobenius 范数平方的微分公式，见附录 A，对 $A$ 求一阶变分：

$ d L = tr((A - M)d A) - 2 lambda^T d A u $

把第二项写成迹：

$ lambda^T d A u = tr(lambda^T d A u) = tr(u lambda^T d A) $

所以

$ d L = tr((A - M - 2 u lambda^T)d A) $

但 $d A$ 是对称的。只有矩阵的对称部分会影响这个内积，因此驻点条件是

$ A - M - (u lambda^T + lambda u^T) = 0 $

也就是

$ A = M + u lambda^T + lambda u^T $

把约束 $A u = u$ 代入：

$ (M + u lambda^T + lambda u^T)u = u $

展开：

$ M u + u(lambda^T u) + lambda(u^T u) = u $

记

$ gamma = u^T u, quad delta = lambda^T u, quad eta = u^T M u $

则

$ M u + delta u + gamma lambda = u $

移项得到

$ gamma lambda = (1 - delta)u - M u $

两边左乘 $u^T$：

$ gamma u^T lambda = (1 - delta)u^T u - u^T M u $

代入 $u^T lambda = delta$、$u^T u = gamma$ 和 $u^T M u = eta$：

$ gamma delta = (1 - delta)gamma - eta $

展开右边：

$ gamma delta = gamma - gamma delta - eta $

两边同时加上 $gamma delta$：

$ 2 gamma delta = gamma - eta $

由于 $gamma > 0$，所以

$ delta = (gamma - eta)/(2 gamma) $

代回

$ gamma lambda = (1 - delta)u - M u $

先计算 $1 - delta$：

$ 1 - delta = 1 - (gamma - eta)/(2 gamma) $

通分：

$ 1 - delta = (2 gamma - gamma + eta)/(2 gamma) = (gamma + eta)/(2 gamma) $

因此

$ gamma lambda = ((gamma + eta)/(2 gamma))u - M u $

两边除以 $gamma$：

$ lambda = ((gamma + eta)/(2 gamma^2))u - (M u)/gamma $

代回 $A = M + u lambda^T + lambda u^T$。先算 $u lambda^T$：

$ u lambda^T = ((gamma + eta)/(2 gamma^2))u u^T - (u u^T M)/gamma $

再算 $lambda u^T$：

$ lambda u^T = ((gamma + eta)/(2 gamma^2))u u^T - (M u u^T)/gamma $

两式相加：

$ u lambda^T + lambda u^T = ((gamma + eta)/(gamma^2))u u^T - (u u^T M + M u u^T)/gamma $

所以

$ A = M - (M u u^T + u u^T M)/gamma + ((gamma + eta)/(gamma^2))u u^T $

把最后一项写成更常用的形式：

$ (gamma + eta)/(gamma^2) = (1 + eta/gamma)/gamma $

于是

$ A = M - (M u u^T + u u^T M)/(u^T u) + (1 + (u^T M u)/(u^T u))(u u^T)/(u^T u) $

现在回到 $H^+$：

$ H^+ = W^(-1/2) A W^(-1/2) $

由 $u = W^(-1/2)y = W^(1/2)s$ 可得

$ W^(-1/2)u = s $

并且

$ u^T u = s^T W s = s^T y = y^T s $

还要化简 $M u$：

$ M u = W^(1/2) H W^(1/2) W^(-1/2)y = W^(1/2)H y $

所以

$ W^(-1/2) M u = H y $

同理，

$ u^T M W^(-1/2) = y^T H $

以及

$ u^T M u = y^T H y $

代回展开式：

$ H^+ = H - (H y s^T + s y^T H)/(y^T s) + (1 + (y^T H y)/(y^T s))(s s^T)/(y^T s) $

令

$ rho = 1/(y^T s) $

则

$ H^+ = H - rho H y s^T - rho s y^T H + rho(1 + rho y^T H y)s s^T $

这个展开式可以整理成更紧凑的乘积形式：

$ H^+ = (I - rho s y^T)H(I - rho y s^T) + rho s s^T $

恢复下标：

$ H_(k+1) = (I - rho_k s_k y_k^T)H_k(I - rho_k y_k s_k^T) + rho_k s_k s_k^T $

其中

$ rho_k = 1/(y_k^T s_k) $

这就是直接由逆形式约束优化问题推出的 BFGS 更新。

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

设 $H$ 正定，且曲率条件成立：

$ y^T s > 0 $

由于

$ rho = 1/(y^T s) $

所以

$ rho > 0 $

任取非零向量 $z$，计算二次型：

$ z^T H^+ z = z^T(V^T H V + rho s s^T)z $

分配乘法：

$ z^T H^+ z = z^T V^T H V z + rho z^T s s^T z $

第一项可写成

$ z^T V^T H V z = (V z)^T H (V z) $

第二项中，$z^T s$ 是标量，且 $s^T z = z^T s$，所以

$ z^T s s^T z = (s^T z)^2 $

于是

$ z^T H^+ z = (V z)^T H(V z) + rho(s^T z)^2 $

因为 $H$ 正定，第一项非负；因为 $rho > 0$，第二项也非负。因此

$ z^T H^+ z >= 0 $

还要证明严格大于零。若 $z^T H^+z = 0$，两个非负项必须同时为零：

$ (V z)^T H(V z) = 0 $

和

$ rho(s^T z)^2 = 0 $

由 $H$ 正定可知第一式推出

$ V z = 0 $

由 $rho > 0$ 可知第二式推出

$ s^T z = 0 $

把 $V = I - rho y s^T$ 代入 $V z = 0$：

$ (I - rho y s^T)z = 0 $

展开：

$ z - rho y(s^T z) = 0 $

由于 $s^T z = 0$，得到

$ z = 0 $

这和任取非零 $z$ 矛盾。因此对所有非零 $z$，

$ z^T H^+ z > 0 $

所以 $H^+$ 正定。

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

== 附录 A：Frobenius 范数平方的微分

对任意矩阵 $X in RR^(m times n)$，Frobenius 范数定义为

$ norm(X)_F = sqrt(sum_(i=1)^m sum_(j=1)^n x_(i j)^2) $

也可以写成迹的形式：

$ norm(X)_F = sqrt(tr(X^T X)) $

因此

$ norm(X)_F^2 = tr(X^T X) $

更一般地，若 $M$ 是与 $X$ 同型的常矩阵，则

$ phi(X) = 1/2 norm(X - M)_F^2 $

的微分为

$ d phi = tr((X - M)^T d X) $

如果 $X$ 和 $M$ 都是对称矩阵，并且只考虑对称方向上的变化 $d X = d X^T$，则

$ d phi = tr((X - M)d X) $

证明如下。由 Frobenius 范数的迹表示，

$ phi(X) = 1/2 tr((X - M)^T (X - M)) $

对两边取微分：

$ d phi = 1/2 d tr((X - M)^T (X - M)) $

因为 $M$ 是常矩阵，所以 $d(X - M) = d X$，从而

$ d phi = 1/2 tr(d X^T (X - M) + (X - M)^T d X) $

利用迹的转置不变性：

$ tr(d X^T (X - M)) = tr(((X - M)^T d X)^T) = tr((X - M)^T d X) $

所以两项相同，得到

$ d phi = tr((X - M)^T d X) $

若 $X$、$M$ 和 $d X$ 都对称，则 $(X - M)^T = X - M$，于是

$ d phi = tr((X - M)d X) $
