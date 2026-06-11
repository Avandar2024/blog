#set math.equation(numbering: "1.")

#let fold(title, body) = [
{% fold(title="#title") %}

#body

{% end %}
]

在 BFGS 中，我们维护一个逆 Hessian 近似 $H_k$，然后用

$ p_k = -H_k g_k $

计算搜索方向。更新公式是

$ H_(k+1) = (I - rho_k s_k y_k^T) H_k (I - rho_k y_k s_k^T) + rho_k s_k s_k^T $

其中

$ s_k = x_(k+1) - x_k, quad y_k = g_(k+1) - g_k, quad rho_k = 1/(y_k^T s_k) $

BFGS 本身是一个近似算法，但是还是局限于用矩阵近似矩阵的思路。但问题在于，只要使用到矩阵，则空间复杂度至少是 $O(n^2)$，每次矩阵乘法也至少是 $O(n^2)$。那么，我们能在不使用矩阵的情况下近似矩阵吗？

答案是可以的，这就是L-BFGS。其核心是：不显式保存 $H_k$，只保存最近 $m$ 组 $(s_i, y_i)$，并且只在需要搜索方向时计算乘积 $H_k g_k$。考虑到更新时实际用到的是$H_k g_k$，这种不直接计算$H_k$的方式颇有核函数的巧妙意味。

== 从递归的角度看

记一次 BFGS 逆矩阵更新为

$ H_(i+1) = V_i^T H_i V_i + rho_i s_i s_i^T $

其中

$ V_i = I - rho_i y_i s_i^T, quad V_i^T = I - rho_i s_i y_i^T $

现在我们不关心完整的 $H_(i+1)$，只关心它乘以某个向量 $q_(i+1)$：

$ H_(i+1) q_(i+1) = V_i^T H_i V_i q_(i+1) + rho_i s_i s_i^T q_(i+1) $ 

记 $V_i q_(i+1)=q_i$，则
$ H_(i+1) q_(i+1) = V_i^T H_i q_i + rho_i s_i s_i^T q_(i+1) $ <recursion>

这个线性方程定义了我们需要的递归。

同时考虑一个细节：递归需要一个初始值，即$H_0$。


== two-loop recursion

下面把递归算法改写成常见的two-loop recursion。

goal :

@recursion

令初始向量

$ q = g_k $

由于 $V_i q_(i+1)=q_i$, 为了避免计算$V_i$的逆矩阵，考虑先进行$i+1 arrow.r i$
方向的更新，于是我们得到了first-loop

$ alpha_i = rho_i s_i^T q $

$ q = q - alpha_i y_i $

可以看到这里产生了副产物 $alpha_i$，由于后面的计算可以用到，先存起来。

到底以后，用一个便宜的初始逆 Hessian 近似：

$ r = H_0^k q $

然后第二层循环在$i arrow.r i+1$的方向上推回来即可，出于复用$alpha_i$的考虑在形式上做了变换：

$ beta_i = rho_i y_i^T r $

$ r = r + s_i (alpha_i - beta_i) $


== python代码实现


它的内存开销是 $O(m n)$，因为只存 $m$ 组长度为 $n$ 的向量。一次方向计算需要两遍遍历曲率对，每组曲率对做常数次点积和 axpy 操作，所以时间复杂度是 $O(m n)$。

#fold("code: 一个最小 Python 版本")[

```python
import numpy as np


def lbfgs_direction(g, pairs):
    """Return the L-BFGS search direction.

    pairs stores (s, y, rho) from old to new.
    """
    q = g.copy()
    alpha = [0.0] * len(pairs)

    for i in range(len(pairs) - 1, -1, -1):
        s, y, rho = pairs[i]
        alpha[i] = rho * np.dot(s, q)
        q -= alpha[i] * y

    if pairs:
        s, y, _ = pairs[-1]
        gamma = np.dot(s, y) / np.dot(y, y)
        r = gamma * q
    else:
        r = q

    for i, (s, y, rho) in enumerate(pairs):
        beta = rho * np.dot(y, r)
        r += s * (alpha[i] - beta)

    return -r
```

]

== $H_0^k$的选取

一个显而易见的事实是：$H_0^k$ 需要尽可能贴近真实的 Hessian矩阵，但是又不能引入过多的计算复杂度。

因此，让我们考虑一个最简单的矩阵形式$H_0^k = gamma I$。在这种形式中通过调节 $gamma$ 的值来让它尽可能贴近 Hessian 矩阵。

我们用如下的式子来定义“贴近”这一概念：
$ H_0^k y_(k-1) - s_(k-1) $

则仍然得到优化问题：

$ min_gamma || gamma y_(k-1) - s_(k-1) ||^2 $

由最小二乘法可得：
$ gamma = (s_(k-1)^T y_(k-1)) / (y_(k-1)^T y_(k-1)) $

说实话，看这个解的形式，和伪逆还是挺像的。

== 更新曲率对

一次优化迭代仍然和 BFGS 一样：

+ 用 two-loop recursion 计算方向 $p_k$。
+ 线搜索得到步长 $alpha_k$。
+ 更新参数：

  $ x_(k+1) = x_k + alpha_k p_k $

+ 计算新梯度 $g_(k+1)$。
+ 构造曲率对：

  $ s_k = x_(k+1) - x_k $

  $ y_k = g_(k+1) - g_k $

+ 如果 $y_k^T s_k$ 足够大，则保存

  $ rho_k = 1/(y_k^T s_k) $

  并把 $(s_k, y_k, rho_k)$ 放进队列尾部。
+ 如果队列长度超过 $m$，丢掉最旧的一组。

这里的判断很重要。理论上需要

$ y_k^T s_k > 0 $

才能保持正定性。实际代码中为了数值稳定性通常还会要求它不要太接近零，例如

```text
ys = dot(y, s)
if ys > eps * norm(s) * norm(y):
    push_pair(s, y, 1 / ys)
```

如果条件不满足，常见做法是跳过这次曲率更新。
