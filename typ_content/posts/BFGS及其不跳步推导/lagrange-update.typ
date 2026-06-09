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
