= BFGS 及其不跳步推导

BFGS 是拟牛顿方法中最常用的一种。它的想法是：不用显式计算 Hessian 矩阵，也尽量保留牛顿法的二阶曲率信息。本文从牛顿法、拟牛顿条件、正定性和逆 Hessian 更新几个角度，把 BFGS 的公式一步一步推出。

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

$ H_(k+1) y_k = s_k $

这就是逆形式的拟牛顿条件。

== Hessian 形式的 BFGS 更新

BFGS 对 Hessian 近似的更新为

$ B_(k+1) = B_k - (B_k s_k s_k^T B_k)/(s_k^T B_k s_k) + (y_k y_k^T)/(y_k^T s_k) $

下面验证它满足拟牛顿条件。为了减少下标，记

$ s = s_k, quad y = y_k, quad B = B_k $

并写

$ B^+ = B - (B s s^T B)/(s^T B s) + (y y^T)/(y^T s) $

计算 $B^+s$：

$ B^+ s = (B - (B s s^T B)/(s^T B s) + (y y^T)/(y^T s))s $

把乘法分配到三项：

$ B^+ s = B s - ((B s s^T B)s)/(s^T B s) + ((y y^T)s)/(y^T s) $

第二项中，矩阵乘法从右向左看：

$ (B s s^T B)s = B s s^T B s $

其中 $s^T B s$ 是一个标量，因此

$ B s s^T B s = B s (s^T B s) $

所以

$ ((B s s^T B)s)/(s^T B s) = (B s (s^T B s))/(s^T B s) = B s $

第三项同理：

$ (y y^T)s = y(y^T s) $

于是

$ ((y y^T)s)/(y^T s) = (y(y^T s))/(y^T s) = y $

代回原式：

$ B^+s = B s - B s + y $

前两项抵消：

$ B^+s = y $

因此 BFGS 更新满足 $B_(k+1)s_k = y_k$。

== 为什么更新保持对称

假设 $B$ 对称，即 $B^T = B$。第一项 $B$ 对称。第二项的分子为 $B s s^T B$，它的转置是

$ (B s s^T B)^T = B^T (s^T)^T s^T B^T $

因为 $(s^T)^T = s$ 且 $B^T = B$，所以

$ (B s s^T B)^T = B s s^T B $

分母 $s^T B s$ 是标量，转置后不变，因此第二项对称。第三项满足

$ (y y^T)^T = y y^T $

所以 $B^+$ 仍然对称。

== 正定性的完整证明

设 $B$ 正定，且曲率条件成立：

$ y^T s > 0 $

任取非零向量 $z$，计算二次型：

$ z^T B^+ z = z^T (B - (B s s^T B)/(s^T B s) + (y y^T)/(y^T s)) z $

分配乘法：

$ z^T B^+ z = z^T B z - z^T (B s s^T B)/(s^T B s) z + z^T (y y^T)/(y^T s) z $

把标量分母提出：

$ z^T B^+ z = z^T B z - (z^T B s s^T B z)/(s^T B s) + (z^T y y^T z)/(y^T s) $

第二项分子中，$z^T B s$ 是标量，$s^T B z$ 也是标量。因为 $B$ 对称，

$ s^T B z = (z^T B s)^T = z^T B s $

所以

$ z^T B s s^T B z = (z^T B s)(s^T B z) = (z^T B s)^2 $

第三项分子为

$ z^T y y^T z = (y^T z)^2 $

于是

$ z^T B^+ z = z^T B z - ((z^T B s)^2)/(s^T B s) + ((y^T z)^2)/(y^T s) $

因为 $B$ 正定，可以定义内积

$ angle.l z, s angle.r_B = z^T B s $

Cauchy-Schwarz 不等式给出

$ (z^T B s)^2 <= (z^T B z)(s^T B s) $

由于 $s^T B s > 0$，两边除以它：

$ ((z^T B s)^2)/(s^T B s) <= z^T B z $

因此

$ z^T B z - ((z^T B s)^2)/(s^T B s) >= 0 $

又因为 $y^T s > 0$，

$ ((y^T z)^2)/(y^T s) >= 0 $

所以

$ z^T B^+ z >= 0 $

还要证明严格大于零。若 $z^T B^+z = 0$，上面两个非负项必须同时为零。第一部分为零意味着 Cauchy-Schwarz 取等号，所以 $z$ 与 $s$ 线性相关，存在标量 $alpha$ 使

$ z = alpha s $

第二部分为零意味着

$ y^T z = 0 $

代入 $z = alpha s$：

$ y^T (alpha s) = 0 $

把标量提出：

$ alpha y^T s = 0 $

由于 $y^T s > 0$，只能有

$ alpha = 0 $

于是

$ z = 0 $

这和我们任取非零 $z$ 矛盾。因此对所有非零 $z$，

$ z^T B^+ z > 0 $

所以 $B^+$ 正定。

== 逆 Hessian 形式

实际计算方向时，更常用 $H_k approx B_k^(-1)$，因为可以直接写

$ p_k = -H_k g_k $

BFGS 的逆更新为

$ H_(k+1) = (I - rho s_k y_k^T) H_k (I - rho y_k s_k^T) + rho s_k s_k^T $

其中

$ rho = 1/(y_k^T s_k) $

仍省略下标，定义

$ H^+ = (I - rho s y^T) H (I - rho y s^T) + rho s s^T $

验证它满足逆拟牛顿条件 $H^+y=s$。先代入 $y$：

$ H^+ y = (I - rho s y^T) H (I - rho y s^T)y + rho s s^T y $

先算最右边括号：

$ (I - rho y s^T)y = y - rho y s^T y $

因为 $s^T y = y^T s$，且 $rho = 1/(y^T s)$，所以

$ rho s^T y = 1 $

于是

$ y - rho y s^T y = y - y = 0 $

第一大项变成

$ (I - rho s y^T)H 0 = 0 $

再算第二项：

$ rho s s^T y = rho s (s^T y) $

代入 $rho = 1/(y^T s)$：

$ rho s (s^T y) = (1/(y^T s)) s (y^T s) = s $

因此

$ H^+ y = s $

逆拟牛顿条件成立。

== 逆形式的展开

从紧凑形式开始：

$ H^+ = (I - rho s y^T) H (I - rho y s^T) + rho s s^T $

先展开右乘：

$ H(I - rho y s^T) = H - rho H y s^T $

再左乘：

$ (I - rho s y^T)(H - rho H y s^T) $

分成两部分：

$ = I(H - rho H y s^T) - rho s y^T (H - rho H y s^T) $

继续展开：

$ = H - rho H y s^T - rho s y^T H + rho^2 s y^T H y s^T $

加上最后一项：

$ H^+ = H - rho H y s^T - rho s y^T H + rho^2 s y^T H y s^T + rho s s^T $

其中 $y^T H y$ 是标量，所以

$ rho^2 s y^T H y s^T = rho^2 (y^T H y) s s^T $

合并两个 $s s^T$ 项：

$ H^+ = H - rho H y s^T - rho s y^T H + (rho + rho^2 y^T H y) s s^T $

提取 $rho$：

$ rho + rho^2 y^T H y = rho(1 + rho y^T H y) $

因此展开形式为

$ H^+ = H - rho H y s^T - rho s y^T H + rho(1 + rho y^T H y) s s^T $

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

BFGS 的核心不是凭空构造一个公式，而是在满足拟牛顿条件的前提下，尽量保留已有的二阶近似，并保持对称和正定。Hessian 形式

$ B_(k+1) = B_k - (B_k s_k s_k^T B_k)/(s_k^T B_k s_k) + (y_k y_k^T)/(y_k^T s_k) $

说明它如何修正曲率；逆 Hessian 形式

$ H_(k+1) = (I - rho_k s_k y_k^T) H_k (I - rho_k y_k s_k^T) + rho_k s_k s_k^T $

则直接用于计算搜索方向。只要线搜索保证 $y_k^T s_k > 0$，BFGS 就能在不显式计算 Hessian 的情况下稳定地利用二阶信息。
